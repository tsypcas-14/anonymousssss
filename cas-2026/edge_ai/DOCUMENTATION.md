# SmartFarm AI - Documentation de la partie IA

## 1. Objectif
Mini-serre intelligente (culture : **tomate**) qui decide localement, sur un Raspberry Pi 3B, quand arroser,
quand ventiler et quand alerter. Conforme au reglement du challenge : **aucune inference cloud**.
Chaine demandee : Capteurs -> Traitement intelligent en edge -> Decision -> Action.

## 2. Travail realise
- **Donnees** : jeu de donnees synthetique construit dans les unites reelles lues par le Pi (valeur brute de l'ADC,
  distance en cm, lux, degres C, % HR), avec cycle jour/nuit et bruit realiste sur chaque capteur.
- **Modeles** : 3 arbres de decision (scikit-learn, profondeur limitee pour rester lisibles), exportes en code
  Python pur (`edge/edge_models.py`) : aucune bibliotheque de ML necessaire sur le Pi, decision en microsecondes.
- **Verification de l'export** : le code exporte est compare a scikit-learn sur tout le jeu de donnees (100 % identique).
- **Programme embarque** (`edge/runtime.py`) : lecture des capteurs, regles de securite, appel des arbres,
  commande des relais, hysteresis temporelle, diagnostic apres arrosage, verrouillage de la pompe, journal CSV.
- **Outils** : `retrain.py` (regeneration complete en une commande, test de fumee inclus),
  `try_model.py` (test manuel sans materiel), mode `--sim` du runtime (simulation d'une journee, avec injection de pannes).

## 3. Principe de fonctionnement
Une boucle toutes les **2 s** :

```
capteurs -> [1 securite] -> [2 diagnostic] -> [3 arbre irrigation] -> relais pompe
                                           -> [4 arbre climat]     -> relais ventilateur
                                           -> journal CSV
```

1. **Securite (regles fixes, prioritaires sur l'IA)**
   - Flamme detectee : buzzer ON, pompe et ventilateur coupes (le ventilateur alimenterait le feu).
   - Une lecture capteur manquante : pompe coupee, cycle ignore (pas d'arrosage a l'aveugle).
   - Reservoir vide (distance eau > 10 cm) : pompe interdite, quelle que soit la decision de l'arbre.
2. **Arbre 3 - diagnostic post-arrosage** (60 s apres chaque impulsion) : compare le sol et le niveau d'eau avant/apres
   pour classer l'arrosage : NORMAL, FUITE, POMPE_BLOQUEE ou CAPTEUR_DEFAILLANT.
   Deux fuites / pompes bloquees consecutives verrouillent la pompe jusqu'a intervention humaine.
3. **Arbre 1 - irrigation** : decide IRRIGATE, OFF ou REFILL_ALERT. Un arrosage est une **impulsion de 5 s**,
   suivie de 60 s d'attente pour que l'eau diffuse avant toute nouvelle decision (evite le sur-arrosage).
4. **Arbre 2 - climat** : decide FAN_ON ou FAN_OFF. Le ventilateur ne change pas d'etat plus d'une fois toutes les 3 minutes.

### Role de chaque arbre
| Arbre | Entrees | Sortie |
|---|---|---|
| Irrigation | sol brut, temperature air, humidite air, lumiere, distance eau | IRRIGATE / OFF / REFILL_ALERT |
| Climat | temperature air, humidite air, lumiere | FAN_ON / FAN_OFF |
| Anomalies | sol avant, baisse du sol, eau consommee, instabilite du capteur de sol | NORMAL / FUITE / POMPE_BLOQUEE / CAPTEUR_DEFAILLANT |

### Comment les arbres ont ete construits
Les etiquettes viennent d'une **politique d'agronome** (seuils ci-dessous) appliquee aux valeurs vraies ; du bruit
capteur est ensuite ajoute aux entrees. L'arbre apprend ainsi a reproduire la politique malgre des mesures imparfaites.

## 4. Seuils utilises (profil tomate, `training/settings.py`)

### Irrigation (valeur brute du sol : plus haut = plus sec)
| Condition | Seuil de declenchement |
|---|---|
| Cas normal | sol > **600** |
| Chaud (> **30 C**) ou plein soleil (> **30 000 lux**) | sol > **560** (on arrose plus tot : forte evaporation) |
| Air humide (> **85 %**) et frais (< **24 C**) | sol > **640** (on tolere un sol plus sec) |
| Reservoir vide (distance > **10 cm**) | REFILL_ALERT, pompe interdite |

### Ventilation (le ventilateur s'allume si l'une de ces conditions est vraie)
| Condition |
|---|
| temperature > **30 C** |
| temperature > **27 C** et humidite air > **80 %** |
| humidite air > **90 %** (risque de moisissure) |
| temperature > **28 C** et lumiere > **30 000 lux** |

### Diagnostic d'anomalies (apprentissage sur evenements simules)
| Cas | Signature |
|---|---|
| NORMAL | le sol baisse de ~120 a 260 (il s'humidifie), eau consommee ~0,3 a 0,8 cm |
| FUITE | beaucoup d'eau consommee (~0,9 a 2,2 cm) mais peu d'effet sur le sol (baisse < ~70) |
| POMPE_BLOQUEE | ni eau consommee (< ~0,15 cm) ni effet sur le sol |
| CAPTEUR_DEFAILLANT | lectures du sol tres instables (ecart-type > ~20 sur 5 lectures) |

### Parametres du programme embarque (`edge/runtime.py`)
| Parametre | Valeur |
|---|---|
| Periode de lecture | 2 s |
| Impulsion de pompe | 5 s (chien de garde : 10 s maximum d'affilee) |
| Attente apres impulsion (diffusion + diagnostic) | 60 s |
| Delai minimum entre 2 changements du ventilateur | 180 s (60 s faisait battre le relais) |
| Verrouillage de la pompe | apres 2 fuites / pompes bloquees consecutives |
| Mesure d'eau (JSN-SR04T) | mediane de 5 mesures |
| Mesure du sol | mediane de 3 lectures serie (Arduino) |

### Brochage utilise (BCM)
Ultrason TRIG 23 / ECHO 24 - flamme 27 - buzzer 22 - relais ventilateur 18 - relais pompe 17 -
DHT22 sur GPIO4 - BH1750 en I2C (0x23) - sol via Arduino (USB serie, `/dev/ttyACM0`).

## 5. Resultats (jeu de test simule, 20 %)
| Arbre | Exactitude |
|---|---|
| Irrigation | 96,5 % |
| Climat | 93,7 % |
| Anomalies | 100 % |

Ces chiffres mesurent la **fidelite a la politique definie**, sur des donnees simulees. Ils ne constituent pas
une mesure de performance sur materiel reel. Le diagnostic d'anomalies atteint 100 % car les cas simules ne se
chevauchent pas ; sur materiel reel il sera plus bas.

## 6. A mesurer sur le prototype
- **Montage du JSN-SR04T** : zone aveugle ~25 cm. Mesurer la distance reservoir plein et vide et les reporter dans
  `SENSOR_DIST_FULL_CM` / `SENSOR_DIST_EMPTY_CM` (`edge/config.py`) ; elles sont converties vers l'echelle des arbres
  (2,5 cm = plein, 10 cm = vide).
- **Effet reel d'une impulsion de pompe de 5 s** sur la valeur du sol : le diagnostic suppose une baisse de ~120 a 260.
- **Sens des relais et du capteur de flamme** : lancer `python3 runtime.py --selftest` au premier demarrage ; sinon changer
  `RELAY_ACTIVE_LOW` / `FLAME_ACTIVE_LOW` dans `edge/config.py`.

## 7. Regenerer ou ajuster
Modifier les seuils dans `training/settings.py` (ou fournir un JSON partiel avec `--profile`), puis :
```
python retrain.py
```
Copier ensuite `edge/` sur le Pi.
