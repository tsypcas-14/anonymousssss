"""Tests of accounts, manual control and the API.   Run:  .venv\\Scripts\\python -m unittest -v"""
import os
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "app" / "server"))
import trees  # noqa: E402,F401  (puts edge_ai/edge on sys.path)
from auth import Auth, AuthError  # noqa: E402
from controller import MANUAL_HOLD_S, Controller  # noqa: E402
from farm_sim import STEP_S, SimulatedFarm  # noqa: E402


def run(farm, ctrl, seconds):
    for _ in range(int(seconds / STEP_S)):
        farm.step(STEP_S)
        ctrl.step(farm.read())


class AuthTest(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.TemporaryDirectory()
        self.auth = Auth(Path(self.dir.name) / "t.db", "424242")

    def tearDown(self):
        self.auth.db.close()
        self.dir.cleanup()

    def test_signup_needs_the_greenhouse_code(self):
        with self.assertRaises(AuthError):
            self.auth.signup("Test User", "a@b.tn", "password1", "000000")
        user, token = self.auth.signup("Test User", "A@B.tn", "password1", "424242")
        self.assertEqual(user["email"], "a@b.tn")
        self.assertEqual(self.auth.user_for(token)["name"], "Test User")

    def test_login_logout_and_validation(self):
        self.auth.signup("Test User", "a@b.tn", "password1", "424242")
        with self.assertRaises(AuthError):
            self.auth.login("a@b.tn", "wrong-pass")
        _, token = self.auth.login("a@b.tn", "password1")
        self.auth.logout(token)
        self.assertIsNone(self.auth.user_for(token))
        for bad in [("", "x@y.tn", "password1"), ("A", "not-an-email", "password1"), ("A", "x@y.tn", "short")]:
            with self.assertRaises(AuthError):
                self.auth.signup(*bad, "424242")
        with self.assertRaises(AuthError):
            self.auth.signup("Twin", "a@b.tn", "password1", "424242")

    def test_code_file_and_settings(self):
        self.assertEqual((Path(self.dir.name) / "greenhouse_code.txt").read_text().strip(), "424242")
        self.assertEqual(self.auth.update_settings(name="Serre A", contact_name="Responsable")["name"], "Serre A")
        self.assertEqual(self.auth.settings()["contact_name"], "Responsable")


class ManualControlTest(unittest.TestCase):
    def setUp(self):
        self.farm = SimulatedFarm()
        self.ctrl = Controller(self.farm)
        run(self.farm, self.ctrl, 3600)

    def test_manual_watering_goes_through_every_step_and_is_checked(self):
        c = self.ctrl.request("water", "Test User", seconds=5)
        self.assertEqual(c["status"], "sent")
        run(self.farm, self.ctrl, STEP_S)
        self.assertEqual(c["status"], "running")
        self.assertTrue(self.farm.pump)
        run(self.farm, self.ctrl, 90)
        self.assertEqual(c["status"], "success", c)
        self.assertGreater(c["result"]["soil_after_pct"], c["result"]["soil_before_pct"])
        self.assertEqual(set(c["steps"]), {"sent", "received", "running", "checking", "done"})
        self.assertEqual(self.ctrl.modes["irrigation"]["mode"], "manual")

    def test_stuck_pump_gives_an_error_with_advice(self):
        self.farm.fault = "blocked"
        c = self.ctrl.request("water", "Test User", seconds=5)
        run(self.farm, self.ctrl, 90)
        self.assertEqual(c["status"], "error")
        self.assertIn("pipe", c["message"])

    def test_safety_refuses_commands(self):
        self.farm.dist = 11.0
        c = self.ctrl.request("water", "Test User", seconds=5)
        run(self.farm, self.ctrl, STEP_S)
        self.assertEqual(c["status"], "refused")
        self.farm.refill()
        self.farm.flame = True
        c = self.ctrl.request("water", "Test User", seconds=5)
        run(self.farm, self.ctrl, STEP_S)
        self.assertEqual(c["status"], "refused")
        self.assertFalse(self.farm.pump)

    def test_manual_mode_stops_auto_watering_then_expires(self):
        self.ctrl.set_mode("irrigation", "manual", "Test User")
        self.farm.dry_out()
        pulses = self.ctrl.snapshot()["irrigation"]["pulses_total"]
        run(self.farm, self.ctrl, 600)
        self.assertEqual(self.ctrl.snapshot()["irrigation"]["pulses_total"], pulses, "manual mode: no automatic watering")
        run(self.farm, self.ctrl, MANUAL_HOLD_S)
        self.assertEqual(self.ctrl.modes["irrigation"]["mode"], "auto")
        self.assertGreater(self.ctrl.snapshot()["irrigation"]["pulses_total"], pulses, "back to auto: it waters again")

    def test_manual_fan_holds_and_flame_still_cuts_it(self):
        c = self.ctrl.request("fan", "Test User", on=True)
        run(self.farm, self.ctrl, 3 * STEP_S)
        self.assertEqual(c["status"], "success")
        self.assertTrue(self.farm.fan)
        run(self.farm, self.ctrl, 600)
        self.assertTrue(self.farm.fan, "manual ON holds even if tree 2 says off")
        self.farm.flame = True
        run(self.farm, self.ctrl, STEP_S)
        self.assertFalse(self.farm.fan)

    def test_snapshot_has_what_the_app_needs(self):
        run(self.farm, self.ctrl, 2 * 86400)
        s = self.ctrl.snapshot()
        for k in ("alerts", "modes", "tank_days", "fan_runs_today", "last_valid", "thresholds"):
            self.assertIn(k, s)
        self.assertIsNotNone(s["tank_days"])
        self.assertTrue(any(e["why"] for e in self.ctrl.events), "log entries explain themselves")


class ApiTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        from fastapi.testclient import TestClient
        cls.tmp = tempfile.TemporaryDirectory()
        os.environ["SMARTFARM_CODE"] = "777777"
        import main
        main.DB_FILE = Path(cls.tmp.name) / "api.db"
        cls.client_cm = TestClient(main.app)
        cls.c = cls.client_cm.__enter__()

    @classmethod
    def tearDownClass(cls):
        cls.client_cm.__exit__(None, None, None)
        import main
        main.auth.db.close()                     # Windows cannot delete an open database file
        cls.tmp.cleanup()
        os.environ.pop("SMARTFARM_CODE", None)

    def test_flow(self):
        c = self.c
        self.assertEqual(c.get("/api/info").json()["app"], "smartfarm")
        self.assertEqual(c.get("/api/state").status_code, 401)
        self.assertEqual(c.post("/api/auth/signup", json={"name": "A", "email": "a@b.tn", "password": "password1",
                                                          "code": "000000"}).status_code, 400)
        r = c.post("/api/auth/signup", json={"name": "Test User", "email": "a@b.tn", "password": "password1", "code": "777777"})
        self.assertEqual(r.status_code, 200, r.text)
        h = {"Authorization": "Bearer " + r.json()["token"]}
        self.assertEqual(c.get("/api/state", headers=h).status_code, 200)
        self.assertEqual(c.get("/api/me", headers=h).json()["user"]["name"], "Test User")
        self.assertEqual(c.post("/api/water", json={"seconds": 99}, headers=h).status_code, 400)
        self.assertEqual(c.post("/api/water", json={"seconds": 5}, headers=h).json()["status"], "sent")
        self.assertEqual(c.post("/api/mode", json={"equipment": "fan", "mode": "manual"}, headers=h).json()["fan"]["mode"], "manual")
        self.assertEqual(c.patch("/api/settings", json={"contact_name": "Responsable"}, headers=h).json()["contact_name"], "Responsable")
        with c.websocket_connect("/ws?token=" + h["Authorization"][7:]) as ws:
            self.assertIn("sensors", ws.receive_json())
        c.post("/api/auth/logout", headers=h)
        self.assertEqual(c.get("/api/state", headers=h).status_code, 401)


if __name__ == "__main__":
    unittest.main()
