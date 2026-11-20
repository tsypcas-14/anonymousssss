"""Fine-tune YOLO11n (pré-entraîné sur COCO) sur le dataset de la serre, puis exporte pour le Raspberry Pi.

Pourquoi YOLO11n ? C'est la plus petite variante (~2.6 M paramètres) : c'est la seule qui tourne
à une vitesse correcte sur le CPU d'un Raspberry Pi. On part des poids COCO (transfer learning)
au lieu de partir de zéro : le modèle sait déjà détecter des formes et des textures.

Usage :
    python vision/train_yolo.py                 # entraînement complet (60 epochs)
    python vision/train_yolo.py --epochs 3      # test rapide
Sorties :
    vision/runs/smartfarm_yolo11n/weights/best.pt   (meilleurs poids)
    vision/models/smartfarm_yolo11n.pt              (copie pour le projet)
    vision/models/smartfarm_yolo11n_ncnn_model/     (format rapide pour Raspberry Pi)
    vision/models/smartfarm_yolo11n.onnx            (format portable de secours)
"""
import argparse
import shutil
from pathlib import Path

from ultralytics import YOLO

HERE = Path(__file__).parent
DATA = HERE / "datasets" / "smartfarm" / "data.yaml"
RUNS = HERE / "runs"
MODELS = HERE / "models"
NAME = "smartfarm_yolo11n"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--epochs", type=int, default=60)
    ap.add_argument("--imgsz", type=int, default=640)
    ap.add_argument("--batch", type=int, default=16)
    ap.add_argument("--device", default="0")          # "0" = 1er GPU, "cpu" sinon
    ap.add_argument("--workers", type=int, default=4)
    ap.add_argument("--resume", action="store_true",
                    help="reprendre un entraînement interrompu depuis runs/.../weights/last.pt")
    a = ap.parse_args()

    if a.resume:
        model = YOLO(RUNS / NAME / "weights" / "last.pt")
        model.train(resume=True, workers=a.workers)
    else:
        model = YOLO("yolo11n.pt")                     # poids pré-entraînés COCO (téléchargés auto)
        model.train(
            data=str(DATA), epochs=a.epochs, imgsz=a.imgsz, batch=a.batch, device=a.device,
            workers=a.workers, project=str(RUNS), name=NAME, exist_ok=True,
            patience=15,          # arrêt anticipé si le mAP de validation ne progresse plus
            cos_lr=True, seed=0, plots=True,
        )

    best = Path(model.trainer.save_dir) / "weights" / "best.pt"
    print("Dossier d'entraînement :", model.trainer.save_dir)
    MODELS.mkdir(exist_ok=True)
    final_pt = MODELS / f"{NAME}.pt"
    shutil.copy2(best, final_pt)

    # Évaluation finale sur la validation, par classe
    metrics = YOLO(final_pt).val(data=str(DATA), imgsz=a.imgsz, device=a.device,
                                 project=str(RUNS), name=f"{NAME}_val", exist_ok=True)
    print(f"mAP50 = {metrics.box.map50:.3f} | mAP50-95 = {metrics.box.map:.3f}")
    for i, nom in YOLO(final_pt).names.items():
        print(f"  {nom:14s} mAP50 = {metrics.box.ap50[i]:.3f}")

    # Exports pour le Raspberry Pi
    for fmt in ("onnx", "ncnn"):
        try:
            out = Path(YOLO(final_pt).export(format=fmt, imgsz=a.imgsz))
            dst = MODELS / out.name
            if out.resolve() != dst.resolve():          # export already lands next to the .pt
                if dst.exists():
                    shutil.rmtree(dst) if dst.is_dir() else dst.unlink()
                shutil.move(str(out), dst)
            print(f"Export {fmt} : {dst}")
        except Exception as e:
            print(f"Export {fmt} impossible ici ({e}). Le faire sur le Pi : "
                  f"yolo export model={final_pt.name} format={fmt}")


if __name__ == "__main__":
    main()
