"""Charge le modèle entraîné et recommande (ou non) une irrigation.

Usage dans le code :
    from predict import charger_modele, recommander_irrigation, couche_securite
    paquet = charger_modele()
    proba, besoin = recommander_irrigation(paquet, mesures)

Usage en ligne de commande (démo) :  python predict.py
"""
from pathlib import Path

import joblib
import numpy as np
import pandas as pd

MODEL_PATH = Path(__file__).parent / "models" / "modele_irrigation_tomate.joblib"


def charger_modele(path: Path = MODEL_PATH) -> dict:
    return joblib.load(path)


def recommander_irrigation(paquet: dict, m: dict) -> tuple[float, int]:
    """m : mesures actuelles + un peu d'historique (voir la démo ci-dessous)."""
    es = 0.6108 * np.exp(17.27 * m["air_temp_c"] / (m["air_temp_c"] + 237.3))
    ligne = {
        "soil_moisture_pct": m["soil_moisture_pct"],
        "air_temp_c": m["air_temp_c"],
        "air_humidity_pct": m["air_humidity_pct"],
        "light_lux": m["light_lux"],
        "light_mean_1h": m["light_mean_1h"],
        "vpd_kpa": es * (1 - m["air_humidity_pct"] / 100),
        "hour_sin": np.sin(2 * np.pi * m["heure"] / 24),
        "hour_cos": np.cos(2 * np.pi * m["heure"] / 24),
        "soil_slope_1h": m["soil_moisture_pct"] - m["soil_moisture_pct_il_y_a_1h"],
        "days_after_transplant": m["days_after_transplant"],
    }
    X_new = pd.DataFrame([ligne])[paquet["features"]]
    proba = float(paquet["modele"].predict_proba(X_new)[0, 1])
    return proba, int(proba >= paquet["seuil_decision"])


def couche_securite(besoin_eau: int, niveau_reservoir_pct: float, flamme: bool) -> str:
    """Règles dures, prioritaires sur le modèle."""
    if flamme:
        return "ALARME : buzzer ON, pompe et lampe coupées"
    if besoin_eau and niveau_reservoir_pct < 10:
        return "Besoin d'eau mais réservoir vide : pompe bloquée, buzzer ON"
    return "Arroser : impulsion de pompe de 10 s" if besoin_eau else "Ne rien faire"


if __name__ == "__main__":
    paquet = charger_modele()
    print("Features :", paquet["features"])
    print("Seuil :", paquet["seuil_decision"], "| scikit-learn :", paquet["version_sklearn"])

    matin_soleil = dict(soil_moisture_pct=80, soil_moisture_pct_il_y_a_1h=84, air_temp_c=27,
                        air_humidity_pct=45, light_lux=35000, light_mean_1h=33000,
                        heure=11, days_after_transplant=35)
    nuit = dict(soil_moisture_pct=80, soil_moisture_pct_il_y_a_1h=80.5, air_temp_c=19,
                air_humidity_pct=75, light_lux=0, light_mean_1h=0,
                heure=23, days_after_transplant=35)

    for nom, m in [("11 h, plein soleil", matin_soleil), ("23 h, nuit", nuit)]:
        proba, besoin = recommander_irrigation(paquet, m)
        print(f"{nom:20s} | sol 80 % | proba = {proba:.2f} | "
              f"{couche_securite(besoin, niveau_reservoir_pct=60, flamme=False)}")
