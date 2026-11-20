"""
Test local des modeles sans materiel.

  python try_model.py                 # 12 scenarios tomate avec resultat attendu (OK / ECART)
  python try_model.py -i              # mode interactif : tapez vos propres valeurs de capteurs
  python try_model.py --soil 700 --temp 32 --hum 60 --light 40000 --dist 5    # un cas direct
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "edge"))
import edge_models as m

# (nom, soil_raw, temp, hum, light, dist, irrigation attendu, climat attendu)
SCENARIOS = [
    ("Sol tres sec, jour tempere",       780, 24, 60, 15000, 4.0, "IRRIGATE", "FAN_OFF"),
    ("Sol tres humide",                  350, 24, 60, 15000, 4.0, "OFF", "FAN_OFF"),
    ("Sol sec mais reservoir vide",      780, 24, 60, 15000, 11.5, "REFILL_ALERT", "FAN_OFF"),
    ("Canicule + plein soleil",          650, 36, 40, 55000, 5.0, "IRRIGATE", "FAN_ON"),
    ("Nuit fraiche, sol correct",        500, 15, 85, 5, 5.0, "OFF", "FAN_OFF"),
    ("Chaud et humide (moisissure)",     450, 29, 88, 8000, 5.0, "OFF", "FAN_ON"),
    ("Humidite air tres elevee",         450, 22, 95, 3000, 5.0, "OFF", "FAN_ON"),
    ("Soleil fort, 29 C",                450, 29, 50, 45000, 5.0, "OFF", "FAN_ON"),
    ("Sol moyen, frais et humide",       620, 20, 94, 4000, 5.0, "OFF", "FAN_ON"),
    ("Sol limite mais chaud",            580, 33, 45, 50000, 5.0, "IRRIGATE", "FAN_ON"),
    ("Reservoir vide + canicule",        800, 35, 40, 50000, 12.0, "REFILL_ALERT", "FAN_ON"),
    ("Conditions ideales",               450, 23, 65, 12000, 4.0, "OFF", "FAN_OFF"),
]
ANOMALIES = [
    ("Arrosage efficace",   700, 190, 0.5, 4, "NORMAL"),
    ("Fuite",               700, 30, 1.6, 4, "FUITE"),
    ("Pompe bloquee",       700, 5, 0.05, 4, "POMPE_BLOQUEE"),
    ("Capteur sol delire",  700, -150, 0.5, 80, "CAPTEUR_DEFAILLANT"),
]


def show(soil, temp, hum, light, dist):
    irr = m.predict_irrigation(soil, temp, hum, light, dist)
    clim = m.predict_climate(temp, hum, light)
    return irr, clim


def batch():
    ok = 0
    print(f"{'scenario':36} {'irrigation':14} {'climat':9} verdict")
    for name, s, t, h, l, d, ei, ec in SCENARIOS:
        irr, clim = show(s, t, h, l, d)
        good = (irr, clim) == (ei, ec); ok += good
        print(f"{name:36} {irr:14} {clim:9} {'OK' if good else f'ECART (attendu {ei}/{ec})'}")
    print(f"\n{ok}/{len(SCENARIOS)} scenarios conformes")
    print("\nDiagnostic post-arrosage :")
    for name, sb, sd, wd, sstd, exp in ANOMALIES:
        got = m.predict_anomaly(sb, sd, wd, sstd)
        print(f"{name:36} {got:20} {'OK' if got == exp else 'ECART (attendu ' + exp + ')'}")


def interactive():
    print("Entrez les valeurs (Entree = valeur par defaut). Ctrl+C pour quitter.")
    defaults = dict(soil=600, temp=25, hum=60, light=15000, dist=5)
    prompts = dict(soil="sol brut 0-1023 (haut=sec)", temp="temp air C", hum="humidite air %",
                   light="lumiere lux", dist="distance eau cm (>10 = vide)")
    try:
        while True:
            v = {}
            for k, p in prompts.items():
                r = input(f"  {p} [{defaults[k]}] : ").strip()
                v[k] = float(r) if r else defaults[k]
            irr, clim = show(v["soil"], v["temp"], v["hum"], v["light"], v["dist"])
            print(f"  -> POMPE: {irr}   VENTILATEUR: {clim}\n")
            defaults = v
    except (KeyboardInterrupt, EOFError):
        print()


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("-i", action="store_true")
    for k in ("soil", "temp", "hum", "light", "dist"):
        ap.add_argument(f"--{k}", type=float)
    a = ap.parse_args()
    if a.i:
        interactive()
    elif a.soil is not None:
        print(show(a.soil, a.temp, a.hum, a.light, a.dist))
    else:
        batch()
