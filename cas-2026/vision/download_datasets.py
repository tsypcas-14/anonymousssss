"""Télécharge les datasets publics dans vision/raw/ (à lancer une seule fois).

  - D-Fire   (~3 Go, fire/smoke, YOLO)  -> vision/raw/dfire/{train,test}/{images,labels}
  - PlantDoc (~1 Go, git clone)         -> vision/raw/plantdoc/{TRAIN,TEST,*.csv}

Usage : python vision/download_datasets.py
Ensuite : python vision/prepare_dataset.py
"""
import subprocess
import time
import urllib.request
import zipfile
from pathlib import Path

RAW = Path(__file__).parent / "raw"
DFIRE_URL = ("https://my.microsoftpersonalcontent.com/personal/c0bd25b6b048b01d/_layouts/15/"
             "download.aspx?share=EbLgD7bES4FDvUN37Grxn8QBF5gIBBc7YV2qklF08GCiBw")
PLANTDOC_GIT = "https://github.com/pratikkayal/PlantDoc-Object-Detection-Dataset.git"


def telecharger_avec_reprise(url: str, dst: Path, essais: int = 50):
    """Téléchargement qui reprend là où il s'est arrêté (connexions instables)."""
    taille_totale = None
    for i in range(essais):
        deja = dst.stat().st_size if dst.exists() else 0
        if taille_totale and deja >= taille_totale:
            return
        req = urllib.request.Request(url, headers={"Range": f"bytes={deja}-"} if deja else {})
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                if taille_totale is None:
                    taille_totale = deja + int(r.headers.get("Content-Length", 0))
                mode = "ab" if r.status == 206 else "wb"
                with open(dst, mode) as f:
                    while chunk := r.read(1 << 20):
                        f.write(chunk)
                        print(f"\r  {dst.name}: {f.tell() / 1e9:.2f} / {taille_totale / 1e9:.2f} Go", end="")
            print()
            return
        except Exception as e:
            print(f"\n  coupure ({e}), reprise {i + 1}/{essais}...")
            time.sleep(3)
    raise RuntimeError(f"Échec du téléchargement de {url}")


def main():
    RAW.mkdir(exist_ok=True)

    if not (RAW / "dfire" / "train").exists():
        z = RAW / "D-Fire.zip"
        print("D-Fire...")
        telecharger_avec_reprise(DFIRE_URL, z)
        with zipfile.ZipFile(z) as f:
            f.extractall(RAW / "dfire")
        z.unlink()
    print("D-Fire OK")

    if not (RAW / "plantdoc" / "train_labels.csv").exists():
        print("PlantDoc...")
        # Quelques fichiers ont des noms invalides sous Windows : le checkout les saute, ce n'est pas grave
        subprocess.run(["git", "clone", "--depth", "1", PLANTDOC_GIT, str(RAW / "plantdoc")])
        subprocess.run(["git", "-C", str(RAW / "plantdoc"), "checkout", "-f", "HEAD"])
    print("PlantDoc OK")


if __name__ == "__main__":
    main()
