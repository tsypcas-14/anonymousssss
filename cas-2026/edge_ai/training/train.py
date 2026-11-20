"""Entrainement des 3 Decision Trees + export en Python pur (edge_models.py), tout en memoire."""
import importlib.util
import json
import os
import pandas as pd
from sklearn.metrics import classification_report, confusion_matrix
from sklearn.model_selection import cross_val_score, train_test_split
from sklearn.tree import DecisionTreeClassifier, export_text
from config import FEATURES_ANOMALY, FEATURES_CLIMATE, FEATURES_IRRIGATION

# nom de l'arbre, fonction exportee, features, cible, cle de profondeur, jeu de donnees
SPECS = [
    ("tree_irrigation", "predict_irrigation", FEATURES_IRRIGATION, "irrigation", "depth_irrigation", "dec"),
    ("tree_climate", "predict_climate", FEATURES_CLIMATE, "climate", "depth_climate", "dec"),
    ("tree_anomaly", "predict_anomaly", FEATURES_ANOMALY, "anomaly", "depth_anomaly", "anom"),
]


def train_all(dec, anom, profile, build_dir, verbose=True):
    """Entraine les 3 arbres. Ecrit build/<arbre>_rules.txt et build/metrics.json. Retourne ({nom: clf}, metrics)."""
    TR = profile["training"]
    os.makedirs(build_dir, exist_ok=True)
    data = {"dec": dec, "anom": anom}
    trees, metrics = {}, {}
    for name, _, feats, target, depth_key, ds in SPECS:
        X, y = data[ds][feats], data[ds][target]
        Xtr, Xte, ytr, yte = train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)
        clf = DecisionTreeClassifier(max_depth=TR[depth_key], min_samples_leaf=TR["min_leaf"],
                                     random_state=42, class_weight="balanced")
        cv = cross_val_score(clf, Xtr, ytr, cv=5)
        clf.fit(Xtr, ytr)
        pred = clf.predict(Xte)
        rep = classification_report(yte, pred, output_dict=True)
        labels = list(clf.classes_)
        cm = confusion_matrix(yte, pred, labels=labels)
        if verbose:
            print(f"\n{name} (profondeur {clf.get_depth()}, {clf.get_n_leaves()} feuilles)  "
                  f"CV {cv.mean():.3f}+-{cv.std():.3f}  test {rep['accuracy']:.3f}")
            print(classification_report(yte, pred))
        with open(os.path.join(build_dir, f"{name}_rules.txt"), "w", encoding="utf-8") as f:
            f.write(export_text(clf, feature_names=feats))
        trees[name] = clf
        metrics[name] = {"cv_mean": round(cv.mean(), 4), "cv_std": round(cv.std(), 4),
                         "test_accuracy": round(rep["accuracy"], 4), "depth": int(clf.get_depth()),
                         "leaves": int(clf.get_n_leaves()), "labels": labels, "confusion_matrix": cm.tolist(),
                         "feature_importance": dict(zip(feats, clf.feature_importances_.round(3).tolist()))}
    with open(os.path.join(build_dir, "metrics.json"), "w", encoding="utf-8") as f:
        json.dump(metrics, f, indent=2)
    return trees, metrics


def _gen(tree, feats, classes, node=0, ind=1):
    pad = "    " * ind
    if tree.children_left[node] == -1:
        return f"{pad}return {classes[tree.value[node][0].argmax()]!r}\n"
    f, t = feats[tree.feature[node]], tree.threshold[node]
    return (f"{pad}if {f} <= {t:.4f}:\n" + _gen(tree, feats, classes, tree.children_left[node], ind + 1)
            + f"{pad}else:\n" + _gen(tree, feats, classes, tree.children_right[node], ind + 1))


def export_python(trees, path):
    """Ecrit edge_models.py : if/else purs, zero dependance (ni sklearn ni numpy sur le Pi)."""
    out = ['"""Genere par retrain.py - NE PAS EDITER A LA MAIN. Aucune dependance."""\n']
    for name, fn, feats, *_ in SPECS:
        clf = trees[name]
        out.append(f"\ndef {fn}({', '.join(feats)}):\n" + _gen(clf.tree_, feats, list(clf.classes_)))
    with open(path, "w", encoding="utf-8") as f:
        f.write("".join(out))


def verify_export(trees, dec, anom, path):
    """Charge le fichier exporte et verifie qu'il predit EXACTEMENT comme sklearn (AssertionError sinon)."""
    spec = importlib.util.spec_from_file_location("edge_models_check", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    data, report = {"dec": dec, "anom": anom}, {}
    for name, fn, feats, _, _, ds in SPECS:
        df = data[ds]
        sk = trees[name].predict(df[feats])
        ex = pd.Series([getattr(mod, fn)(**row) for row in df[feats].to_dict("records")])
        report[fn] = float((sk == ex).mean())
        assert report[fn] == 1.0, f"export incorrect pour {fn}"
    return report
