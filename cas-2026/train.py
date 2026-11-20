"""Entraîne la Random Forest d'irrigation (version locale du notebook Colab).

Reprend exactement le pipeline de notebooks/smartfarm_irrigation_rf.ipynb,
sans les graphiques ni le code spécifique à Colab.

Usage :  python train.py
Sortie : models/modele_irrigation_tomate.joblib
"""
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
import sklearn
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import (accuracy_score, classification_report, confusion_matrix,
                             f1_score, fbeta_score, precision_score, recall_score)
from sklearn.model_selection import GridSearchCV, GroupKFold, cross_val_predict

ROOT = Path(__file__).parent
DATA = ROOT / "data" / "smartfarm_tomato_dataset_v4.csv"
MODEL_OUT = ROOT / "models" / "modele_irrigation_tomate.joblib"

FEATURES = ["soil_moisture_pct", "air_temp_c", "air_humidity_pct", "light_lux", "light_mean_1h",
            "vpd_kpa", "hour_sin", "hour_cos", "soil_slope_1h", "days_after_transplant"]


def charger_et_preparer(path: Path) -> pd.DataFrame:
    df = pd.read_csv(path, parse_dates=["timestamp"])

    # Nettoyage : lectures de sol aberrantes -> NaN, puis ffill par cycle
    glitch = df["soil_raw_adc"].isin([0, 1023]) | ~df["soil_moisture_pct"].between(-20, 140)
    df.loc[glitch, ["soil_raw_adc", "soil_moisture_pct"]] = np.nan
    capteurs = ["air_temp_c", "air_humidity_pct", "soil_raw_adc", "soil_moisture_pct", "water_level_pct"]
    df[capteurs] = df.groupby("cycle")[capteurs].ffill()

    # Features physiques
    heure = df["timestamp"].dt.hour + df["timestamp"].dt.minute / 60
    df["hour_sin"] = np.sin(2 * np.pi * heure / 24)
    df["hour_cos"] = np.cos(2 * np.pi * heure / 24)
    es = 0.6108 * np.exp(17.27 * df["air_temp_c"] / (df["air_temp_c"] + 237.3))
    df["vpd_kpa"] = es * (1 - df["air_humidity_pct"] / 100)
    df["soil_slope_1h"] = df.groupby("cycle")["soil_moisture_pct"].diff(6)
    df["light_mean_1h"] = (df.groupby("cycle")["light_lux"]
                             .transform(lambda x: x.rolling(6, min_periods=1).mean()))
    return df.dropna(subset=["soil_slope_1h"]).reset_index(drop=True)


def evaluer(nom, y_vrai, y_pred):
    tn, fp, fn, tp = confusion_matrix(y_vrai, y_pred).ravel()
    return {"modèle": nom, "accuracy": accuracy_score(y_vrai, y_pred),
            "precision": precision_score(y_vrai, y_pred), "recall": recall_score(y_vrai, y_pred),
            "F1": f1_score(y_vrai, y_pred), "FN": fn, "FP": fp}


def main():
    df = charger_et_preparer(DATA)
    X, y = df[FEATURES], df["irrigation_needed"]
    print(f"Données : {X.shape}")

    # Split train/test par semaines (1 semaine sur 5 en test)
    semaine = df["timestamp"].dt.isocalendar().week.astype(int)
    est_test = (semaine % 5 == 0)
    X_train, X_test = X[~est_test], X[est_test]
    y_train, y_test = y[~est_test], y[est_test]
    print(f"Train : {len(X_train)} | Test : {len(X_test)}")

    # Baseline : seuil fixe sur l'humidité du sol
    seuils = np.arange(60, 100, 0.5)
    f1_train = [f1_score(y_train, (X_train["soil_moisture_pct"] < s).astype(int)) for s in seuils]
    s_best = seuils[int(np.argmax(f1_train))]
    y_pred_base = (X_test["soil_moisture_pct"] < s_best).astype(int)

    # Random Forest initiale
    rf = RandomForestClassifier(n_estimators=100, max_depth=12, min_samples_leaf=5,
                                n_jobs=-1, random_state=42)
    rf.fit(X_train, y_train)
    y_pred_rf = rf.predict(X_test)

    # GridSearch avec validation croisée par semaines
    groupes = semaine[~est_test].values
    recherche = GridSearchCV(
        RandomForestClassifier(n_estimators=100, random_state=42, n_jobs=-1),
        param_grid={"max_depth": [8, 12, 16], "min_samples_leaf": [5, 20],
                    "class_weight": [None, "balanced"]},
        scoring="f1", cv=GroupKFold(n_splits=3), verbose=1,
    )
    recherche.fit(X_train, y_train, groups=groupes)
    meilleur_rf = recherche.best_estimator_
    print("Meilleur réglage :", recherche.best_params_, f"| F1 CV = {recherche.best_score_:.3f}")

    # Seuil de décision : meilleur F2 en validation croisée
    proba_cv = cross_val_predict(meilleur_rf, X_train, y_train, groups=groupes,
                                 cv=GroupKFold(n_splits=3), method="predict_proba")[:, 1]
    seuils_dec = np.round(np.arange(0.10, 0.90, 0.05), 2)
    f2 = [fbeta_score(y_train, (proba_cv >= s).astype(int), beta=2) for s in seuils_dec]
    seuil = float(seuils_dec[int(np.argmax(f2))])
    print("Seuil de décision retenu :", seuil)

    # Évaluation finale sur le test
    y_pred_final = (meilleur_rf.predict_proba(X_test)[:, 1] >= seuil).astype(int)
    res = pd.DataFrame([evaluer(f"Baseline sol < {s_best} %", y_test, y_pred_base),
                        evaluer("RF initiale (seuil 0.5)", y_test, y_pred_rf),
                        evaluer(f"RF réglée (seuil {seuil})", y_test, y_pred_final)])
    print(res.round(3).to_string(index=False))
    print(classification_report(y_test, y_pred_final, digits=3,
                                target_names=["0 : pas besoin", "1 : besoin d'eau"]))

    MODEL_OUT.parent.mkdir(exist_ok=True)
    joblib.dump({"modele": meilleur_rf, "features": FEATURES, "seuil_decision": seuil,
                 "version_sklearn": sklearn.__version__}, MODEL_OUT, compress=3)
    print(f"Modèle sauvegardé : {MODEL_OUT} ({MODEL_OUT.stat().st_size / 1e6:.2f} Mo)")


if __name__ == "__main__":
    main()
