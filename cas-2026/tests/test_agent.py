"""Tests of the autonomous agent (no hardware, no network).   Run:  .venv\\Scripts\\python -m unittest -v"""
import json
import random
import sys
import time
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "app" / "server"))
import trees  # noqa: E402  (puts edge_ai/edge on sys.path)
import config  # noqa: E402
import edge_models  # noqa: E402
import stats  # noqa: E402
from controller import LOCKOUT_AFTER, Controller  # noqa: E402
from farm_sim import STEP_S, SimulatedFarm  # noqa: E402


def run(farm, ctrl, hours):
    for _ in range(int(hours * 3600 / STEP_S)):
        farm.step(STEP_S)
        ctrl.step(farm.read())


class TreesTest(unittest.TestCase):
    def test_explain_matches_the_code_running_on_the_pi(self):
        rng = random.Random(1)
        for _ in range(5000):
            x = dict(soil_raw=rng.uniform(250, 950), air_temp=rng.uniform(5, 45), air_hum=rng.uniform(20, 100),
                     light=rng.uniform(0, 70000), water_dist=rng.uniform(1, 14))
            self.assertEqual(trees.explain("irrigation", x)["label"], edge_models.predict_irrigation(**x))
            c = {k: x[k] for k in ("air_temp", "air_hum", "light")}
            self.assertEqual(trees.explain("climate", c)["label"], edge_models.predict_climate(**c))
            a = dict(soil_before=rng.uniform(550, 900), soil_drop=rng.uniform(-300, 300),
                     water_drop_cm=rng.uniform(-0.2, 2.5), soil_std=rng.uniform(0, 120))
            self.assertEqual(trees.explain("anomaly", a)["label"], edge_models.predict_anomaly(**a))

    def test_model_card_has_metrics_and_policy(self):
        card = trees.model_card()
        self.assertEqual(set(card["trees"]), {"irrigation", "climate", "anomaly"})
        self.assertIn("test_accuracy", card["trees"]["irrigation"]["metrics"])
        self.assertEqual(card["policy"]["irrigation"]["thr_base"], 600)


class ConfigTest(unittest.TestCase):
    def test_ultrasonic_mapping_keeps_the_tank_scale(self):
        self.assertAlmostEqual(config.to_model_dist(config.SENSOR_DIST_FULL_CM), config.WATER_FULL_CM)
        self.assertAlmostEqual(config.to_model_dist(config.SENSOR_DIST_EMPTY_CM), config.WATER_EMPTY_CM)
        self.assertEqual(config.tank_pct(config.WATER_FULL_CM), 100)
        self.assertEqual(config.tank_pct(config.WATER_EMPTY_CM), 0)

    def test_hardware_driver_imports_without_a_pi(self):
        import hardware                                   # RPi.GPIO etc. are only imported in Hardware()
        self.assertEqual(hardware.PUMP_MAX_S, 10.0)


class AgentTest(unittest.TestCase):
    def setUp(self):
        self.farm = SimulatedFarm()
        self.ctrl = Controller(self.farm)

    def test_three_days_waters_ventilates_and_diagnoses_normal(self):
        t0 = time.perf_counter()
        run(self.farm, self.ctrl, 72)
        speed = 72 * 3600 / STEP_S / (time.perf_counter() - t0)
        s = self.ctrl.snapshot()
        diags = [d["label"] for d in self.ctrl.diagnoses]
        self.assertGreaterEqual(len(diags), 3, "the plants should have been watered")
        self.assertTrue(all(d == "NORMAL" for d in diags), diags)
        self.assertGreater(sum(p["fan"] for p in self.ctrl.history), 0, "the fan should run on hot days")
        self.assertFalse(s["irrigation"]["locked"])
        self.assertAlmostEqual(len(self.ctrl.history), 72 * 12, delta=1)
        self.assertGreater(speed, 3000, f"simulation too slow: {speed:.0f} ticks/s")

    def test_leak_is_diagnosed_and_locks_the_pump(self):
        run(self.farm, self.ctrl, 2)
        self.farm.fault = "leak"
        for _ in range(LOCKOUT_AFTER):
            self.farm.dry_out()
            run(self.farm, self.ctrl, 0.1)
        self.assertEqual([d["label"] for d in list(self.ctrl.diagnoses)[:LOCKOUT_AFTER]], ["FUITE"] * LOCKOUT_AFTER)
        self.assertTrue(self.ctrl.locked)
        n = sum(d["pulses"] for d in self.ctrl.daily.values())
        self.farm.dry_out()
        run(self.farm, self.ctrl, 0.1)
        self.assertEqual(sum(d["pulses"] for d in self.ctrl.daily.values()), n, "a locked pump must not run")
        self.ctrl.unlock_pump()
        self.assertFalse(self.ctrl.locked)

    def test_stuck_pump_and_faulty_sensor(self):
        self.farm.fault = "blocked"
        self.farm.dry_out()
        run(self.farm, self.ctrl, 0.1)
        self.assertEqual(self.ctrl.last_diag["label"], "POMPE_BLOQUEE")
        self.assertTrue(self.ctrl.locked, "two stuck pulses in a row lock the pump")
        self.ctrl.unlock_pump()
        self.farm.fault = "sensor"
        self.farm.dry_out()
        run(self.farm, self.ctrl, 0.1)
        self.assertEqual(self.ctrl.last_diag["label"], "CAPTEUR_DEFAILLANT")

    def test_flame_cuts_pump_and_fan_and_sounds_the_buzzer(self):
        run(self.farm, self.ctrl, 1)
        self.farm.dry_out()
        self.farm.flame = True
        run(self.farm, self.ctrl, 0.05)
        self.assertTrue(self.farm.buzzer)
        self.assertFalse(self.farm.pump or self.farm.fan)
        self.assertTrue(self.ctrl.snapshot()["alarms"]["fire"])
        self.farm.flame = False
        run(self.farm, self.ctrl, 0.05)
        self.assertFalse(self.farm.buzzer)

    def test_missing_reading_stops_the_pump(self):
        self.farm.dry_out()
        self.farm.step(STEP_S)
        self.ctrl.step(self.farm.read())
        self.assertTrue(self.farm.pump, "dry soil should start a pulse")
        r = self.farm.read()
        r["air_temp"] = None
        self.ctrl.step(r)
        self.assertFalse(self.farm.pump)
        self.assertTrue(self.ctrl.snapshot()["alarms"]["missing"])

    def test_empty_tank_forbids_the_pump(self):
        self.farm.dist = 11.0
        self.farm.dry_out()
        run(self.farm, self.ctrl, 0.1)
        self.assertEqual(sum(d["pulses"] for d in self.ctrl.daily.values()), 0)
        self.assertTrue(self.ctrl.tank_low)

    def test_state_survives_a_restart(self):
        run(self.farm, self.ctrl, 3)
        self.ctrl.locked = True
        saved = json.loads(json.dumps(self.ctrl.dump()))
        other = Controller(SimulatedFarm())
        other.restore(saved)
        self.assertTrue(other.locked)
        self.assertEqual(len(other.history), len(self.ctrl.history))

    def test_statistics(self):
        run(self.farm, self.ctrl, 48)
        st = stats.compute(self.ctrl, 24)
        self.assertEqual(st["points"], 288)
        self.assertEqual(sum(st["hist"]["soil"]["counts"]), 288)
        self.assertEqual(st["kpi"]["pulses"], sum(st["by_hour"]["pulses"]))
        self.assertGreater(st["kpi"]["water_l"], 0)
        self.assertLessEqual(st["kpi"]["fan_pct"], 100)
        json.dumps(st)


if __name__ == "__main__":
    unittest.main()
