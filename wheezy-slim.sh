#!/usr/bin/env bash
#
# wheezy-slim.sh
# Allège la Debian Wheezy de la VM Marionnet (IUT Villetaneuse) en purgeant GUI,
# docs et applis lourdes, et bascule APT vers les dépôts archivés
#
# - supprime man-db (plus de trigger long)
# - désactive les triggers APT
# - purge dynamiquement les paquets *-doc
#
# Patrice BRINGUIER
#
# 15/05/2025
# patrice.bringuier@univ-paris13.fr
# 
#
set -euo pipefail

# 0) Réécriture de /etc/apt/sources.list
SL=/etc/apt/sources.list
BACKUP=${SL}.$(date +%Y%m%d_%H%M%S).bak

echo "Sauvegarde de sources.list → $BACKUP"
cp -v "$SL" "$BACKUP"
cat > "$SL" << 'EOF'
# Wheezy archivées
deb http://archive.debian.org/debian/ wheezy main
deb http://archive.debian.org/debian-security wheezy/updates main
EOF
chmod 644 "$SL"

# 0b) Ignorer expiration et signatures manquantes
cat > /etc/apt/apt.conf.d/99archive << 'EOF'
Acquire::Check-Valid-Until "false";
Acquire::AllowInsecureRepositories "true";
EOF

# Options communes pour désactiver triggers et forcer "oui"
APT_OPTS=(
  -o DPkg::Options::="--no-triggers"
  --yes --force-yes
)

# 1) Mise à jour
apt-get update -qq

# 2) On supprime man-db en premier pour éviter le trigger
apt-get "${APT_OPTS[@]}" purge --auto-remove man-db

# 3) Purge interface graphique et bibliothèques X
apt-get "${APT_OPTS[@]}" purge --auto-remove \
  'x11-*' 'libx11-*' libxext6 libxrender1 libxrandr2 \
  libxt6 libxft2 libgtk* libqt* xauth xorg*

# 4) Purge applis lourdes et multimédia
apt-get "${APT_OPTS[@]}" purge --auto-remove \
  libreoffice-* thunderbird* chromium-browser* firefox-* \
  gimp* inkscape* vlc* ffmpeg* gstreamer* audacity* \
  cups* sane-utils evince* yelp* nautilus*

# 5) Purge dynamique des paquets *-doc
DOC_PKGS=$(apt-cache pkgnames | grep -E '.*-doc$' || true)
if [ -n "$DOC_PKGS" ]; then
  apt-get "${APT_OPTS[@]}" purge --auto-remove $DOC_PKGS
fi

# 6) Purge docs de base et pages de manuel restantes
apt-get "${APT_OPTS[@]}" purge --auto-remove \
  manpages doc-base groff-base info install-info localepurge

# 7) Suppression manuelle des pages et documents
rm -rf /usr/share/man/* /usr/share/doc/*

# 8) Nettoyage final
apt-get "${APT_OPTS[@]}" autoremove --purge
apt-get "${APT_OPTS[@]}" autoclean
apt-get "${APT_OPTS[@]}" clean

echo "=== Terminé : micro-Linux opérationnel ! ==="
echo "Ancien sources.list → $BACKUP"
