"""Simulated greenhouse, in the same units as the real sensors (raw soil ADC, cm, lux, °C, % RH).

2 tomato plants sharing one soil probe, a small reservoir watched by an ultrasonic sensor, a pulse pump,
an extraction fan and a buzzer. The simulator has the same interface as hardware.RealFarm, so the
controller does not know which one is running. Time is virtual: step(dt) advances it by dt seconds.

Faults can be injected to watch tree 3 diagnose them: leak, stuck pump, faulty soil sensor.
"""
import math
import random
from datetime import datetime, timedelta

from config import WATER_EMPTY_CM, WATER_FULL_CM   # edge_ai/edge is on sys.path (see trees.py)

STEP_S = 5.0                     # one simulation tick = 5 virtual seconds (= one pump pulse)
PUMP_SOIL_PER_S = 36.0           # raw points of soil wetting per second of pumping (~180 per 5 s pulse)
PUMP_DIST_PER_S = 0.10           # cm of tank drop per second of pumping, model scale (~0.5 cm per pulse)
FAULTS = ("leak", "blocked", "sensor")


class SimulatedFarm:
    is_simulated = True

    def __init__(self, seed: int = 7, start: datetime | None = None, start_day: int = 21):
        self.rng = random.Random(seed)
        self.now = start or datetime(2026, 4, 1, 6, 0)
        self.t0 = self.now - timedelta(days=start_day)            # transplant day
        self.soil_raw = 470.0                                      # true soil value (higher = drier)
        self.dist = 3.5                                            # true water distance, model scale (2.5 full, 10 empty)
        self.air_temp, self.air_hum, self.light, self.cloud = 20.0, 70.0, 0.0, 0.9
        self.pump = self.fan = self.buzzer = False
        self.pump_left = 0.0
        self.flame = False
        self.fault = None                                          # None | leak | blocked | sensor
        self._empty_s = 0.0
        self.auto_refilled = False

    # ---- interface shared with RealFarm --------------------------------------------------------
    def set_pump(self, on: bool):
        self.pump = bool(on)
        if not on:
            self.pump_left = 0.0

    def pulse_pump(self, seconds: float):
        self.pump, self.pump_left = True, seconds

    def set_fan(self, on: bool): self.fan = bool(on)
    def set_buzzer(self, on: bool): self.buzzer = bool(on)

    def read(self) -> dict:
        n = self.rng.gauss
        noise = 100 if self.fault == "sensor" else 4
        return {
            "t": self.now.timestamp(),
            "days_after_transplant": round((self.now - self.t0).total_seconds() / 86400, 2),
            "soil_raw": round(min(1022, max(1, self.soil_raw + n(0, noise)))),
            "air_temp": round(self.air_temp + n(0, 0.15), 1),
            "air_hum": round(min(99, max(15, self.air_hum + n(0, 0.8))), 1),
            "light": round(max(0, self.light + n(0, self.light * 0.02 + 1))),
            "water_dist": round(self.dist + n(0, 0.05), 2),
            "flame": self.flame,
        }

    # ---- physics -------------------------------------------------------------------------------
    def step(self, dt: float = STEP_S):
        prev_day = self.now.date()
        self.now += timedelta(seconds=dt)
        if self.now.date() != prev_day:                            # new day: new weather
            self.cloud = self.rng.choice([1.0, 1.0, 0.9, 0.75, 0.55, 0.35])
        h = self.now.hour + self.now.minute / 60 + self.now.second / 3600
        sun = max(0.0, math.sin(math.pi * (h - 6) / 13)) if 6 <= h <= 19 else 0.0
        self.light = 42000 * sun * self.cloud

        a = lambda k: 1 - (1 - k) ** (dt / 600)                   # noqa: E731  (rates were tuned per 10 min)
        outside = 15 + 9 * max(0.0, math.sin(math.pi * (h - 7) / 14)) * (0.6 + 0.4 * self.cloud)
        target, k = outside + 11 * sun * self.cloud, 0.18                        # greenhouse effect
        if self.fan:
            target, k = outside + 3 * sun * self.cloud, 0.35
        self.air_temp += a(k) * (target - self.air_temp)

        # Plants drink: transpiration follows light, dry air (VPD) and plant size
        es = 0.6108 * math.exp(17.27 * self.air_temp / (self.air_temp + 237.3))
        vpd = es * (1 - self.air_hum / 100)
        size = min(1.0, 0.25 + (self.now - self.t0).days / 45)
        raw_per_h = 12 * (0.25 + 4.2 * sun * self.cloud) * (0.6 + 0.5 * vpd) * size
        self.soil_raw = min(900.0, self.soil_raw + raw_per_h * dt / 3600)

        hum_target = 80 - 1.6 * (self.air_temp - 20) + 6 * size * sun - (14 if self.fan else 0)
        self.air_hum = min(97.0, max(25.0, self.air_hum + a(0.2) * (hum_target - self.air_hum)))

        if self.pump:
            run = min(dt, self.pump_left)
            if self.dist < 12.5 and self.fault != "blocked":
                if self.fault == "leak":                          # water goes to the floor, not the pot
                    self.soil_raw -= 6 * run; self.dist += 0.35 * run
                else:
                    self.soil_raw -= PUMP_SOIL_PER_S * run; self.dist += PUMP_DIST_PER_S * run
                self.soil_raw = max(280.0, self.soil_raw)
            self.pump_left -= run
            if self.pump_left <= 0:
                self.pump = False

        # Simulated caretaker: the tank is refilled after it stayed empty for 6 hours (the alert shows first)
        self._empty_s = self._empty_s + dt if self.dist > WATER_EMPTY_CM else 0.0
        if self._empty_s >= 6 * 3600:
            self.dist, self._empty_s, self.auto_refilled = WATER_FULL_CM, 0.0, True

    # ---- demo helpers ----------------------------------------------------------------------------
    def refill(self): self.dist = WATER_FULL_CM
    def dry_out(self): self.soil_raw = 700.0
