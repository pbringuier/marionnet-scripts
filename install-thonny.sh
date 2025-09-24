#!/usr/bin/env bash
#------------------------------------------------------------------------------
# install-thonny.sh
#
# Objectif :
#   - Bascule les dépôts vers archive.debian.org / old-releases.ubuntu.com
#   - Met à jour apt
#   - Installe Python3 + Tkinter
#   - Installe pip via get-pip.py
#   - Installe Thonny <3.4 (compatible Python 3.6)
#
# Usage :
#   curl -L -k https://URL/vers/install-thonny.sh | bash
#
#------------------------------------------------------------------------------

set -euo pipefail

echo ">>> Sauvegarde et bascule des dépôts..."

# Sauvegarde sources.list
SL=/etc/apt/sources.list
BACKUP=${SL}.$(date +%Y%m%d_%H%M%S).bak
cp -v "$SL" "$BACKUP" || true

# Détecte Ubuntu vs Debian
if grep -qi ubuntu /etc/os-release 2>/dev/null; then
  cat > "$SL" <<'EOF'
deb http://old-releases.ubuntu.com/ubuntu/ bionic main universe
deb http://old-releases.ubuntu.com/ubuntu/ bionic-updates main universe
deb http://old-releases.ubuntu.com/ubuntu/ bionic-security main universe
EOF
else
  cat > "$SL" <<'EOF'
deb http://archive.debian.org/debian wheezy main contrib non-free
deb http://archive.debian.org/debian-security wheezy/updates main contrib non-free
EOF
  mkdir -p /etc/apt/apt.conf.d
  cat > /etc/apt/apt.conf.d/99archive <<'EOC'
Acquire::Check-Valid-Until "false";
Acquire::AllowInsecureRepositories "true";
EOC
fi

chmod 644 "$SL"

echo ">>> apt-get update..."
apt-get -o Acquire::Retries=3 update || true

echo ">>> Installation de Python3 et Tkinter..."
apt-get install -y python3 python3-tk || true

echo ">>> Installation de pip (via get-pip.py)..."
cd /tmp
curl -L -k https://bootstrap.pypa.io/pip/3.6/get-pip.py -o get-pip.py
python3 get-pip.py

echo ">>> Installation de Thonny (version <3.4) et dépendances TP..."
pip3 install "thonny<3.4" matplotlib pytest

echo ">>> Vérification..."
which thonny || true

echo "✅ Installation terminée. Lance 'thonny' pour démarrer."

