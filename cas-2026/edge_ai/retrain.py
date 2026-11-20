"""
SmartFarm AI - Re-entrainement 100% simule, une seule commande (tout en memoire, aucun script intermediaire).

  python retrain.py                          # profil tomate par defaut
  python retrain.py --seed 7 --samples 20000 # autre tirage / plus de donnees
  python retrain.py --profile mon_profil.json  # surcharge partielle des seuils (voir training/settings.py)
  python retrain.py --no-smoke               # sans le test du runtime en simulation
  python retrain.py --save-data              # ecrit aussi les donnees d'entrainement dans build/*.csv

Etapes : generation -> entrainement -> export edge/edge_models.py (verifie identique a sklearn)
         -> test de fumee du runtime. En cas d'echec, edge_models.py est remis dans son etat precedent.
Sorties : edge/edge_models.py (a copier sur le Pi) ; build/ (regles lisibles et metriques : regenerable).
"""
import argparse
import json
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.abspath(__file__))
sys.path[:0] = [os.path.join(ROOT, "edge"), os.path.join(ROOT, "training")]

from datagen import generate          # noqa: E402
from settings import load_profile      # noqa: E402
from train import export_python, train_all, verify_export  # noqa: E402

BUILD = os.path.join(ROOT, "build")
EDGE_MODELS = os.path.join(ROOT, "edge", "edge_models.py")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--profile")
    ap.add_argument("--seed", type=int)
    ap.add_argument("--samples", type=int)
    ap.add_argument("--no-smoke", action="store_true")
    ap.add_argument("--save-data", action="store_true", help="ecrit les donnees d'entrainement dans build/*.csv")
    a = ap.parse_args()

    sim = {k: v for k, v in (("seed", a.seed), ("samples", a.samples)) if v is not None}
    profile = load_profile(a.profile, {"sim": sim} if sim else None)
    old = open(EDGE_MODELS, encoding="utf-8").read() if os.path.exists(EDGE_MODELS) else None
    old_metrics = None
    if os.path.exists(os.path.join(BUILD, "metrics.json")):
        old_metrics = json.load(open(os.path.join(BUILD, "metrics.json"), encoding="utf-8"))

    try:
        print(f"[1/4] donnees simulees (profil '{profile['name']}', seed {profile['sim']['seed']})")
        dec, anom = generate(profile)
        if a.save_data:
            os.makedirs(BUILD, exist_ok=True)
            dec.to_csv(os.path.join(BUILD, "data_decisions.csv"), index=False)
            anom.to_csv(os.path.join(BUILD, "data_anomalies.csv"), index=False)

        print("[2/4] entrainement des 3 arbres")
        trees, metrics = train_all(dec, anom, profile, BUILD, verbose=False)

        print("[3/4] export edge_models.py + verification export == sklearn")
        export_python(trees, EDGE_MODELS)
        for fn, ok in verify_export(trees, dec, anom, EDGE_MODELS).items():
            print(f"      {fn}: {ok:.0%}")

        if not a.no_smoke:
            print("[4/4] test de fumee du runtime (simulation)")
            r = subprocess.run([sys.executable, os.path.join(ROOT, "edge", "runtime.py"), "--sim", "--steps", "600"],
                               capture_output=True, text=True, encoding="utf-8")
            if r.returncode or "pompe ON" not in r.stdout or "ventilateur ON" not in r.stdout:
                raise RuntimeError("runtime simule en echec ou sans activation pompe/ventilateur :\n" + r.stderr[-800:])
            sim_log = os.path.join(ROOT, "edge", "logs", "sim_readings.csv")
            if os.path.exists(sim_log): os.remove(sim_log)
            print("      OK : pompe et ventilateur se declenchent")
    except Exception as e:
        print("\nECHEC :", e)
        if old is not None:
            open(EDGE_MODELS, "w", encoding="utf-8").write(old); print("edge_models.py remis dans son etat precedent.")
        sys.exit(1)

    print(f"\n{'arbre':17} {'accuracy':>9} {'avant':>7} {'feuilles':>9}")
    for name, m in metrics.items():
        prev = f"{old_metrics[name]['test_accuracy']:.3f}" if old_metrics and name in old_metrics else "-"
        print(f"{name:17} {m['test_accuracy']:9.3f} {prev:>7} {m['leaves']:9d}")
    print("\nSur le Pi : copiez le dossier edge/ (runtime.py, hardware.py, edge_models.py, config.py).")


if __name__ == "__main__":
    main()
