"""Autonomous greenhouse agent: the 3 decision trees of edge_ai, plus manual control, history, alerts and explanations.

Same rules as edge_ai/edge/runtime.py. Each tick (2 s on the Pi, 5 virtual seconds in simulation):
  1. Safety (hard-coded, above the AI and above manual commands): flame -> buzzer on, pump and fan cut;
     a missing sensor reading -> pump cut, cycle skipped; tank empty -> pump forbidden; pump locked -> no watering.
  2. Tree 3, 60 s after each pulse: was the watering NORMAL, a leak (FUITE), a stuck pump (POMPE_BLOQUEE)
     or a faulty soil sensor (CAPTEUR_DEFAILLANT)? Two leaks / stuck pumps in a row lock the pump.
  3. Watering: a command from the app ("water now") or, in automatic mode, tree 1 (5 s pulse, then 60 s to spread).
  4. Ventilation: a command from the app or, in automatic mode, tree 2 (at most one change every 3 minutes).
A manual command puts that equipment in manual mode for 1 hour, then the greenhouse decides again.
"""
import itertools
import math
import statistics
from collections import Counter, deque
from datetime import datetime

from trees import explain                                  # noqa: I001 (puts edge_ai/edge on sys.path)
from config import SOIL_RAW_DRY, SOIL_RAW_WET, TANK_LITERS, WATER_EMPTY_CM, model_cm_to_liters, soil_pct, tank_pct

PUMP_PULSE_S = 5.0
MANUAL_WATER_S = (3, 5, 8)            # durations offered in the app (the hardware watchdog stops at 10 s)
SOAK_S = 60.0
FAN_MIN_DWELL_S = 180.0                # at most one fan change every 3 minutes (60 s made it chatter around 28 °C)
MANUAL_HOLD_S = 3600.0                # a manual command holds 1 hour, then automatic again
LOCKOUT_AFTER = 2
HISTORY_EVERY_S = 300                 # one history point every 5 minutes
HISTORY_POINTS = 7 * 288              # 7 days
STRESS_RAW = 650                      # drier than this (raw ADC), the tomato is under water stress
WATER_RAW = 600                       # tree 1's usual watering threshold (agronomist policy, normal day)
TANK_WATCH_PCT = 20                   # below this the tank is "to look at"
FAN_TEMP = 30                         # agronomist policy: hot above 30 °C
REQUIRED = ("soil_raw", "air_temp", "air_hum", "light", "water_dist")
LABEL = {"soil_raw": "soil", "air_temp": "temperature", "air_hum": "humidity", "light": "light",
         "water_dist": "water level"}
DIAG = {"NORMAL": "effective", "FUITE": "leak", "POMPE_BLOQUEE": "pump stuck", "CAPTEUR_DEFAILLANT": "soil sensor faulty"}

STAGES = [(0, "Seedling"), (14, "Vegetative growth"), (25, "Flowering"),
          (40, "Fruit set"), (60, "Ripening"), (80, "Harvest")]


def growth_estimate(dat: float, vigor: float, soil_raw: float) -> dict:
    """Digital-twin estimate of one plant from its age and how well it has been kept (no sensor measures the plant)."""
    v = 0.55 + 0.45 * vigor
    return {
        "stage": [name for d, name in STAGES if dat >= d][-1],
        "height_cm": round((10 + 115 * (1 - math.exp(-dat / 35))) * v, 1),
        "leaves": int(min(26, 4 + dat * 0.55) * (0.7 + 0.3 * vigor)),
        "trusses": int(max(0, min(5, (dat - 25) // 7 + 1))) if dat >= 25 else 0,
        "fruits": int(max(0, min(14, (dat - 40) * 0.7)) * v) if dat >= 40 else 0,
        "ripeness": round(max(0.0, min(1.0, (dat - 60) / 20)), 2),
        "wilt": round(max(0.0, min(1.0, (soil_raw - STRESS_RAW) / 200)), 2),
        "vigor": round(vigor, 2),
    }


def _pstdev(xs) -> float:
    """Population std in plain floats (statistics.pstdev uses exact fractions: 20x slower, same result here)."""
    m = sum(xs) / len(xs)
    return math.sqrt(sum((x - m) ** 2 for x in xs) / len(xs))


def _new_day():
    return {"pulses": 0, "water_l": 0.0, "fan_s": 0.0, "seconds": 0.0, "fire_alarms": 0,
            "irrigation_s": Counter(), "climate_s": Counter(), "anomalies": Counter()}


def why_tree(d: dict) -> str:
    """The path of a tree decision in plain words: 'water distance 6.0 ≤ 9.97, soil raw 640 > 614 …'."""
    unit = {"air_temp": " °C", "air_hum": " %", "light": " lx", "water_dist": " cm", "water_drop_cm": " cm"}
    name = {"soil_raw": "soil", "air_temp": "air", "air_hum": "humidity", "light": "light", "water_dist": "water distance",
            "soil_before": "soil before", "soil_drop": "soil change", "water_drop_cm": "water used", "soil_std": "sensor spread"}
    fmt = lambda f, v: f"{v:.0f}" if abs(v) >= 100 else f"{v:.2f}".rstrip("0").rstrip(".")   # noqa: E731
    return ", ".join(f"{name.get(s['f'], s['f'])} {fmt(s['f'], s['v'])}{unit.get(s['f'], '')} "
                     f"{'≤' if s['le'] else '>'} {fmt(s['f'], s['t'])}" for s in d["path"])


class Controller:
    def __init__(self, farm):
        self.farm = farm
        self.sensors = None
        self.soil_hist = deque(maxlen=5)
        self.pumping = False
        self.pump_until = self.soak_until = 0.0
        self.eval_pending = False
        self.before = None
        self.fan_on = False
        self.fan_changed = -1e12
        self.fan_run = None                                     # current fan run {start, max_temp, manual}
        self.buzzer = False
        self.locked, self.bad_streak = False, 0
        self.alarm_fire = self.tank_low = self.missing = False
        self.decision = {"irrigation": None, "climate": None}
        self.last_diag = None
        self.vision = {"status": "idle", "detections": [], "image": None, "time": None}
        self.vigor = [1.0, 1.0]
        self.history = deque(maxlen=HISTORY_POINTS)
        self.daily: dict[str, dict] = {}
        self.events = deque(maxlen=400)
        self.diagnoses = deque(maxlen=300)
        self.fan_runs = deque(maxlen=200)
        self.last_valid: dict[str, dict] = {}
        self.since: dict[str, str] = {}                         # alert name -> since when (iso)
        self.modes = {"irrigation": {"mode": "auto"}, "fan": {"mode": "auto"}}
        self.command = None                                     # the last command from the app (with its steps)
        self._cmd_ids = itertools.count(1)
        self._bucket = None
        self._last_t = None
        self._ids = itertools.count(1)
        self.log("info", "Agent started", "Automatic mode: 3 decision trees, 100 % local.", kind="system")

    # ---- helpers ------------------------------------------------------------------------------
    @property
    def now(self) -> float:
        return self._last_t or 0.0

    def stamp(self, t: float | None = None) -> str:
        return datetime.fromtimestamp(self.now if t is None else t).isoformat(timespec="seconds") if (t or self._last_t) else ""

    def log(self, level: str, title: str, detail: str = "", kind: str = "system", why: str = ""):
        """level: info | auto | user | warn | alarm. kind: irrigation | fan | tank | safety | sensor | system."""
        self.events.appendleft({"id": next(self._ids), "level": level, "kind": kind, "title": title,
                                "detail": detail, "why": why, "time": self.stamp()})

    def _day(self) -> dict:
        key = self.sensors["timestamp"][:10]
        if key not in self.daily:
            self.daily[key] = _new_day()
            for old in sorted(self.daily)[:-14]:                    # keep two weeks of daily counters
                del self.daily[old]
        return self.daily[key]

    def _pump_off(self):
        self.farm.set_pump(False)
        self.pumping = False

    def _fan(self, on: bool, now: float):
        if on == self.fan_on:
            return
        self.farm.set_fan(on)
        self.fan_on, self.fan_changed = on, now
        t = self.sensors.get("air_temp")
        if on:
            self.fan_run = {"start": self.stamp(now), "max_temp": t, "manual": self.modes["fan"]["mode"] == "manual"}
        elif self.fan_run:
            self.fan_runs.appendleft({**self.fan_run, "end": self.stamp(now)})
            self.fan_run = None

    def _alert(self, name: str, active: bool):
        if active:
            self.since.setdefault(name, self.stamp())
        else:
            self.since.pop(name, None)

    def unlock_pump(self, who: str = "the app"):
        if self.locked:
            self.locked, self.bad_streak = False, 0
            self.log("user", "Pump unlocked", f"Unlocked by {who} after checking the hardware.", kind="irrigation")

    # ---- manual control (from the app) ----------------------------------------------------------
    def set_mode(self, equipment: str, mode: str, who: str):
        if equipment not in self.modes or mode not in ("auto", "manual"):
            raise ValueError("equipment must be irrigation or fan, mode auto or manual")
        what = {"irrigation": "Watering", "fan": "Ventilation"}[equipment]
        if mode == "auto":
            if self.modes[equipment]["mode"] != "auto":
                self.log("user", f"{what} back to automatic", f"{who} gave it back to the greenhouse.", kind=equipment)
            self.modes[equipment] = {"mode": "auto"}
        else:
            self.modes[equipment] = {"mode": "manual", "since": self.stamp(), "until": self.now + MANUAL_HOLD_S, "by": who}
            if equipment == "fan":
                self.modes["fan"]["on"] = self.fan_on
            self.log("user", f"{who} took over the {what.lower()}",
                     f"Manual until {datetime.fromtimestamp(self.now + MANUAL_HOLD_S):%H:%M}, then automatic again.", kind=equipment)

    def request(self, kind: str, who: str, seconds: float | None = None, on: bool | None = None) -> dict:
        """A command from the app. It is 'sent' now, 'received' at the next tick, then executed or refused."""
        if self.command and self.command["status"] in ("sent", "received", "running", "checking"):
            if kind == "water" and self.command["kind"] == "water":
                raise ValueError("A watering is already in progress.")
        if kind == "water" and seconds not in MANUAL_WATER_S:
            raise ValueError(f"seconds must be one of {MANUAL_WATER_S}")
        self.command = {"id": next(self._cmd_ids), "kind": kind, "seconds": seconds, "on": on, "by": who,
                        "status": "sent", "steps": {"sent": self.stamp()}, "message": "", "result": None}
        return self.command

    def stop_watering(self, who: str):
        c = self.command
        if self.pumping:
            self._pump_off()
            self.eval_pending = False
            self.soak_until = self.now + SOAK_S
            self.log("user", "Watering stopped", f"Stopped by {who}.", kind="irrigation")
        if c and c["kind"] == "water" and c["status"] in ("sent", "received", "running", "checking"):
            c["status"], c["message"] = "stopped", "Stopped from the app."
            c["steps"]["done"] = self.stamp()

    def _refuse(self, reason: str):
        c = self.command
        c["status"], c["message"] = "refused", reason
        c["steps"]["done"] = self.stamp()
        self.log("warn", "Command refused", reason, kind="irrigation" if c["kind"] == "water" else "fan")

    def _run_command(self, r: dict, now: float, day: dict):
        """Called once all readings are valid and no flame: start what the app asked for."""
        c = self.command
        if not c or c["status"] != "received":
            return
        if c["kind"] == "fan":
            self.modes["fan"] = {"mode": "manual", "since": self.stamp(), "until": now + MANUAL_HOLD_S, "by": c["by"], "on": c["on"]}
            self._fan(bool(c["on"]), now)
            c["status"], c["steps"]["done"] = "success", self.stamp()
            c["message"] = "The fan is running." if c["on"] else "The fan is stopped."
            self.log("user", f"Fan {'started' if c['on'] else 'stopped'} by hand", f"By {c['by']}. Automatic again in 1 hour.",
                     kind="fan", why=f"Air {r['air_temp']:.1f} °C, humidity {r['air_hum']:.0f} %.")
            return
        if self.locked:
            return self._refuse("The pump is locked after two faulty waterings. Check it, then unlock it in Settings.")
        if r["water_dist"] > WATER_EMPTY_CM:
            return self._refuse("The tank is empty. Fill it first: the pump never runs dry.")
        if self.pumping or self.eval_pending:
            return self._refuse("A watering just happened. Wait one minute for the water to spread.")
        self.modes["irrigation"] = {"mode": "manual", "since": self.stamp(), "until": now + MANUAL_HOLD_S, "by": c["by"]}
        self._start_pulse(r, now, day, c["seconds"], manual=True)
        c["status"], c["steps"]["running"] = "running", self.stamp()

    def _start_pulse(self, r: dict, now: float, day: dict, seconds: float, manual: bool):
        self.before = {"soil": statistics.median(self.soil_hist), "dist": r["water_dist"], "seconds": seconds, "manual": manual}
        self.farm.pulse_pump(seconds)
        self.pumping, self.pump_until = True, now + seconds
        day["pulses"] += 1
        if self._bucket:
            self._bucket["pulses"] += 1

    # ---- one tick ----------------------------------------------------------------------------
    def step(self, r: dict):
        """r = one reading from the farm: raw sensor units + 't' (epoch seconds) + 'days_after_transplant'."""
        now = r["t"]
        dt = 0.0 if self._last_t is None else max(0.0, min(10.0, now - self._last_t))
        self._last_t = now
        stamp = datetime.fromtimestamp(now)
        ok = all(r.get(k) is not None for k in REQUIRED)
        self.sensors = {
            **r, "timestamp": stamp.isoformat(timespec="seconds"), "hour": stamp.hour + stamp.minute / 60,
            "soil_pct": round(soil_pct(r["soil_raw"]), 1) if r.get("soil_raw") is not None else None,
            "water_level_pct": round(tank_pct(r["water_dist"]), 1) if r.get("water_dist") is not None else None,
        }
        for k in REQUIRED:
            if r.get(k) is not None:
                self.last_valid[k] = {"v": r[k], "t": self.sensors["timestamp"]}
        day = self._day()
        day["seconds"] += dt
        if self.fan_on:
            day["fan_s"] += dt
            if self.fan_run and r.get("air_temp") is not None:
                self.fan_run["max_temp"] = max(self.fan_run["max_temp"] or r["air_temp"], r["air_temp"])
        if self.pumping and now >= self.pump_until:                    # the farm already stopped it (timer)
            self.pumping = False
            self.soak_until, self.eval_pending = now + SOAK_S, True
            if self.command and self.command["status"] == "running":
                self.command["status"], self.command["steps"]["checking"] = "checking", self.stamp()
        for eq, m in self.modes.items():                               # manual for 1 hour, then automatic again
            if m["mode"] == "manual" and now >= m["until"]:
                self.modes[eq] = {"mode": "auto"}
                self.log("info", f"{'Watering' if eq == 'irrigation' else 'Ventilation'} back to automatic",
                         "One hour without a manual command: the greenhouse decides again.", kind=eq)
        if self.command and self.command["status"] == "sent":
            self.command["status"], self.command["steps"]["received"] = "received", self.stamp()

        # --- 1. SAFETY ---
        fire = bool(r.get("flame")) or self.vision.get("status") == "fire"
        self._alert("fire", fire)
        if fire:
            if not self.alarm_fire:
                day["fire_alarms"] += 1
                self.log("alarm", "Flame in the greenhouse", "Buzzer on. Pump and fan cut (the fan would feed the fire).",
                         kind="safety")
            if self.pumping:
                self.eval_pending = False                              # an interrupted pulse cannot be judged
                if self.command and self.command["status"] == "running":
                    self.command["status"], self.command["message"] = "error", "Stopped by the fire alarm."
            if self.command and self.command["status"] == "received":
                self._refuse("A flame is detected: everything is cut until it is gone.")
            self._pump_off(); self._fan(False, now)
            self.farm.set_buzzer(True)
            self.alarm_fire = self.buzzer = True
            self.decision = {"irrigation": {"label": "SAFETY_FLAME", "path": []}, "climate": None}
            self._record(now, dt)
            return
        if self.alarm_fire:
            self.log("info", "Flame gone", "The flame sensor is clear again. Back to normal.", kind="safety")
        self.alarm_fire = False
        if self.buzzer:
            self.farm.set_buzzer(False); self.buzzer = False

        self._alert("missing", not ok)
        if not ok:
            if not self.missing:
                gone = ", ".join(LABEL[k] for k in REQUIRED if r.get(k) is None)
                self.log("warn", "A sensor stopped answering", f"No {gone}. Watering paused: the greenhouse never waters blind.",
                         kind="sensor")
            self.missing = True
            if self.pumping:
                self.eval_pending = False
            self._pump_off()
            c = self.command
            if c and c["status"] == "received":
                if c["kind"] == "fan" and r.get("air_temp") is not None and r.get("air_hum") is not None:
                    self._run_command(r, now, day)                     # the fan does not need the soil or tank
                else:
                    self._refuse("A sensor is not answering: watering is paused for safety." if c["kind"] == "water"
                                 else "The air sensor is not answering.")
            self._record(now, dt)
            return
        if self.missing:
            self.log("info", "Sensors back", "All readings are valid again.", kind="sensor")
        self.missing = False

        self.soil_hist.append(r["soil_raw"])
        soil_std = _pstdev(self.soil_hist) if len(self.soil_hist) >= 3 else 0.0

        # --- 2. DIAGNOSIS after a pulse (tree 3) ---
        if self.eval_pending and now >= self.soak_until:
            self._diagnose(r, soil_std, day)

        # --- 3. WATERING: command from the app, or tree 1 in automatic mode ---
        irr = explain("irrigation", {k: r[k] for k in REQUIRED})
        self.decision["irrigation"] = irr
        day["irrigation_s"][irr["label"]] += dt
        low = r["water_dist"] > WATER_EMPTY_CM or irr["label"] == "REFILL_ALERT"
        if low and not self.tank_low:
            self.log("warn", "The tank is empty", "Pump forbidden until it is filled.", kind="tank", why=why_tree(irr))
        if not low and self.tank_low:
            self.log("info", "Tank filled", f"Level {self.sensors['water_level_pct']:.0f} %.", kind="tank")
        self.tank_low = low
        self._alert("tank", low or self.sensors["water_level_pct"] < TANK_WATCH_PCT)
        self._alert("locked", self.locked)
        self._alert("dry", r["soil_raw"] > STRESS_RAW)
        self._run_command(r, now, day)
        idle = not self.pumping and now >= self.soak_until and not self.eval_pending
        auto = self.modes["irrigation"]["mode"] == "auto"
        if auto and irr["label"] == "IRRIGATE" and idle and not self.locked and not low:
            self._start_pulse(r, now, day, PUMP_PULSE_S, manual=False)
            self.log("auto", "Watering, 5 seconds", f"The soil was at {self.sensors['soil_pct']:.0f} % "
                     f"({r['soil_raw']:.0f} raw), {r['air_temp']:.1f} °C.", kind="irrigation",
                     why=f"Tree 1 said water: {why_tree(irr)}.")

        # --- 4. VENTILATION: tree 2 in automatic mode, the app's choice in manual mode ---
        clim = explain("climate", {k: r[k] for k in ("air_temp", "air_hum", "light")})
        self.decision["climate"] = clim
        day["climate_s"][clim["label"]] += dt
        fm = self.modes["fan"]
        want = bool(fm.get("on")) if fm["mode"] == "manual" else clim["label"] == "FAN_ON"
        if want != self.fan_on and (fm["mode"] == "manual" or now - self.fan_changed >= FAN_MIN_DWELL_S):
            self._fan(want, now)
            if fm["mode"] == "auto":
                hot = r["air_temp"] > FAN_TEMP
                self.log("auto", "Ventilation started" if want else "Ventilation stopped",
                         (f"The air was {r['air_temp']:.1f} °C, {r['air_hum']:.0f} % humidity." if want
                          else f"The air came back to {r['air_temp']:.1f} °C."), kind="fan",
                         why=(f"Above {FAN_TEMP} °C tomatoes suffer. " if want and hot else "") + f"Tree 2: {why_tree(clim)}.")
        self._record(now, dt)

    def _diagnose(self, r: dict, soil_std: float, day: dict):
        self.eval_pending = False
        b = self.before
        after = statistics.median(self.soil_hist)
        inputs = {"soil_before": b["soil"], "soil_drop": b["soil"] - after,
                  "water_drop_cm": r["water_dist"] - b["dist"], "soil_std": soil_std}
        d = explain("anomaly", inputs)
        used = max(0.0, model_cm_to_liters(inputs["water_drop_cm"]))
        self.last_diag = {**d, "inputs": {k: round(v, 2) for k, v in inputs.items()}, "time": self.sensors["timestamp"],
                          "seconds": b["seconds"], "manual": b["manual"], "water_l": round(used, 3),
                          "soil_before_pct": round(soil_pct(b["soil"]), 1), "soil_after_pct": round(soil_pct(after), 1)}
        self.diagnoses.appendleft(self.last_diag)
        day["anomalies"][d["label"]] += 1
        day["water_l"] += used
        c = self.command
        cmd = c if c and c["kind"] == "water" and c["status"] == "checking" else None
        if d["label"] == "NORMAL":
            self.bad_streak = 0
            self.log("auto", "Watering checked: it worked", f"The soil went from {self.last_diag['soil_before_pct']:.0f} % to "
                     f"{self.last_diag['soil_after_pct']:.0f} %, {used * 1000:.0f} mL taken from the tank.", kind="irrigation",
                     why=f"Tree 3: {why_tree(d)}.")
        else:
            if d["label"] in ("FUITE", "POMPE_BLOQUEE"):
                self.bad_streak += 1
            self.log("warn", f"Watering problem: {DIAG[d['label']]}",
                     f"Soil change {inputs['soil_drop']:+.0f}, water used {inputs['water_drop_cm']:.2f} cm, sensor spread {soil_std:.0f}.",
                     kind="irrigation", why=f"Tree 3 said {d['label']}: {why_tree(d)}.")
            if self.bad_streak >= LOCKOUT_AFTER and not self.locked:
                self.locked = True
                self.log("alarm", "Pump locked", f"{LOCKOUT_AFTER} faulty waterings in a row. Check the pump and the pipes, "
                         "then unlock it in Settings.", kind="irrigation")
        if cmd:
            cmd["steps"]["done"] = self.stamp()
            cmd["result"] = {k: self.last_diag[k] for k in ("label", "soil_before_pct", "soil_after_pct", "water_l", "seconds")}
            cmd["status"] = "success" if d["label"] == "NORMAL" else "error"
            cmd["message"] = {"NORMAL": "", "FUITE": "Water left the tank but the soil barely changed: look for a leak in the pipe.",
                              "POMPE_BLOQUEE": "I got your order, but no water came out. Check that the pipe is not bent "
                                               "and that the pump is plugged in.",
                              "CAPTEUR_DEFAILLANT": "The soil readings jump around: check that the soil probe is well in the soil."}[d["label"]]

    # ---- history ------------------------------------------------------------------------------
    def _record(self, now: float, dt: float):
        b = self._bucket
        if b is None:
            b = self._bucket = {"start": now, "pulses": 0, "fan_s": 0.0, "secs": 0.0}
        b["secs"] += dt
        if self.fan_on:
            b["fan_s"] += dt
        if now - b["start"] < HISTORY_EVERY_S:
            return
        s = self.sensors
        if s.get("soil_raw") is not None:
            for i in range(2):                                         # plant vigor: drops under water stress
                target = 1.0 if s["soil_raw"] <= STRESS_RAW else max(0.0, 1 - (s["soil_raw"] - STRESS_RAW) / 200)
                self.vigor[i] += 0.002 * (target - self.vigor[i])
        rnd = lambda v, n=1: None if v is None else round(v, n)       # noqa: E731
        self.history.append({
            "t": s["timestamp"], "soil": rnd(s.get("soil_pct")), "soil_raw": rnd(s.get("soil_raw"), 0),
            "temp": rnd(s.get("air_temp")), "hum": rnd(s.get("air_hum")), "light": rnd(s.get("light"), 0),
            "tank": rnd(s.get("water_level_pct")), "pump": b["pulses"],
            "fan": round(b["fan_s"] / b["secs"], 2) if b["secs"] else int(self.fan_on),
            "irr": (self.decision["irrigation"] or {}).get("label"),
            "clim": (self.decision["climate"] or {}).get("label"),
        })
        self._bucket = {"start": now, "pulses": 0, "fan_s": 0.0, "secs": 0.0}

    # ---- persistence (real mode) --------------------------------------------------------------
    def dump(self) -> dict:
        return {"history": list(self.history), "events": list(self.events), "diagnoses": list(self.diagnoses),
                "fan_runs": list(self.fan_runs),
                "daily": {k: {**v, "irrigation_s": dict(v["irrigation_s"]), "climate_s": dict(v["climate_s"]),
                              "anomalies": dict(v["anomalies"])} for k, v in self.daily.items()},
                "vigor": self.vigor, "locked": self.locked, "bad_streak": self.bad_streak}

    def restore(self, d: dict):
        self.history.extend(d.get("history", []))
        self.events.extend(d.get("events", []))
        self._ids = itertools.count(max((e["id"] for e in self.events), default=0) + 1)
        self.diagnoses.extend(d.get("diagnoses", []))
        self.fan_runs.extend(d.get("fan_runs", []))
        self.last_diag = self.diagnoses[0] if self.diagnoses else None
        for k, v in d.get("daily", {}).items():
            self.daily[k] = {**v, "irrigation_s": Counter(v["irrigation_s"]), "climate_s": Counter(v["climate_s"]),
                             "anomalies": Counter(v["anomalies"])}
        self.vigor = d.get("vigor", self.vigor)
        self.locked, self.bad_streak = d.get("locked", False), d.get("bad_streak", 0)   # a lock survives a reboot

    # ---- derived numbers for the app ------------------------------------------------------------
    def tank_days(self) -> float | None:
        """Days of water left at the pace of the last 3 days (None = not enough data yet)."""
        lvl = (self.sensors or {}).get("water_level_pct")
        days = sorted(self.daily)[-4:-1] or sorted(self.daily)[-1:]
        used = [self.daily[d]["water_l"] for d in days if self.daily[d]["seconds"] > 6 * 3600]
        if lvl is None or not used or sum(used) <= 0:
            return None
        return round(lvl / 100 * TANK_LITERS / (sum(used) / len(used)), 1)

    def alerts(self) -> list[dict]:
        s, out = self.sensors or {}, []
        if "fire" in self.since:
            out.append({"id": "fire", "level": "critical", "title": "A flame in the greenhouse",
                        "detail": "The alarm is sounding. Pump and fan are cut.", "since": self.since["fire"]})
        if "locked" in self.since:
            out.append({"id": "locked", "level": "watch", "title": "The pump is locked",
                        "detail": "Two faulty waterings in a row. Check the pump, then unlock it.", "since": self.since["locked"]})
        if "missing" in self.since:
            gone = [LABEL[k] for k in REQUIRED if s.get(k) is None]
            out.append({"id": "missing", "level": "watch", "title": "A sensor stopped answering",
                        "detail": f"No news of the {', '.join(gone)}. Watering is paused.", "since": self.since["missing"]})
        if "tank" in self.since:
            d = self.tank_days()
            out.append({"id": "tank", "level": "watch", "title": "The tank is empty" if self.tank_low else "The tank is getting low",
                        "detail": "Fill it: the pump is forbidden until then." if self.tank_low
                        else (f"Water for about {d:.0f} day{'s' if d >= 2 else ''}. " if d else "") + "Fill it when you pass by.",
                        "since": self.since["tank"]})
        if "dry" in self.since:
            out.append({"id": "dry", "level": "watch", "title": "The soil is a bit dry",
                        "detail": "I am watering." if self.pumping or self.eval_pending else
                        "Watering is in manual mode." if self.modes["irrigation"]["mode"] == "manual" else
                        "I will water at the next check.", "since": self.since["dry"]})
        return out

    def snapshot(self, extra: dict | None = None) -> dict:
        s = self.sensors or {}
        today = self.daily.get(s.get("timestamp", "")[:10], _new_day())
        now = self.now
        phase = ("pulsing" if self.pumping else "checking" if self.eval_pending
                 else "soaking" if now < self.soak_until else "ready")
        soil_raw = s.get("soil_raw") if s.get("soil_raw") is not None else 600
        day_key = s.get("timestamp", "")[:10]
        runs = [r for r in self.fan_runs if r["start"][:10] == day_key][::-1]
        if self.fan_run:
            runs.append({**self.fan_run, "end": None})
        state = {
            "sensors": s,
            "soil_avg": s.get("soil_pct"),
            "actuators": {"pump": self.pumping, "fan": self.fan_on, "buzzer": self.buzzer},
            "decision": self.decision,
            "last_diagnosis": self.last_diag,
            "irrigation": {"phase": phase, "soak_left_s": max(0, round(self.soak_until - now)),
                           "pulses_today": today["pulses"], "water_today_l": round(today["water_l"], 3),
                           "total_l": round(sum(d["water_l"] for d in self.daily.values()), 3),
                           "pulses_total": sum(d["pulses"] for d in self.daily.values()),
                           "locked": self.locked, "bad_streak": self.bad_streak},
            "plants": [growth_estimate(s.get("days_after_transplant", 0), self.vigor[i], soil_raw) for i in range(2)],
            "alarms": {"fire": self.alarm_fire, "tank_low": self.tank_low, "missing": self.missing,
                       "pump_locked": self.locked},
            "alerts": self.alerts(),
            "modes": {eq: {**m, "seconds_left": max(0, round(m["until"] - now))} if m["mode"] == "manual" else m
                      for eq, m in self.modes.items()},
            "command": self.command,
            "tank_days": self.tank_days(),
            "fan_runs_today": runs,
            "last_valid": self.last_valid,
            "thresholds": {"water_pct": round(soil_pct(WATER_RAW)), "water_raw": WATER_RAW, "fan_temp": FAN_TEMP,
                           "tank_watch_pct": TANK_WATCH_PCT, "comfort": [15, FAN_TEMP],
                           "soil_wet_raw": SOIL_RAW_WET, "soil_dry_raw": SOIL_RAW_DRY, "manual_seconds": MANUAL_WATER_S},
            "vision": self.vision,
            "simulated": self.farm.is_simulated,
        }
        if extra:
            state.update(extra)
        return state
