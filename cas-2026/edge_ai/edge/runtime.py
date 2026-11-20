"""
SmartFarm AI - Runtime Edge AI (Raspberry Pi 3B). 100% local, aucun appel reseau.

  Capteurs -> [regles de securite] -> Decision Trees (edge_models.py) -> relais pompe / ventilateur
                                                                      -> journal CSV (re-entrainement)

Usage :
  python3 runtime.py              # materiel reel
  python3 runtime.py --selftest   # teste buzzer + relais un par un (a faire AVANT le 1er run)
  python3 runtime.py --sim        # simulation PC (horloge virtuelle, sans materiel)
  python3 runtime.py --sim --inject FUITE   # simule une fuite pour voir le diagnostic
"""
import argparse
import csv
import os
import random
import statistics
import time
from collections import deque

import edge_models
from config import WATER_EMPTY_CM
from hardware import PUMP_MAX_S, Hardware, selftest

# ======================= CONFIG (brochage et etalonnage : voir config.py) =======================
LOOP_S = 2.0                 # periode de lecture
PUMP_PULSE_S = 5.0           # duree d'une impulsion d'arrosage
SOAK_S = 60.0                # attente apres impulsion (l'eau diffuse) avant de re-decider / diagnostiquer
FAN_MIN_DWELL_S = 180.0      # hysteresis : 3 min minimum entre 2 changements (60 s faisait battre le relais vers 28 °C)
LOCKOUT_AFTER = 2            # nb d'anomalies pompe/fuite consecutives avant de bloquer la pompe
HERE = os.path.dirname(os.path.abspath(__file__))
LOG_FILE = os.path.join(HERE, "logs", "readings.csv")
# ====================================================================================


# ----------------------------- horloge (virtuelle en simulation) -----------------------------
class Clock:
    def __init__(self, virtual):
        self.virtual, self.t = virtual, 0.0

    def now(self):
        return self.t if self.virtual else time.time()

    def sleep(self, s):
        if self.virtual:
            self.t += s
        else:
            time.sleep(s)


# ----------------------------- simulation PC -----------------------------
class Simulator:
    def __init__(self, clock, inject=None):
        self.clock, self.inject = clock, inject
        self.soil, self.dist = 560.0, 4.0
        self.pump = self.fan = self.buzzer = False
        self._last = 0.0

    def read(self):
        t = self.clock.now(); dt, self._last = t - self._last, t
        hour = (6 + t / 60.0 / 5) % 24            # 1 jour simule = 2 h virtuelles
        day = max(0.0, __import__("math").sin(__import__("math").pi * (hour - 6) / 12))
        temp = 18 + 14 * day + random.gauss(0, .3) - (3 if self.fan else 0)
        hum = max(30, min(98, 90 - 1.6 * (temp - 15) + random.gauss(0, 2)))
        light = day * 45000 + random.uniform(0, 30)
        # sechage (plus rapide s'il fait chaud / lumineux)
        self.soil += dt * (0.25 + 0.01 * (temp - 18) + 0.00001 * light)
        if self.pump:
            if self.inject == "POMPE_BLOQUEE": pass
            elif self.inject == "FUITE": self.soil -= dt * 6; self.dist += dt * 0.35
            else: self.soil -= dt * 36; self.dist += dt * 0.10
        soil = self.soil + random.gauss(0, 100 if self.inject == "CAPTEUR_DEFAILLANT" else 4)
        return dict(soil_raw=soil, air_temp=temp, air_hum=hum, light=light,
                    water_dist=self.dist + random.gauss(0, .05), flame=False)

    def set_pump(self, on): self.pump = on
    def pulse_pump(self, seconds): self.pump = True          # la boucle de simulation l'eteint
    def set_fan(self, on): self.fan = on
    def set_buzzer(self, on): self.buzzer = on
    def close(self): pass


# ----------------------------- controleur -----------------------------
class Controller:
    def __init__(self, hw, clock):
        self.hw, self.clock = hw, clock
        self.soil_hist = deque(maxlen=5)
        self.pump_on = self.fan_on = False
        self.pump_until = self.soak_until = 0.0
        self.fan_changed = -1e9
        self.before = None                 # releves avant impulsion, pour le diagnostic
        self.eval_pending = False
        self.bad_streak, self.locked = 0, False
        self.events = []                   # messages a afficher/loguer pour ce cycle

    def ev(self, msg):
        self.events.append(msg); print(f"[{self.clock.now():8.0f}s] {msg}")

    def step(self, s):
        now, ok = self.clock.now(), all(s[k] is not None for k in ("soil_raw", "air_temp", "air_hum", "light", "water_dist"))
        decision = dict(irrigation="", climate="", anomaly="")

        # --- 1. SECURITE (regles codees en dur, prioritaires sur l'IA) ---
        if s["flame"]:
            self.hw.set_buzzer(True)
            self._set_pump(False); self._set_fan(False)      # on coupe le ventilateur (alimente le feu) et la pompe
            self.ev("!!! FLAMME DETECTEE : buzzer ON, pompe et ventilateur coupes")
            return s, dict(decision, irrigation="SAFETY_FLAME")
        self.hw.set_buzzer(False)
        if not ok:
            self._set_pump(False)                            # capteur muet : pas d'arrosage a l'aveugle
            self.ev("lecture capteur manquante -> pompe coupee, cycle ignore")
            return s, decision

        self.soil_hist.append(s["soil_raw"])
        soil_std = statistics.pstdev(self.soil_hist) if len(self.soil_hist) >= 3 else 0.0

        # chien de garde pompe + fin d'impulsion
        if self.pump_on and now >= min(self.pump_until, self._pump_start + PUMP_MAX_S):
            self._set_pump(False); self.soak_until = now + SOAK_S; self.eval_pending = True
            self.ev("pompe OFF (fin d'impulsion), attente diffusion")

        # --- 2. DIAGNOSTIC post-irrigation (arbre 3) ---
        if self.eval_pending and now >= self.soak_until:
            b = self.before
            soil_after = statistics.median(self.soil_hist)    # meme estimateur qu'avant l'impulsion
            anomaly = edge_models.predict_anomaly(
                soil_before=b["soil"], soil_drop=b["soil"] - soil_after,
                water_drop_cm=s["water_dist"] - b["dist"], soil_std=soil_std)
            decision["anomaly"] = anomaly; self.eval_pending = False
            if anomaly == "NORMAL":
                self.bad_streak = 0; self.ev("diagnostic : irrigation efficace")
            else:
                self.bad_streak += anomaly in ("FUITE", "POMPE_BLOQUEE")
                self.ev(f"ANOMALIE : {anomaly} (serie={self.bad_streak})")
                if self.bad_streak >= LOCKOUT_AFTER:
                    self.locked = True; self.ev("POMPE VERROUILLEE (verifier le materiel puis relancer)")

        # --- 3. IRRIGATION (arbre 1) ---
        irr = edge_models.predict_irrigation(s["soil_raw"], s["air_temp"], s["air_hum"], s["light"], s["water_dist"])
        decision["irrigation"] = irr
        if irr == "REFILL_ALERT": self.ev("reservoir vide -> remplir (pompe interdite)")
        idle = not self.pump_on and now >= self.soak_until and not self.eval_pending
        if irr == "IRRIGATE" and idle and not self.locked and s["water_dist"] <= WATER_EMPTY_CM:
            self.before = dict(soil=statistics.median(self.soil_hist), dist=s["water_dist"])
            self.pump_on = True; self.hw.pulse_pump(PUMP_PULSE_S)   # arret programme par minuteur materiel
            self._pump_start = now; self.pump_until = now + PUMP_PULSE_S
            self.ev(f"pompe ON ({PUMP_PULSE_S:.0f}s) sol={s['soil_raw']:.0f}")

        # --- 4. CLIMAT (arbre 2) avec hysteresis temporelle ---
        clim = edge_models.predict_climate(s["air_temp"], s["air_hum"], s["light"])
        decision["climate"] = clim
        want_fan = clim == "FAN_ON"
        if want_fan != self.fan_on and now - self.fan_changed >= FAN_MIN_DWELL_S:
            self._set_fan(want_fan); self.fan_changed = now
            self.ev(f"ventilateur {'ON' if want_fan else 'OFF'}")
        return s, decision

    _pump_start = 0.0

    def _set_pump(self, on):
        self.pump_on = on; self.hw.set_pump(on)

    def _set_fan(self, on):
        self.fan_on = on; self.hw.set_fan(on)


# ----------------------------- main -----------------------------
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sim", action="store_true")
    ap.add_argument("--selftest", action="store_true")
    ap.add_argument("--inject", choices=["FUITE", "POMPE_BLOQUEE", "CAPTEUR_DEFAILLANT"])
    ap.add_argument("--steps", type=int, default=1500, help="nb de cycles en simulation")
    args = ap.parse_args()

    clock = Clock(virtual=args.sim)
    hw = Simulator(clock, args.inject) if args.sim else Hardware()
    if args.selftest:
        try: selftest(hw)
        finally: hw.close()
        return

    log_file = os.path.join(HERE, "logs", "sim_readings.csv") if args.sim else LOG_FILE   # la simulation ne pollue pas les vraies donnees
    os.makedirs(os.path.dirname(log_file), exist_ok=True)
    new = not os.path.exists(log_file)
    ctl = Controller(hw, clock)
    cols = ["t", "soil_raw", "air_temp", "air_hum", "light", "water_dist", "flame",
            "irrigation", "climate", "anomaly", "pump_on", "fan_on"]
    n = 0
    with open(log_file, "a", newline="") as f:
        w = csv.writer(f)
        if new: w.writerow(cols)
        try:
            while not args.sim or n < args.steps:
                s, d = ctl.step(hw.read())
                w.writerow([round(clock.now(), 1)] + [s[k] for k in cols[1:7]] +
                           [d["irrigation"], d["climate"], d["anomaly"], int(ctl.pump_on), int(ctl.fan_on)])
                f.flush(); n += 1; clock.sleep(LOOP_S)
        except KeyboardInterrupt:
            print("\nArret demande.")
        finally:
            hw.close()


if __name__ == "__main__":
    main()
