"""Trace la progression de l'entraînement YOLO (marche aussi pendant l'entraînement).

Usage : python vision/plot_training.py
Sortie : vision/runs/training_progress.png
"""
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

RUN = Path(__file__).parent / "runs" / "smartfarm_yolo11n"
OUT = Path(__file__).parent / "runs" / "training_progress.png"
BLUE, ORANGE = "#2a78d6", "#eb6834"
INK, INK2, GRID, SURFACE = "#0b0b0b", "#52514e", "#e6e5e0", "#fcfcfb"

df = pd.read_csv(RUN / "results.csv")
df.columns = df.columns.str.strip()

fig, axes = plt.subplots(1, 2, figsize=(13, 4.8), facecolor=SURFACE)
panneaux = [
    ("Précision de détection (validation) — plus haut = mieux",
     [("metrics/mAP50(B)", "mAP50", BLUE), ("metrics/mAP50-95(B)", "mAP50-95", ORANGE)], "score (0 à 1)"),
    ("Erreur de position des boîtes — plus bas = mieux",
     [("train/box_loss", "entraînement", BLUE), ("val/box_loss", "validation", ORANGE)], "box loss"),
]
for ax, (titre, series, ylabel) in zip(axes, panneaux):
    ax.set_facecolor(SURFACE)
    for col, nom, couleur in series:
        ax.plot(df["epoch"], df[col], color=couleur, lw=2, label=nom)
        x, y = df["epoch"].iloc[-1], df[col].iloc[-1]
        ax.plot(x, y, "o", ms=8, color=couleur, mec=SURFACE, mew=2)
        ax.annotate(f"{nom} {y:.3f}", (x, y), xytext=(8, 0), textcoords="offset points",
                    va="center", fontsize=9, color=INK)
    ax.set_title(titre, loc="left", fontsize=11, color=INK)
    ax.set_xlabel("epoch", color=INK2); ax.set_ylabel(ylabel, color=INK2)
    ax.grid(color=GRID, lw=0.8); ax.set_axisbelow(True)
    for s in ("top", "right"):
        ax.spines[s].set_visible(False)
    for s in ("left", "bottom"):
        ax.spines[s].set_color(GRID)
    ax.tick_params(colors=INK2)
    ax.legend(frameon=False, loc="best", labelcolor=INK)
    ax.set_xlim(1, max(60, df["epoch"].max()) + 8)

fig.suptitle(f"YOLO11n serre — epoch {int(df['epoch'].iloc[-1])}/60",
             x=0.01, ha="left", fontsize=13, color=INK)
fig.tight_layout()
fig.savefig(OUT, dpi=130, facecolor=SURFACE)
print(f"Graphique : {OUT}")
