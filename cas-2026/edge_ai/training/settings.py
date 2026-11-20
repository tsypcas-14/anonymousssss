"""Profil = politique d'expert (culture tomate) + parametres de simulation et d'entrainement."""
import copy
import json

DEFAULT_PROFILE = {
    "name": "tomate",
    "irrigation": {                    # seuils sur soil_raw (ADC, plus haut = plus sec)
        "thr_base": 600, "thr_hot": 560, "thr_humid": 640,
        "hot_temp": 30, "bright_lux": 30000, "humid_hum": 85, "cool_temp": 24,
    },
    "climate": {
        "fan_temp": 30, "fan_temp_humid": 27, "fan_hum_high": 80,
        "fan_hum_mold": 90, "fan_temp_bright": 28, "bright_lux": 30000,
    },
    "sim": {                           # bruit capteur et taille des datasets
        "seed": 42, "samples": 12000, "anomaly_samples": 4000,
        "noise_soil": 12, "noise_temp": 0.5, "noise_hum": 2, "noise_light": 0.03, "noise_dist": 0.2,
    },
    "training": {"depth_irrigation": 6, "depth_climate": 6, "depth_anomaly": 5, "min_leaf": 20},
}


def load_profile(path=None, overrides=None):
    """Profil par defaut, surcharge par un JSON optionnel puis par `overrides` (dict partiel)."""
    p = copy.deepcopy(DEFAULT_PROFILE)
    user = json.load(open(path, encoding="utf-8")) if path else {}
    for src in (user, overrides or {}):
        for k, v in src.items():
            if isinstance(v, dict) and isinstance(p.get(k), dict):
                unknown = set(v) - set(p[k])
                if unknown:
                    raise KeyError(f"parametre inconnu dans '{k}': {sorted(unknown)}")
                p[k].update(v)
            else:
                p[k] = v
    return p
