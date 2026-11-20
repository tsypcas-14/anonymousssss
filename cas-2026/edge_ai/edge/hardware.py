"""Pilote materiel du Raspberry Pi 3B (cablage du dossier technique). 100 % local.

Utilise par edge/runtime.py (programme CLI) et par le serveur app/server (tableau de bord).
Les bibliotheques materielles sont importees dans __init__ : ce fichier s'importe sur un PC sans erreur.

Corrections par rapport a la premiere version :
  - JSN-SR04T : distance convertie a l'echelle du modele (zone aveugle ~25 cm, voir config.py)
  - serie Arduino : la 1re ligne apres vidage du tampon est jetee (elle peut etre tronquee : "12" au lieu de "512")
  - DHT22 : une valeur plus vieille que DHT_MAX_AGE_S est consideree manquante
  - pompe : l'arret est programme par un minuteur independant de la boucle (une lecture lente ne prolonge plus l'arrosage)
  - flamme : polarite configurable (FLAME_ACTIVE_LOW)
"""
import statistics
import threading
import time

from config import (BH1750_ADDR, DHT_MAX_AGE_S, FLAME_ACTIVE_LOW, PIN, RELAY_ACTIVE_LOW, SERIAL_BAUD,
                    SERIAL_PORT, to_model_dist)

PUMP_MAX_S = 10.0            # chien de garde : jamais plus que ca d'affilee, quoi qu'il arrive


class Hardware:
    def __init__(self):
        import RPi.GPIO as GPIO
        import adafruit_dht
        import board
        import serial
        import smbus2
        self.GPIO = GPIO
        GPIO.setmode(GPIO.BCM)
        GPIO.setwarnings(False)
        off = GPIO.HIGH if RELAY_ACTIVE_LOW else GPIO.LOW
        GPIO.setup(PIN["PUMP"], GPIO.OUT, initial=off)    # relais OFF des le demarrage
        GPIO.setup(PIN["FAN"], GPIO.OUT, initial=off)
        GPIO.setup(PIN["BUZZER"], GPIO.OUT, initial=GPIO.LOW)
        GPIO.setup(PIN["TRIG"], GPIO.OUT, initial=GPIO.LOW)
        GPIO.setup(PIN["ECHO"], GPIO.IN)
        GPIO.setup(PIN["FLAME"], GPIO.IN)
        self.dht = adafruit_dht.DHT22(board.D4)
        self.ser = serial.Serial(SERIAL_PORT, SERIAL_BAUD, timeout=2)
        self.bus = smbus2.SMBus(1)
        self.last_dht = (None, None, 0.0)             # temp, hum, instant de la lecture
        self.pump_on = False
        self._pump_timer = None
        self._lock = threading.Lock()

    # ----------------------------- capteurs -----------------------------
    def _distance_once(self):
        G = self.GPIO
        G.output(PIN["TRIG"], True); time.sleep(0.00001); G.output(PIN["TRIG"], False)
        t0 = time.time(); timeout = t0 + 0.05
        while G.input(PIN["ECHO"]) == 0:
            t0 = time.time()
            if t0 > timeout: return None
        t1 = t0
        while G.input(PIN["ECHO"]) == 1:
            t1 = time.time()
            if t1 - t0 > 0.05: return None
        return (t1 - t0) * 17150

    def read_distance_cm(self):
        """Distance capteur -> eau en cm (mediane de 5 mesures, le JSN-SR04T est bruite), ou None."""
        d = [x for x in (self._distance_once() for _ in range(5)) if x is not None and 2 < x < 450]
        return statistics.median(d) if d else None

    def read_soil(self):
        """Mediane de 3 lignes fraiches. La 1re ligne apres le vidage est jetee : elle peut etre coupee."""
        self.ser.reset_input_buffer()
        self.ser.readline()
        vals = []
        for _ in range(3):
            line = self.ser.readline().decode("utf-8", "ignore").strip()
            if line.isdigit() and 0 < int(line) < 1023:       # 0 / 1023 = fil debranche ou parasite
                vals.append(int(line))
        return statistics.median(vals) if vals else None

    def read_dht(self):
        try:
            t, h = self.dht.temperature, self.dht.humidity
            if t is not None and h is not None:
                self.last_dht = (t, h, time.time())
        except RuntimeError:                                  # le DHT22 echoue souvent : on garde la derniere valeur...
            pass
        t, h, at = self.last_dht
        if time.time() - at > DHT_MAX_AGE_S:                   # ... mais pas indefiniment
            return None, None
        return t, h

    def read_light(self):
        try:
            self.bus.write_byte(BH1750_ADDR, 0x10); time.sleep(0.18)
            raw = self.bus.read_i2c_block_data(BH1750_ADDR, 0x10, 2)
            return (raw[0] << 8 | raw[1]) / 1.2
        except OSError:
            return None

    def read_flame(self):
        level = self.GPIO.input(PIN["FLAME"])
        return level == 0 if FLAME_ACTIVE_LOW else level == 1

    def read(self):
        """Un releve complet. water_dist est a l'echelle du modele ; water_dist_sensor_cm est la mesure brute."""
        dist = self.read_distance_cm()
        temp, hum = self.read_dht()
        return dict(soil_raw=self.read_soil(), air_temp=temp, air_hum=hum, light=self.read_light(),
                    water_dist=None if dist is None else round(to_model_dist(dist), 2),
                    water_dist_sensor_cm=dist, flame=self.read_flame())

    # ----------------------------- actionneurs -----------------------------
    def _relay(self, name, on):
        self.GPIO.output(PIN[name], (not on) if RELAY_ACTIVE_LOW else on)

    def set_pump(self, on):
        with self._lock:
            if self._pump_timer:
                self._pump_timer.cancel(); self._pump_timer = None
            self.pump_on = bool(on)
            self._relay("PUMP", on)
            if on:                                            # chien de garde independant de la boucle
                self._pump_timer = threading.Timer(PUMP_MAX_S, self.set_pump, (False,))
                self._pump_timer.daemon = True
                self._pump_timer.start()

    def pulse_pump(self, seconds):
        """Allume la pompe et programme son arret exact apres `seconds` (minuteur, pas la boucle)."""
        seconds = min(seconds, PUMP_MAX_S)
        self.set_pump(True)
        with self._lock:
            self._pump_timer.cancel()
            self._pump_timer = threading.Timer(seconds, self.set_pump, (False,))
            self._pump_timer.daemon = True
            self._pump_timer.start()

    def set_fan(self, on): self._relay("FAN", on)
    def set_buzzer(self, on): self.GPIO.output(PIN["BUZZER"], on)

    def close(self):
        self.set_pump(False); self.set_fan(False); self.set_buzzer(False)
        self.GPIO.cleanup()


def selftest(hw):
    print("Selftest : chaque sortie s'active 2 s. Verifiez que le BON organe reagit.")
    for name, fn in (("BUZZER", hw.set_buzzer), ("RELAIS VENTILATEUR", hw.set_fan), ("RELAIS POMPE", hw.set_pump)):
        print(f" -> {name} ON"); fn(True); time.sleep(2); fn(False); print(f" -> {name} OFF"); time.sleep(1)
    print("Si un relais est ACTIF au repos / inverse, changez RELAY_ACTIVE_LOW dans config.py.")
    print("Capteur de flamme : approchez un briquet pendant 5 s...")
    seen = []
    for _ in range(10):
        seen.append(hw.GPIO.input(PIN["FLAME"])); time.sleep(0.5)
    print(f"   niveaux lus : {seen}  -> flamme = {'LOW (0)' if FLAME_ACTIVE_LOW else 'HIGH (1)'} attendu ; sinon changez FLAME_ACTIVE_LOW.")
    d = hw.read_distance_cm()
    print(f"Distance brute JSN-SR04T : {d} cm (doit etre > 25 cm ; reportez plein/vide dans SENSOR_DIST_*_CM).")
    print("Lecture complete :", hw.read())
