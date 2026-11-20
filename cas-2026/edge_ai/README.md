# SmartFarm AI - Edge AI local (culture : tomate)

100 % local : aucun appel reseau, ni a l'entrainement ni sur le Raspberry Pi.
Description complete du travail, principe de fonctionnement et seuils : voir [DOCUMENTATION.md](DOCUMENTATION.md).

```
edge_ai/
  edge/                 <- tourne sur le Pi (aucune dependance ML)
    runtime.py            agent CLI : capteurs -> securite -> arbres -> relais -> journal CSV
    hardware.py           pilote Pi 3B (cablage du dossier technique), partage avec le serveur app/server
    edge_models.py        les 3 arbres en if/else purs (genere par retrain.py, ne pas editer)
    config.py             features, BROCHAGE, etalonnage capteurs, polarites (un seul fichier a ajuster)
  training/             <- PC seulement (scikit-learn, pandas, numpy)
    settings.py           profil tomate : seuils agronomiques, bruit capteur, profondeur des arbres
    datagen.py            donnees synthetiques (politique d'expert + bruit capteur)
    train.py              entrainement, export Python, verification export == scikit-learn
  retrain.py            <- une commande : generer -> entrainer -> exporter -> tester
  try_model.py          <- tester les arbres a la main, sans materiel
  build/                <- genere (regles lisibles, metriques) : regenerable
```

## Commandes (depuis ce dossier)
```
python try_model.py                          # 12 scenarios + 4 diagnostics
python try_model.py -i                       # mode interactif
python edge/runtime.py --sim                 # simulation complete d'une journee
python edge/runtime.py --sim --inject FUITE  # idem avec panne (POMPE_BLOQUEE, CAPTEUR_DEFAILLANT)
python retrain.py                            # tout regenerer (scikit-learn, pandas, numpy requis)
```

## Sur le Raspberry Pi
L'agent complet (arbres + tableau de bord web) s'installe avec `bash deploy/install_pi.sh <date>` a la racine du depot
(voir le README principal). L'agent CLI seul reste utilisable :
```
cd edge_ai/edge
../../venv/bin/python runtime.py --selftest    # 1er lancement : relais, buzzer, polarite flamme, distance ultrason
../../venv/bin/python runtime.py               # agent seul, sans application web (ne pas lancer en meme temps que le service)
```

## Corrections apportees (revue du code)
- **JSN-SR04T** : zone aveugle ~25 cm. Le capteur doit etre fixe au moins 25 cm au-dessus du niveau plein ; la distance
  mesuree est convertie vers l'echelle d'entrainement (2.5 plein / 10 vide) par `config.to_model_dist()`.
- **Serie Arduino** : la premiere ligne apres le vidage du tampon est jetee (elle pouvait etre tronquee : "12" au lieu de "512").
- **DHT22** : une valeur de plus de 30 s est consideree manquante (avant : derniere valeur gardee indefiniment).
- **Pompe** : arret programme par un minuteur materiel (une lecture lente ne prolonge plus l'impulsion ; 10 s max garanti).
- **Flamme** : polarite configurable `FLAME_ACTIVE_LOW` (les modules LM393 passent a LOW quand ils voient une flamme).
- **Diagnostic** : le sol "apres" est la mediane des 5 dernieres lectures, comme le sol "avant".
