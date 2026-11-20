"""Generate the figures embedded in the README.

- Irrigation Random Forest: metrics vs baseline, confusion matrices, ROC / PR curves,
  threshold trade-off, boundary-zone F1, feature importance (computed from the committed model).
- EDA figures extracted from notebooks/smartfarm_irrigation_rf.ipynb.
- Vision: YOLO11n (ONNX) detections on app/server/demo_images/.
- Vision training curves: only if vision/runs/smartfarm_yolo11n/results.csv exists.

Usage : python docs/make_figures.py
Output: docs/figures/*.png
"""
import base64
import json
import sys
from pathlib import Path

import joblib
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402
from PIL import Image  # noqa: E402
from sklearn.base import clone  # noqa: E402
from sklearn.metrics import (auc, confusion_matrix, f1_score, fbeta_score,  # noqa: E402
                             precision_recall_curve, precision_score, recall_score, roc_curve,
                             accuracy_score)
from sklearn.model_selection import GroupKFold, cross_val_predict  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
import train  # noqa: E402

OUT = ROOT / "docs" / "figures"
OUT.mkdir(parents=True, exist_ok=True)

# Palette (validated reference palette, light mode)
SURFACE, INK, INK2, MUTED, GRID = "#fcfcfb", "#0b0b0b", "#52514e", "#8a8984", "#e6e5e0"
BLUE, ORANGE, AQUA = "#2a78d6", "#eb6834", "#1baf7a"
BASE_GRAY, BLUE_LIGHT = "#b7b6b0", "#8fb8ea"

plt.rcParams.update({
    "figure.facecolor": SURFACE, "axes.facecolor": SURFACE, "savefig.facecolor": SURFACE,
    "axes.edgecolor": GRID, "axes.labelcolor": INK2, "axes.titlecolor": INK,
    "axes.titlesize": 12, "axes.titleweight": "bold", "axes.titlelocation": "left",
    "xtick.color": INK2, "ytick.color": INK2, "text.color": INK, "font.size": 10,
    "axes.grid": True, "grid.color": GRID, "grid.linewidth": 0.8,
    "axes.spines.top": False, "axes.spines.right": False, "legend.frameon": False,
})


def save(fig, name):
    fig.savefig(OUT / name, dpi=150, bbox_inches="tight")
    plt.close(fig)
    print("wrote", OUT / name)


# --------------------------------------------------------------------------- Random Forest
def rf_figures():
    df = train.charger_et_preparer(train.DATA)
    pack = joblib.load(ROOT / "models" / "modele_irrigation_tomate.joblib")
    model, feats, thr = pack["modele"], pack["features"], pack["seuil_decision"]
    X, y = df[feats], df["irrigation_needed"]
    week = df["timestamp"].dt.isocalendar().week.astype(int)
    test = (week % 5 == 0).values
    Xtr, Xte, ytr, yte = X[~test], X[test], y[~test], y[test]

    # Baseline: best fixed soil threshold on train
    s_grid = np.arange(60, 100, 0.5)
    s_best = s_grid[int(np.argmax([f1_score(ytr, (Xtr["soil_moisture_pct"] < s).astype(int))
                                   for s in s_grid]))]
    pred_base = (Xte["soil_moisture_pct"] < s_best).astype(int)
    proba = model.predict_proba(Xte)[:, 1]
    pred_05 = (proba >= 0.5).astype(int)
    pred_rf = (proba >= thr).astype(int)

    models = [(f"Baseline\nsoil < {s_best:g} %", pred_base, BASE_GRAY),
              ("Random Forest\nthreshold 0.5", pred_05, BLUE_LIGHT),
              (f"Random Forest\ntuned (threshold {thr:g})", pred_rf, BLUE)]

    # 1. Metric comparison + error counts
    metrics = [("Accuracy", accuracy_score), ("Precision", precision_score),
               ("Recall", recall_score), ("F1", f1_score)]
    fig, (a1, a2) = plt.subplots(1, 2, figsize=(13, 4.6), gridspec_kw={"width_ratios": [1.6, 1]})
    w = 0.26
    xs = np.arange(len(metrics))
    for i, (name, pred, col) in enumerate(models):
        vals = [f(yte, pred) for _, f in metrics]
        bars = a1.bar(xs + (i - 1) * w, vals, w - 0.03, color=col, label=name.replace("\n", " "))
        for b, v in zip(bars, vals):
            a1.text(b.get_x() + b.get_width() / 2, v + 0.004, f"{v:.3f}", ha="center",
                    va="bottom", fontsize=8, color=INK2)
    a1.set_xticks(xs, [m for m, _ in metrics])
    a1.set_ylim(0.8, 1.01)
    a1.set_title("Test-set metrics (held-out weeks)")
    a1.legend(loc="lower left", fontsize=8.5)
    a1.grid(axis="x", visible=False)

    labels = [n for n, _, _ in models]
    fn = [confusion_matrix(yte, p).ravel()[2] for _, p, _ in models]
    fp = [confusion_matrix(yte, p).ravel()[1] for _, p, _ in models]
    xi = np.arange(len(models))
    b1 = a2.bar(xi - 0.19, fn, 0.36, color=ORANGE, label="Missed waterings (FN)")
    b2 = a2.bar(xi + 0.19, fp, 0.36, color=MUTED, label="Unneeded waterings (FP)")
    for bars in (b1, b2):
        for b in bars:
            a2.text(b.get_x() + b.get_width() / 2, b.get_height() + 6, int(b.get_height()),
                    ha="center", va="bottom", fontsize=8.5, color=INK2)
    a2.set_xticks(xi, labels, fontsize=8.5)
    a2.set_title("Errors on 7,044 test samples")
    a2.legend(fontsize=8.5)
    a2.grid(axis="x", visible=False)
    save(fig, "rf_metrics.png")

    # 2. Confusion matrices
    fig, axes = plt.subplots(1, 2, figsize=(10, 4.2))
    for ax, (name, pred, _) in zip(axes, [models[0], models[2]]):
        cm = confusion_matrix(yte, pred)
        pct = cm / cm.sum(axis=1, keepdims=True)
        ax.imshow(pct, cmap=matplotlib.colors.LinearSegmentedColormap.from_list(
            "b", ["#eef4fc", BLUE]), vmin=0, vmax=1)
        for (r, c), v in np.ndenumerate(cm):
            ax.text(c, r, f"{v:,}\n{pct[r, c]:.1%}", ha="center", va="center", fontsize=11,
                    color="white" if pct[r, c] > 0.55 else INK)
        ax.set_xticks([0, 1], ["No water", "Water"])
        ax.set_yticks([0, 1], ["No need", "Needs water"])
        ax.set_xlabel("Predicted")
        ax.set_ylabel("Actual")
        ax.set_title(name.replace("\n", " "))
        ax.grid(False)
    save(fig, "rf_confusion_matrices.png")

    # 3. ROC and Precision-Recall
    fig, (a1, a2) = plt.subplots(1, 2, figsize=(11, 4.4))
    fpr, tpr, _ = roc_curve(yte, proba)
    a1.plot(fpr, tpr, color=BLUE, lw=2, label=f"Random Forest (AUC = {auc(fpr, tpr):.3f})")
    tn, fpb, fnb, tpb = confusion_matrix(yte, pred_base).ravel()
    a1.scatter([fpb / (fpb + tn)], [tpb / (tpb + fnb)], s=60, color=ORANGE, zorder=3,
               edgecolor=SURFACE, linewidth=2, label="Baseline rule")
    tn, fpr_, fnr_, tpr_ = confusion_matrix(yte, pred_rf).ravel()
    a1.scatter([fpr_ / (fpr_ + tn)], [tpr_ / (tpr_ + fnr_)], s=60, color=BLUE, zorder=3,
               edgecolor=SURFACE, linewidth=2, label=f"Operating point (threshold {thr:g})")
    a1.plot([0, 1], [0, 1], color=MUTED, lw=1, ls="--")
    a1.set_xlabel("False positive rate")
    a1.set_ylabel("True positive rate (recall)")
    a1.set_title("ROC curve")
    a1.legend(loc="lower right", fontsize=8.5)

    prec, rec, _ = precision_recall_curve(yte, proba)
    a2.plot(rec, prec, color=BLUE, lw=2, label=f"Random Forest (AUC = {auc(rec, prec):.3f})")
    a2.scatter([recall_score(yte, pred_base)], [precision_score(yte, pred_base)], s=60,
               color=ORANGE, zorder=3, edgecolor=SURFACE, linewidth=2, label="Baseline rule")
    a2.scatter([recall_score(yte, pred_rf)], [precision_score(yte, pred_rf)], s=60, color=BLUE,
               zorder=3, edgecolor=SURFACE, linewidth=2, label=f"Operating point (threshold {thr:g})")
    a2.set_xlabel("Recall")
    a2.set_ylabel("Precision")
    a2.set_ylim(0.5, 1.01)
    a2.set_title("Precision-Recall curve")
    a2.legend(loc="lower left", fontsize=8.5)
    save(fig, "rf_roc_pr.png")

    # 4. Threshold selection on cross-validated train probabilities (no test leakage)
    groups = week[~test].values
    p_cv = cross_val_predict(clone(model), Xtr, ytr, groups=groups, cv=GroupKFold(n_splits=3),
                             method="predict_proba")[:, 1]
    ts = np.round(np.arange(0.10, 0.90, 0.05), 2)
    rows = [(recall_score(ytr, p_cv >= t), precision_score(ytr, p_cv >= t),
             fbeta_score(ytr, p_cv >= t, beta=2)) for t in ts]
    r, p, f2 = map(np.array, zip(*rows))
    fig, ax = plt.subplots(figsize=(8.5, 4.2))
    ax.plot(ts, r, color=BLUE, lw=2, label="Recall")
    ax.plot(ts, p, color=ORANGE, lw=2, label="Precision")
    ax.plot(ts, f2, color=AQUA, lw=2, label="F2 score (selection criterion)")
    ax.axvline(thr, color=MUTED, lw=1, ls="--")
    ax.annotate(f"Selected threshold = {thr:g}", (thr, f2[np.argmin(abs(ts - thr))]),
                xytext=(thr + 0.06, 0.86), fontsize=9, color=INK2,
                arrowprops=dict(arrowstyle="-", color=MUTED))
    ax.set_xlabel("Decision threshold (share of trees voting 'water')")
    ax.set_ylabel("Score (cross-validation, train weeks)")
    ax.set_title("Decision threshold selection")
    ax.legend(fontsize=9)
    save(fig, "rf_threshold.png")

    # 5. F1 by soil-moisture band
    bands = [(0, 65), (65, 75), (75, 85), (85, 95), (95, 200)]
    names = ["< 65 %", "65-75 %", "75-85 %", "85-95 %", "> 95 %"]
    soil = Xte["soil_moisture_pct"].values
    fb, fr, nn = [], [], []
    for lo, hi in bands:
        m = (soil >= lo) & (soil < hi)
        has_pos = yte[m].sum() > 0
        fb.append(f1_score(yte[m], pred_base[m]) if has_pos else np.nan)
        fr.append(f1_score(yte[m], pred_rf[m]) if has_pos else np.nan)
        nn.append(int(m.sum()))
    fig, ax = plt.subplots(figsize=(9, 4.2))
    xi = np.arange(len(bands))
    for off, vals, col, lab in [(-0.19, fb, BASE_GRAY, "Baseline rule"),
                                (0.19, fr, BLUE, "Random Forest (tuned)")]:
        bars = ax.bar(xi + off, np.nan_to_num(vals), 0.36, color=col, label=lab)
        for b, v in zip(bars, vals):
            if not np.isnan(v):
                ax.text(b.get_x() + b.get_width() / 2, v + 0.01, f"{v:.2f}", ha="center",
                        fontsize=8.5, color=INK2)
    for i, v in enumerate(fr):
        if np.isnan(v):
            ax.text(i, 0.05, "n/a: no plant\nneeds water here", ha="center", fontsize=8.5, color=MUTED)
    ax.set_xticks(xi, [f"{n}\n(n = {k:,})" for n, k in zip(names, nn)])
    ax.set_xlabel("Soil moisture")
    ax.set_ylabel("F1 score (class 'needs water')")
    ax.set_ylim(0, 1.1)
    ax.set_title("Where the model beats the fixed rule: the ambiguous moisture band")
    ax.legend(fontsize=9, loc="upper right")
    ax.grid(axis="x", visible=False)
    save(fig, "rf_boundary_zone.png")
    z = (soil >= 65) & (soil < 95)
    print(f"F1 in 65-95 % band: baseline {f1_score(yte[z], pred_base[z]):.3f} | RF {f1_score(yte[z], pred_rf[z]):.3f}")

    # 6. Feature importance
    imp = sorted(zip(model.feature_importances_, feats))
    fig, ax = plt.subplots(figsize=(8, 4.2))
    vals, labs = zip(*imp)
    ax.barh(labs, vals, color=BLUE, height=0.6)
    for i, v in enumerate(vals):
        ax.text(v + 0.006, i, f"{v:.3f}", va="center", fontsize=8.5, color=INK2)
    ax.set_xlabel("Mean decrease in impurity")
    ax.set_title("Feature importance")
    ax.grid(axis="y", visible=False)
    save(fig, "rf_feature_importance.png")


# --------------------------------------------------------------------------- Notebook EDA
def notebook_figures():
    nb = json.loads((ROOT / "notebooks" / "smartfarm_irrigation_rf.ipynb").read_text(encoding="utf-8"))
    wanted = {"2025-09-22": "eda_week.png", "histplot": "eda_soil_distribution.png",
              "cols = [": "eda_correlation.png"}
    for c in nb["cells"]:
        src = "".join(c.get("source", ""))
        for key, name in wanted.items():
            if key in src:
                for o in c.get("outputs", []):
                    png = o.get("data", {}).get("image/png")
                    if png:
                        (OUT / name).write_bytes(base64.b64decode(png))
                        print("wrote", OUT / name)
                        break


# --------------------------------------------------------------------------- Vision
CLASSES = ["fire", "smoke", "leaf_healthy", "leaf_anomaly"]
THRESH = {"fire": 0.35, "smoke": 0.40, "leaf_healthy": 0.50, "leaf_anomaly": 0.45}  # = detect_pi.py
BOX_COL = {"fire": ORANGE, "smoke": "#6250d6", "leaf_healthy": AQUA, "leaf_anomaly": "#e34948"}


def nms(boxes, scores, iou=0.5):
    order, keep = scores.argsort()[::-1], []
    while order.size:
        i = order[0]
        keep.append(i)
        xx1 = np.maximum(boxes[i, 0], boxes[order[1:], 0])
        yy1 = np.maximum(boxes[i, 1], boxes[order[1:], 1])
        xx2 = np.minimum(boxes[i, 2], boxes[order[1:], 2])
        yy2 = np.minimum(boxes[i, 3], boxes[order[1:], 3])
        inter = np.clip(xx2 - xx1, 0, None) * np.clip(yy2 - yy1, 0, None)
        area = lambda b: (b[..., 2] - b[..., 0]) * (b[..., 3] - b[..., 1])  # noqa: E731
        order = order[1:][inter / (area(boxes[i]) + area(boxes[order[1:]]) - inter) < iou]
    return keep


def detect(sess, img):
    w0, h0 = img.size
    r = 640 / max(w0, h0)
    nw, nh = round(w0 * r), round(h0 * r)
    canvas = Image.new("RGB", (640, 640), (114, 114, 114))
    px, py = (640 - nw) // 2, (640 - nh) // 2
    canvas.paste(img.resize((nw, nh)), (px, py))
    x = np.asarray(canvas, dtype=np.float32).transpose(2, 0, 1)[None] / 255.0
    out = sess.run(None, {"images": x})[0][0].T            # (8400, 4 + nc)
    cls, conf = out[:, 4:].argmax(1), out[:, 4:].max(1)
    m = conf >= min(THRESH.values())
    out, cls, conf = out[m], cls[m], conf[m]
    xy = out[:, :4]
    boxes = np.stack([xy[:, 0] - xy[:, 2] / 2, xy[:, 1] - xy[:, 3] / 2,
                      xy[:, 0] + xy[:, 2] / 2, xy[:, 1] + xy[:, 3] / 2], 1)
    boxes = (boxes - [px, py, px, py]) / r
    dets = []
    for c in np.unique(cls):
        idx = np.where(cls == c)[0]
        for k in nms(boxes[idx], conf[idx]):
            j = idx[k]
            if conf[j] >= THRESH[CLASSES[c]]:
                dets.append((CLASSES[c], float(conf[j]), boxes[j]))
    return dets


def vision_figures():
    import onnxruntime as ort
    sess = ort.InferenceSession(str(ROOT / "vision" / "models" / "smartfarm_yolo11n.onnx"))
    scenes = ["fire", "leaf_anomaly", "normal"]
    fig, axes = plt.subplots(3, 4, figsize=(14, 9.5))
    for row, scene in enumerate(scenes):
        files = sorted((ROOT / "app" / "server" / "demo_images" / scene).glob("*.jpg"))[:4]
        for col, f in enumerate(files):
            ax = axes[row, col]
            img = Image.open(f).convert("RGB")
            dets = detect(sess, img)
            ax.imshow(img)
            for name, conf, (x1, y1, x2, y2) in dets:
                ax.add_patch(plt.Rectangle((x1, y1), x2 - x1, y2 - y1, fill=False,
                                           color=BOX_COL[name], lw=2.2))
                ax.text(x1, y1, f" {name} {conf:.2f} ", fontsize=7.5, color="white",
                        va="bottom", bbox=dict(facecolor=BOX_COL[name], edgecolor="none", pad=1))
            ax.set_xticks([])
            ax.set_yticks([])
            ax.grid(False)
            for s in ax.spines.values():
                s.set_visible(False)
            if col == 0:
                ax.set_ylabel(scene.replace("_", " "), fontsize=11, color=INK)
    fig.suptitle("YOLO11n detections (ONNX export, per-class thresholds of detect_pi.py)",
                 x=0.01, ha="left", fontsize=13, fontweight="bold")
    fig.tight_layout()
    save(fig, "vision_detections.png")

    results = ROOT / "vision" / "runs" / "smartfarm_yolo11n" / "results.csv"
    if results.exists():
        import pandas as pd
        d = pd.read_csv(results)
        d.columns = d.columns.str.strip()
        fig, (a1, a2) = plt.subplots(1, 2, figsize=(13, 4.6))
        a1.plot(d["epoch"], d["metrics/mAP50(B)"], color=BLUE, lw=2, label="mAP@50")
        a1.plot(d["epoch"], d["metrics/mAP50-95(B)"], color=ORANGE, lw=2, label="mAP@50-95")
        a1.set_title("Validation mAP during fine-tuning")
        a1.set_xlabel("Epoch")
        a1.legend()
        a2.plot(d["epoch"], d["train/box_loss"], color=BLUE, lw=2, label="Train")
        a2.plot(d["epoch"], d["val/box_loss"], color=ORANGE, lw=2, label="Validation")
        a2.set_title("Box loss")
        a2.set_xlabel("Epoch")
        a2.legend()
        save(fig, "vision_training.png")
    else:
        print("no YOLO results.csv found: vision_training.png skipped")


if __name__ == "__main__":
    rf_figures()
    notebook_figures()
    vision_figures()
