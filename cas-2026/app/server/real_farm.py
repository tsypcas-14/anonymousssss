"""Real greenhouse on the Raspberry Pi 3B: wraps the shared driver edge_ai/edge/hardware.py.

Wiring, calibration and polarity live in edge_ai/edge/config.py (one place for the CLI agent and the app).
Run `python3 edge_ai/edge/runtime.py --selftest` on the Pi before the first start.
"""
import time
from datetime import datetime

from hardware import Hardware     # edge_ai/edge/hardware.py (on sys.path, see trees.py)


class RealFarm:
    is_simulated = False

    def __init__(self, transplant_date: datetime):
        self.transplant_date = transplant_date
        self.hw = Hardware()

    def read(self) -> dict:
        """Blocking (~1.5 s: serial, ultrasonic, I2C): call it from a worker thread."""
        r = self.hw.read()
        r["t"] = time.time()
        r["days_after_transplant"] = round((datetime.now() - self.transplant_date).total_seconds() / 86400, 2)
        return r

    def set_pump(self, on: bool): self.hw.set_pump(on)
    def pulse_pump(self, seconds: float): self.hw.pulse_pump(seconds)   # stopped by a timer, not by the loop
    def set_fan(self, on: bool): self.hw.set_fan(on)
    def set_buzzer(self, on: bool): self.hw.set_buzzer(on)
    def close(self): self.hw.close()
