"""Constantes partagees entre l'entrainement, le runtime CLI et le serveur (unites = celles lues par le Pi).

soil_raw   : ADC 0-1023 de l'Arduino A0 (capteur capacitif : PLUS HAUT = PLUS SEC)
air_temp   : DHT22, degres C          air_hum : DHT22, % HR
light      : BH1750, lux
water_dist : distance "echelle modele" en cm (2.5 = reservoir plein, 10 = vide).
             La distance reellement mesuree par le JSN-SR04T est convertie par to_model_dist().
flame      : capteur digital -> regle de securite codee en dur, PAS du ML
"""
FEATURES_IRRIGATION = ["soil_raw", "air_temp", "air_hum", "light", "water_dist"]
FEATURES_CLIMATE = ["air_temp", "air_hum", "light"]
FEATURES_ANOMALY = ["soil_before", "soil_drop", "water_drop_cm", "soil_std"]

# Seuil physique : au-dela, le reservoir est vide -> pompe interdite (aussi applique par le runtime)
WATER_EMPTY_CM = 10.0
WATER_FULL_CM = 2.5                 # echelle sur laquelle les arbres ont ete entraines

# ======================= MATERIEL (dossier technique, Raspberry Pi 3B, BCM) =======================
PIN = dict(TRIG=23, ECHO=24, FLAME=27, BUZZER=22, FAN=18, PUMP=17)   # DHT22 sur GPIO4, BH1750 en I2C
RELAY_ACTIVE_LOW = True      # la plupart des modules relais s'activent a LOW -> verifier avec --selftest
FLAME_ACTIVE_LOW = True      # modules LM393 : sortie DO a LOW quand une flamme est vue -> verifier avec --selftest
SERIAL_PORT = "/dev/ttyACM0"
SERIAL_BAUD = 9600           # le croquis Arduino du dossier : Serial.println(analogRead(A0)) toutes les 500 ms
BH1750_ADDR = 0x23           # ADDR -> GND
DHT_MAX_AGE_S = 30.0         # au-dela, une valeur DHT22 est perimee -> lecture "manquante" (pas d'arrosage a l'aveugle)

# Montage du JSN-SR04T. ATTENTION : il ne mesure rien sous ~20-25 cm (zone aveugle).
# Il doit donc etre fixe AU MOINS 25 cm au-dessus du niveau "plein". Mesurer sur le prototype :
SENSOR_DIST_FULL_CM = 25.0   # distance mesuree reservoir plein
SENSOR_DIST_EMPTY_CM = 32.5  # distance mesuree reservoir vide (ici 7.5 cm d'eau utile)
# (Avec un HC-SR04, sans zone aveugle, on peut mettre 2.5 et 10.0 : la conversion devient l'identite.)
TANK_LITERS = 2.0            # volume utile du reservoir, pour les statistiques d'eau consommee

# Etalonnage du capteur de sol (affichage en % uniquement ; les arbres travaillent en valeur brute)
SOIL_RAW_WET = 300           # valeur brute juste apres un arrosage complet
SOIL_RAW_DRY = 900           # valeur brute sol sec / a l'air


def to_model_dist(sensor_cm):
    """Distance mesuree (cm) -> echelle du modele (2.5 plein ... 10 vide). Lineaire, donc le % de remplissage est conserve."""
    span = SENSOR_DIST_EMPTY_CM - SENSOR_DIST_FULL_CM
    return WATER_FULL_CM + (sensor_cm - SENSOR_DIST_FULL_CM) / span * (WATER_EMPTY_CM - WATER_FULL_CM)


def tank_pct(model_dist):
    return max(0.0, min(100.0, (WATER_EMPTY_CM - model_dist) / (WATER_EMPTY_CM - WATER_FULL_CM) * 100))


def soil_pct(raw):
    return max(0.0, min(100.0, (SOIL_RAW_DRY - raw) / (SOIL_RAW_DRY - SOIL_RAW_WET) * 100))


def model_cm_to_liters(cm):
    return cm / (WATER_EMPTY_CM - WATER_FULL_CM) * TANK_LITERS
