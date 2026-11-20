#!/usr/bin/env bash
# Installs the SmartFarm agent + web app on a Raspberry Pi 3B (Raspberry Pi OS). Run from the repo folder:
#   bash deploy/install_pi.sh 2026-11-01        <- the day the tomatoes were transplanted
# Safe to run again (it only updates what changed).
set -euo pipefail

DATE="${1:-}"
if [[ ! "$DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  echo "Usage: bash deploy/install_pi.sh YYYY-MM-DD   (transplant date of the tomatoes)"; exit 1
fi
DIR="$(cd "$(dirname "$0")/.." && pwd)"
USER_NAME="$(id -un)"
cd "$DIR"

echo "==> System packages (python venv, I2C tools, GPIO library for the DHT22)"
sudo apt-get update -qq
sudo apt-get install -y -qq python3-venv python3-dev i2c-tools libgpiod2

echo "==> Enable I2C (BH1750) and serial access (Arduino on USB)"
sudo raspi-config nonint do_i2c 0 || echo "   (enable I2C by hand: sudo raspi-config > Interface Options > I2C)"
sudo usermod -aG gpio,i2c,dialout "$USER_NAME" || true

echo "==> Python environment"
python3 -m venv venv
venv/bin/pip install -q --upgrade pip
venv/bin/pip install -q -r deploy/requirements-pi.txt

echo "==> Checks"
venv/bin/python -m unittest discover -s tests 2>&1 | tail -3
ls /dev/ttyACM* /dev/ttyUSB* 2>/dev/null || echo "   WARNING: no Arduino found on USB (expected /dev/ttyACM0, see edge_ai/edge/config.py)"
i2cdetect -y 1 2>/dev/null | grep -q " 23" && echo "   BH1750 found at 0x23" || echo "   WARNING: BH1750 not seen at 0x23 on I2C bus 1"

echo "==> systemd service (starts on boot, restarts if it crashes)"
sed -e "s#__DIR__#$DIR#g" -e "s#__USER__#$USER_NAME#g" -e "s#__DATE__#$DATE#g" deploy/smartfarm.service \
  | sudo tee /etc/systemd/system/smartfarm.service >/dev/null
sudo systemctl daemon-reload
sudo systemctl enable smartfarm

cat <<EOF

Installed. BEFORE starting the service, test the wiring once (relays, buzzer, flame polarity, ultrasonic):
    cd $DIR/edge_ai/edge && ../../venv/bin/python runtime.py --selftest
Fix edge_ai/edge/config.py if needed (RELAY_ACTIVE_LOW, FLAME_ACTIVE_LOW, SENSOR_DIST_FULL_CM / EMPTY_CM), then:
    sudo systemctl start smartfarm
    journalctl -u smartfarm -f            (logs)
Then read the greenhouse code (needed to create an account in the app) and write it on the greenhouse:
    cat $DIR/app/server/data/greenhouse_code.txt
Open the app on a phone or PC on the same Wi-Fi:  http://$(hostname -I | awk '{print $1}'):8000
EOF
