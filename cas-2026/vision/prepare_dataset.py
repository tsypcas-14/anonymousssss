"""Construit le dataset YOLO unique de la serre à partir de deux datasets publics.

Sources (téléchargées dans vision/raw/) :
  - D-Fire   (fire + smoke, format YOLO)        https://github.com/gaiasd/DFireDataset
  - PlantDoc (maladies des feuilles, CSV boîtes) https://github.com/pratikkayal/PlantDoc-Object-Detection-Dataset
    -> on garde uniquement les feuilles de TOMATE.

Classes finales :
  0 fire          (D-Fire classe 1)
  1 smoke         (D-Fire classe 0)
  2 leaf_healthy  (PlantDoc "Tomato leaf")
  3 leaf_anomaly  (PlantDoc : toutes les maladies de la tomate fusionnées)

Pourquoi fusionner les maladies ? PlantDoc ne contient que ~200 boîtes par maladie de tomate :
trop peu pour apprendre 8 classes séparées de façon fiable. Une classe "anomalie" est plus robuste,
et le Raspberry Pi n'a besoin que de savoir "cette feuille ne va pas bien".

Équilibrage : D-Fire a ~17 000 images d'entraînement contre ~500 pour les tomates.
On sous-échantillonne D-Fire et on répète les images de tomates (sur-échantillonnage) dans la liste train.

Usage : python vision/prepare_dataset.py [--dfire-train 8000] [--dfire-val 1500] [--leaf-repeat 4]
"""
import argparse
import csv
import random
import shutil
from collections import defaultdict
from pathlib import Path

HERE = Path(__file__).parent
RAW = HERE / "raw"
OUT = HERE / "datasets" / "smartfarm"

CLASSES = ["fire", "smoke", "leaf_healthy", "leaf_anomaly"]
DFIRE_MAP = {1: 0, 0: 1}   # D-Fire : 0 = smoke, 1 = fire
HEALTHY = "Tomato leaf"


def reset_out():
    if OUT.exists():
        shutil.rmtree(OUT)
    for split in ("train", "val"):
        (OUT / "images" / split).mkdir(parents=True)
        (OUT / "labels" / split).mkdir(parents=True)


def copier(img_src: Path, lignes: list[str], split: str, nom: str) -> Path:
    dst = OUT / "images" / split / f"{nom}{img_src.suffix.lower()}"
    shutil.copy2(img_src, dst)
    (OUT / "labels" / split / f"{nom}.txt").write_text("\n".join(lignes) + ("\n" if lignes else ""))
    return dst


def dfire(split_src: str, split_dst: str, n: int, rng: random.Random) -> list[Path]:
    img_dir = RAW / "dfire" / split_src / "images"
    lbl_dir = RAW / "dfire" / split_src / "labels"
    images = sorted(img_dir.iterdir())
    rng.shuffle(images)
    images = images[:n]
    out = []
    for img in images:
        lbl = lbl_dir / f"{img.stem}.txt"
        lignes = []
        if lbl.exists():
            for l in lbl.read_text().split("\n"):
                p = l.split()
                if len(p) == 5:
                    lignes.append(" ".join([str(DFIRE_MAP[int(p[0])])] + p[1:]))
        out.append(copier(img, lignes, split_dst, f"df_{img.stem}"))
    return out


def plantdoc(csv_name: str, img_folder: str, split_dst: str) -> list[Path]:
    boites = defaultdict(list)
    with open(RAW / "plantdoc" / csv_name, newline="", encoding="utf-8") as f:
        for r in csv.DictReader(f):
            if not r["class"].startswith("Tomato"):
                continue
            boites[r["filename"]].append(r)

    out, manquants = [], 0
    for i, (fname, rows) in enumerate(sorted(boites.items())):
        img = RAW / "plantdoc" / img_folder / fname
        if not img.exists():
            manquants += 1
            continue
        lignes = []
        for r in rows:
            w, h = float(r["width"]), float(r["height"])
            x1, y1 = max(0.0, float(r["xmin"])), max(0.0, float(r["ymin"]))
            x2, y2 = min(w, float(r["xmax"])), min(h, float(r["ymax"]))
            if x2 <= x1 or y2 <= y1:
                continue
            cls = 2 if r["class"] == HEALTHY else 3
            lignes.append(f"{cls} {(x1 + x2) / 2 / w:.6f} {(y1 + y2) / 2 / h:.6f} "
                          f"{(x2 - x1) / w:.6f} {(y2 - y1) / h:.6f}")
        if lignes:
            out.append(copier(img, lignes, split_dst, f"pd_{split_dst}_{i:04d}"))
    print(f"  PlantDoc {img_folder}: {len(out)} images de tomate ({manquants} introuvables)")
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dfire-train", type=int, default=8000)
    ap.add_argument("--dfire-val", type=int, default=1500)
    ap.add_argument("--leaf-repeat", type=int, default=4)
    ap.add_argument("--seed", type=int, default=0)
    a = ap.parse_args()
    rng = random.Random(a.seed)

    reset_out()
    print("Copie D-Fire...")
    df_train = dfire("train", "train", a.dfire_train, rng)
    df_val = dfire("test", "val", a.dfire_val, rng)
    print("Copie PlantDoc (tomate)...")
    pd_train = plantdoc("train_labels.csv", "TRAIN", "train")
    pd_val = plantdoc("test_labels.csv", "TEST", "val")

    # Listes d'images : les tomates sont répétées dans train pour compenser le déséquilibre
    train_list = df_train + pd_train * a.leaf_repeat
    rng.shuffle(train_list)
    (OUT / "train.txt").write_text("\n".join(str(p.resolve()) for p in train_list) + "\n")
    (OUT / "val.txt").write_text("\n".join(str(p.resolve()) for p in df_val + pd_val) + "\n")

    yaml = (f"path: {OUT.resolve().as_posix()}\n"
            "train: train.txt\nval: val.txt\n"
            f"nc: {len(CLASSES)}\nnames: {CLASSES}\n")
    (OUT / "data.yaml").write_text(yaml)

    # Statistiques
    for split in ("train", "val"):
        compte = [0] * len(CLASSES)
        for f in (OUT / "labels" / split).glob("*.txt"):
            for l in f.read_text().split("\n"):
                if l.strip():
                    compte[int(l.split()[0])] += 1
        n_img = len(list((OUT / "images" / split).iterdir()))
        print(f"{split}: {n_img} images | boîtes : " + ", ".join(f"{c}={n}" for c, n in zip(CLASSES, compte)))
    print(f"Liste train (avec répétition des tomates x{a.leaf_repeat}) : {len(train_list)} entrées")
    print(f"Dataset prêt : {OUT / 'data.yaml'}")


if __name__ == "__main__":
    main()
