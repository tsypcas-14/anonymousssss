"""
Compare les composants rendus par Flutter aux maquettes du design v2 (PDF), à 3 px par dp.

  1) flutter test test/goldens          -> écrit build/golden_x3/*.png (captures 1080x2268)
  2) python tool/compare_design.py <SmartFarm-Interface-v2.pdf> [<SmartFarm-Interface.pdf>]
                                        -> écrit build/comparaison_design/cmp_*.png
Le second PDF (première version du design) sert aux parties reprises de cette version (ex. l'en-tête
« Arrosage » avec le sélecteur Auto / Manuel) ; sans lui, ces comparaisons sont ignorées.
Chaque image : maquette | composant Flutter | écart (blanc = différence).
Le PDF est lu à l'échelle 0,75 pt/dp (écran du design = 270 x 567 pt = 360 x 756 dp).
Nécessite : pip install pymupdf pillow numpy
"""
import sys
from pathlib import Path

import numpy as np
import pymupdf as fitz
from PIL import Image

S = 0.75          # points par dp
OY = {"v2": 204.8, "v1": 213.8}   # origine verticale des écrans dans chaque PDF (pt)
ROOT = Path(__file__).resolve().parent.parent
CAPTURES = ROOT / "build" / "golden_x3"
SORTIE = ROOT / "build" / "comparaison_design"

# nom, golden, source du PDF, page (0 = première), origine x de l'écran (pt), y de début et de fin (dp)
CAS = [
    # Écran complet ; on ignore les 34 premiers dp (barre d'état du téléphone dessinée dans la maquette)
    ("serre_accueil", "serre_accueil", "v2", 5, 90, 34, 756),
    ("serre_a_regarder", "serre_a_regarder", "v2", 5, 405, 34, 756),
    ("flamme", "flamme", "v2", 5, 720, 34, 756),
    ("capteur_sol", "capteur_sol", "v2", 8, 90, 34, 756),
    ("capteur_air", "capteur_air", "v2", 8, 405, 34, 756),
    ("capteur_muet", "capteur_muet", "v2", 8, 720, 34, 756),
    ("aeration_bas", "aeration", "v2", 9, 90, 548, 756),
    ("alertes", "alertes", "v2", 9, 720, 34, 756),
    ("reglages", "reglages", "v2", 10, 405, 34, 756),
    ("seuils", "seuils", "v2", 10, 720, 34, 756),
    ("aide", "aide", "v2", 11, 90, 34, 756),
    ("succes", "succes", "v2", 7, 90, 34, 756),
    ("erreur", "erreur", "v2", 7, 405, 34, 756),
    ("securite", "securite", "v2", 7, 720, 34, 756),
    ("chargement", "chargement", "v2", 12, 90, 34, 756),
    ("bienvenue", "bienvenue", "v2", 12, 405, 34, 756),
    ("connecter", "connecter", "v2", 12, 720, 34, 756),
    ("plantes_texte", "plantes", "v2", 11, 405, 300, 756),
    ("hors_ligne", "hors_ligne", "v2", 11, 720, 34, 756),
    # Arrosage : l'en-tête (titre, cloche, sélecteur) vient de la v1 ; le bas (bouton, lien, barre) de la v2
    ("carnet", "carnet", "v2", 10, 90, 34, 688),
    ("arrosage_entete", "arrosage", "v1", 4, 90, 34, 140),
    ("arrosage_bas", "arrosage", "v2", 6, 90, 548, 756),
    ("en_cours", "en_cours", "v2", 6, 720, 34, 756),
    ("cartes_pourquoi_vanne", "cartes_pourquoi_vanne", "v1", 4, 90, 140, 305),
    ("accueil_lignes", "accueil_lignes", "v2", 5, 90, 336, 756),
    ("lignes_a_regarder", "lignes_a_regarder", "v2", 5, 405, 336, 470),
    ("bouton_plein_lien", "bouton_plein_lien", "v2", 6, 90, 548, 756),
    ("bouton_contour", "bouton_contour", "v2", 6, 720, 600, 756),
    ("carte_confirmation", "carte_confirmation", "v2", 6, 405, 455, 756),
    ("barre_carnet", "barre_carnet", "v2", 10, 90, 688, 756),
]


def main(pdf_v2: str, pdf_v1: str | None) -> None:
    docs = {"v2": fitz.open(pdf_v2), "v1": fitz.open(pdf_v1) if pdf_v1 else None}
    SORTIE.mkdir(parents=True, exist_ok=True)
    print(f"{'composant':22} écart moyen   pixels très différents (>40/255)")
    for nom, golden, src, page, ox, y0, y1 in CAS:
        doc = docs[src]
        if doc is None:
            print(f"{nom:22} (ignoré : PDF {src} non fourni)")
            continue
        oy = OY[src]
        pm = doc[page].get_pixmap(matrix=fitz.Matrix(4, 4), clip=fitz.Rect(ox, oy + y0 * S, ox + 270, oy + y1 * S))
        ref = Image.frombytes("RGB", (pm.width, pm.height), pm.samples)
        mine = Image.open(CAPTURES / f"{golden}.png").convert("RGB").crop((0, int(y0 * 3), 1080, int(y1 * 3)))
        h = min(ref.height, mine.height)  # arrondis du PDF : on garde la hauteur commune
        ref, mine = ref.crop((0, 0, ref.width, h)), mine.crop((0, 0, mine.width, h))
        d = np.abs(np.asarray(ref).astype(int) - np.asarray(mine).astype(int)).max(axis=2)
        print(f"{nom:22} {d.mean():6.2f}/255    {(d > 40).mean() * 100:5.2f} %")
        diff = Image.fromarray(np.clip(d * 3, 0, 255).astype("uint8")).convert("RGB")
        w, hh = ref.size
        comp = Image.new("RGB", (w * 3 + 20, hh), (255, 255, 255))
        comp.paste(ref, (0, 0)); comp.paste(mine, (w + 10, 0)); comp.paste(diff, (2 * w + 20, 0))
        comp.save(SORTIE / f"cmp_{nom}.png")
    print(f"Images : {SORTIE}")


if __name__ == "__main__":
    if len(sys.argv) not in (2, 3):
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2] if len(sys.argv) == 3 else None)
