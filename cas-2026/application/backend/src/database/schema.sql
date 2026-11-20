-- SmartFarm : schéma de départ (Phase 0). Aucune donnée, aucune logique.
-- Les horodatages sont en millisecondes Unix (UTC). Historique conservé 7 jours (PDD section 4).

CREATE TABLE IF NOT EXISTS mesures (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  capteur     TEXT    NOT NULL,   -- ex. 'sol', 'air_temperature', 'air_humidite', 'lumiere', 'reservoir', 'flamme'
  valeur      REAL    NOT NULL,
  horodatage  INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_mesures_capteur_temps ON mesures (capteur, horodatage);

CREATE TABLE IF NOT EXISTS evenements (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  type        TEXT    NOT NULL,   -- ex. 'arrosage', 'aeration', 'securite', 'mode', 'capteur'
  texte       TEXT    NOT NULL,
  horodatage  INTEGER NOT NULL,
  niveau      TEXT    NOT NULL CHECK (niveau IN ('info', 'a_verifier', 'critique'))  -- 3 niveaux du PDD, section 7
);
CREATE INDEX IF NOT EXISTS idx_evenements_temps ON evenements (horodatage);

CREATE TABLE IF NOT EXISTS seuils (
  nom         TEXT    PRIMARY KEY,
  valeur      REAL    NOT NULL,
  modifiable  INTEGER NOT NULL DEFAULT 0 CHECK (modifiable IN (0, 1))  -- lecture seule en version 1
);

-- Une seule ligne : un seul compte agriculteur (PDD section 2).
CREATE TABLE IF NOT EXISTS preferences (
  id                 INTEGER PRIMARY KEY CHECK (id = 1),
  mode_notification  TEXT NOT NULL DEFAULT 'importantes' CHECK (mode_notification IN ('importantes', 'toutes')),
  contact_urgence    TEXT
);
