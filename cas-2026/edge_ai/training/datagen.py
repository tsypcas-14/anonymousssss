"""Donnees synthetiques alignees sur le materiel reel.

Les etiquettes sont calculees par la politique d'expert sur les valeurs VRAIES (avant action),
puis on bruite les features comme le feraient les capteurs : l'arbre apprend malgre le bruit.
"""
import numpy as np
import pandas as pd
from config import WATER_EMPTY_CM


def policy_irrigation(IR, soil, temp, hum, light, dist):
    if dist > WATER_EMPTY_CM:
        return "REFILL_ALERT"
    thr = IR["thr_base"]
    if temp > IR["hot_temp"] or light > IR["bright_lux"]:        # chaud / plein soleil -> on arrose plus tot
        thr = IR["thr_hot"]
    elif hum > IR["humid_hum"] and temp < IR["cool_temp"]:       # air humide et frais -> on tolere plus sec
        thr = IR["thr_humid"]
    return "IRRIGATE" if soil > thr else "OFF"


def policy_climate(CL, temp, hum, light):
    if temp > CL["fan_temp"]:
        return "FAN_ON"
    if temp > CL["fan_temp_humid"] and hum > CL["fan_hum_high"]:
        return "FAN_ON"
    if hum > CL["fan_hum_mold"]:                                 # risque de moisissure
        return "FAN_ON"
    if temp > CL["fan_temp_bright"] and light > CL["bright_lux"]:
        return "FAN_ON"
    return "FAN_OFF"


def generate(profile):
    """Retourne (df_decisions, df_anomalies)."""
    IR, CL, SIM = profile["irrigation"], profile["climate"], profile["sim"]
    rng = np.random.default_rng(SIM["seed"])
    N = SIM["samples"]

    hour = rng.uniform(0, 24, N)
    daylight = np.clip(np.sin(np.pi * (hour - 6) / 12), 0, None)     # 0 la nuit, 1 a midi
    cloud = rng.uniform(0.3, 1.0, N)
    light_t = daylight * cloud * rng.uniform(25000, 65000, N) + rng.uniform(0, 30, N)
    temp_t = np.clip(17 + 11 * daylight + rng.normal(0, 3.5, N), 10, 42)
    hum_t = np.clip(92 - 1.6 * (temp_t - 15) + rng.normal(0, 9, N), 25, 99)
    soil_t = rng.uniform(280, 900, N)
    dist_t = rng.uniform(2.5, 12.5, N)

    dec = pd.DataFrame({
        "soil_raw": soil_t + rng.normal(0, SIM["noise_soil"], N),
        "air_temp": temp_t + rng.normal(0, SIM["noise_temp"], N),
        "air_hum": np.clip(hum_t + rng.normal(0, SIM["noise_hum"], N), 0, 100),
        "light": np.clip(light_t * rng.normal(1, SIM["noise_light"], N), 0, None),
        "water_dist": dist_t + rng.normal(0, SIM["noise_dist"], N),
        "irrigation": [policy_irrigation(IR, *v) for v in zip(soil_t, temp_t, hum_t, light_t, dist_t)],
        "climate": [policy_climate(CL, *v) for v in zip(temp_t, hum_t, light_t)],
    }).round(2)

    # evenements d'irrigation : diagnostic d'anomalies
    M = SIM["anomaly_samples"]
    kind = rng.choice(["NORMAL", "FUITE", "POMPE_BLOQUEE", "CAPTEUR_DEFAILLANT"], M, p=[0.7, 0.1, 0.1, 0.1])
    soil_drop, water_drop, soil_std = np.empty(M), np.empty(M), np.empty(M)
    for i, k in enumerate(kind):
        if k == "NORMAL":
            soil_drop[i], water_drop[i], soil_std[i] = rng.uniform(120, 260), rng.uniform(0.3, 0.8), rng.uniform(1, 9)
        elif k == "FUITE":          # beaucoup d'eau consommee, peu d'effet sur le sol
            soil_drop[i], water_drop[i], soil_std[i] = rng.uniform(0, 70), rng.uniform(0.9, 2.2), rng.uniform(1, 9)
        elif k == "POMPE_BLOQUEE":  # ni eau consommee ni effet
            soil_drop[i], water_drop[i], soil_std[i] = rng.uniform(-5, 25), rng.uniform(0, 0.15), rng.uniform(1, 9)
        else:                       # capteur sol defaillant : valeurs erratiques
            soil_drop[i], water_drop[i], soil_std[i] = rng.uniform(-300, 300), rng.uniform(0.3, 0.8), rng.uniform(30, 120)
    anom = pd.DataFrame({
        "soil_before": rng.uniform(580, 850, M) + rng.normal(0, 8, M),
        "soil_drop": soil_drop, "water_drop_cm": water_drop + rng.normal(0, 0.05, M),
        "soil_std": soil_std, "anomaly": kind,
    }).round(2)
    return dec, anom
