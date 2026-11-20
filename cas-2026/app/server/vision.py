"""Camera watch for the server: runs the YOLO model and reports fire / smoke / leaf anomalies.

Real mode : takes a photo with the Pi camera every CAMERA_PERIOD_S seconds.
Sim mode  : "takes the photo" from app/server/demo_images/<scene>/, so the real model
            is exercised on real pictures during a demo without any camera.
If the model or its libraries are missing, vision is reported as unavailable (no fake results).
"""
import random
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).parent
DEMO = HERE / "demo_images"
CAPTURES = HERE / "data" / "captures"
MODELS = ROOT / "vision" / "models"
CAMERA_PERIOD_S = 30

sys.path.insert(0, str(ROOT / "vision"))


def find_model() -> Path | None:
    for name in ("smartfarm_yolo11n_ncnn_model", "smartfarm_yolo11n.pt", "smartfarm_yolo11n.onnx"):
        if (MODELS / name).exists():
            return MODELS / name
    return None


class Vision:
    def __init__(self, simulated: bool):
        self.simulated = simulated
        self.scene = "normal"                 # sim only: normal | leaf_anomaly | fire
        self.model = None
        self.error = None
        self.fire_streak = 0
        self.grab = None
        self._last_scene = None
        CAPTURES.mkdir(parents=True, exist_ok=True)

    def load(self):
        path = find_model()
        if path is None:
            self.error = "No trained vision model found in vision/models/."
            return
        try:
            import detect_pi                                  # vision/detect_pi.py
            from ultralytics import YOLO
            self.dp = detect_pi
            self.model = YOLO(str(path), task="detect")
            self.model_name = path.name
            if not self.simulated:
                self.grab = detect_pi.ouvrir_camera("picamera")
        except Exception as e:                                # missing lib, no camera...
            self.model = None
            self.error = f"Vision unavailable: {e}"

    def _demo_frame(self):
        import cv2
        files = sorted((DEMO / self.scene).glob("*.jpg"))
        if not files:
            return None
        return cv2.imread(str(random.choice(files)))

    def analyse_once(self) -> dict:
        """Blocking: grab one frame, run the model, save the annotated picture."""
        if self.model is None:
            return {"status": "unavailable", "detections": [], "image": None,
                    "time": None, "message": self.error}
        import cv2
        frame = self._demo_frame() if self.simulated else self.grab()
        if frame is None:
            return {"status": "unavailable", "detections": [], "image": None, "time": None,
                    "message": "No picture available."}
        t0 = time.perf_counter()
        res, dets = self.dp.analyser(self.model, frame)
        ms = (time.perf_counter() - t0) * 1000
        state, self.fire_streak = self.dp.decision(dets, self.fire_streak)
        status = {"ALARME_FEU": "fire", "FEU_A_CONFIRMER": "checking",
                  "ANOMALIE_FEUILLE": "leaf_anomaly", "RAS": "ok"}[state]
        cv2.imwrite(str(CAPTURES / "latest.jpg"), res.plot())
        return {"status": status, "inference_ms": round(ms), "model": self.model_name,
                "detections": [{"name": n, "conf": round(c, 2)} for n, c, _ in dets],
                "image": f"/captures/latest.jpg?t={time.time_ns()}",
                "time": time.strftime("%H:%M:%S")}

    def period(self) -> float:
        if not self.simulated:
            return CAMERA_PERIOD_S
        # sim: react quickly when the demo scene changes, otherwise look every 8 s
        changed = self.scene != self._last_scene
        self._last_scene = self.scene
        return 0.5 if changed or self.fire_streak == 1 else 8
