"""Surveillance caméra sur le Raspberry Pi : feu / fumée / feuilles anormales.

Prend une photo toutes les N secondes, lance YOLO, et :
  - fire / smoke  -> ALARME immédiate (même logique que couche_securite(flamme=True))
  - leaf_anomaly  -> signalement (photo annotée sauvegardée + log), pas d'action sur la pompe
Les photos avec détection sont enregistrées dans vision/captures/ avec un journal CSV.

Sur le Pi :
    pip install ultralytics ncnn picamera2      (picamera2 : souvent déjà installé sur Raspberry Pi OS)
    python vision/detect_pi.py --model vision/models/smartfarm_yolo11n_ncnn_model
Sur PC (test avec webcam ou une image) :
    python vision/detect_pi.py --source image.jpg
    python vision/detect_pi.py --source 0          # webcam
"""
import argparse
import csv
import time
from datetime import datetime
from pathlib import Path

import cv2
from ultralytics import YOLO

HERE = Path(__file__).parent
CAPTURES = HERE / "captures"

# Seuils de confiance par classe : le feu est volontairement plus sensible (rater un feu coûte plus cher
# qu'une fausse alerte) ; les feuilles demandent plus de certitude pour éviter les signalements inutiles.
SEUILS = {"fire": 0.35, "smoke": 0.40, "leaf_healthy": 0.50, "leaf_anomaly": 0.45}
CONFIRMATIONS_FEU = 2   # nb de photos consécutives avec feu/fumée avant l'alarme (anti faux positif)


def modele_par_defaut() -> Path:
    """NCNN (le plus rapide sur le Pi) s'il existe, sinon ONNX, sinon PyTorch."""
    for nom in ("smartfarm_yolo11n_ncnn_model", "smartfarm_yolo11n.onnx", "smartfarm_yolo11n.pt"):
        if (HERE / "models" / nom).exists():
            return HERE / "models" / nom
    return HERE / "models" / "smartfarm_yolo11n.pt"


def ouvrir_camera(source):
    """Renvoie une fonction qui retourne une image BGR (numpy) à chaque appel."""
    if source == "picamera":
        from picamera2 import Picamera2
        cam = Picamera2()
        cam.configure(cam.create_still_configuration(main={"size": (1280, 960), "format": "RGB888"}))
        cam.start()
        time.sleep(2)  # laisse l'exposition se stabiliser
        return lambda: cam.capture_array()  # RGB888 de picamera2 = ordre BGR en mémoire, OK pour OpenCV
    if Path(str(source)).is_file():
        img = cv2.imread(str(source))
        return lambda: img.copy()
    cap = cv2.VideoCapture(int(source))
    return lambda: cap.read()[1]


def analyser(model, frame):
    res = model.predict(frame, imgsz=640, conf=min(SEUILS.values()), verbose=False)[0]
    detections, garder = [], []
    for i, b in enumerate(res.boxes):
        nom = res.names[int(b.cls)]
        conf = float(b.conf)
        if conf >= SEUILS.get(nom, 0.5):
            detections.append((nom, conf, [round(v) for v in b.xyxy[0].tolist()]))
            garder.append(i)
    return res[garder], detections      # l'image annotée ne montre que les détections retenues


def decision(detections, feu_consecutif):
    noms = {d[0] for d in detections}
    if noms & {"fire", "smoke"}:
        feu_consecutif += 1
        if feu_consecutif >= CONFIRMATIONS_FEU:
            return "ALARME_FEU", feu_consecutif
        return "FEU_A_CONFIRMER", feu_consecutif
    if "leaf_anomaly" in noms:
        return "ANOMALIE_FEUILLE", 0
    return "RAS", 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", default=str(modele_par_defaut()))
    ap.add_argument("--source", default="picamera")
    ap.add_argument("--interval", type=float, default=30, help="secondes entre deux photos")
    ap.add_argument("--once", action="store_true", help="une seule analyse puis quitter")
    a = ap.parse_args()

    model = YOLO(a.model, task="detect")
    lire = ouvrir_camera(a.source)
    CAPTURES.mkdir(exist_ok=True)
    journal = CAPTURES / "journal.csv"
    nouveau = not journal.exists()
    feu_consecutif = 0

    with open(journal, "a", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        if nouveau:
            w.writerow(["horodatage", "etat", "detections", "image", "inference_ms"])
        while True:
            frame = lire()
            t0 = time.perf_counter()
            res, dets = analyser(model, frame)
            ms = (time.perf_counter() - t0) * 1000
            etat, feu_consecutif = decision(dets, feu_consecutif)

            stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            image = ""
            if dets:
                image = str(CAPTURES / f"{stamp}_{etat}.jpg")
                cv2.imwrite(image, res.plot())
            w.writerow([stamp, etat, ";".join(f"{n}:{c:.2f}" for n, c, _ in dets), image, f"{ms:.0f}"])
            f.flush()
            print(f"{stamp} | {etat:17s} | {len(dets)} détection(s) | {ms:.0f} ms")

            if etat == "ALARME_FEU":
                # TODO GPIO : buzzer ON, couper pompe et lampe (voir predict.couche_securite(flamme=True))
                print("  >>> ALARME : feu/fumée confirmé(e) — buzzer ON, pompe et lampe coupées")

            if a.once:
                break
            time.sleep(a.interval)


if __name__ == "__main__":
    main()
