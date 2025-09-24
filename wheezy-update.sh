#!/usr/bin/env bash
#------------------------------------------------------------------------------
# wheezy-update.sh
#
# Objectif :
#   Alléger une Debian *Wheezy* (VM Marionnet – IUT Villetaneuse) et basculer
#   APT vers les dépôts archivés pour permettre les mises à jour/installs.
#
# Actions principales :
#   - Reconfigure /etc/apt/sources.list vers archive.debian.org (wheezy).
#   - Désactive les vérifications d’expiration/signatures des Release.
#   - Supprime man-db (évite les triggers lents) et désactive les triggers APT.
#
# Avertissements :
#   - Environnement EOL : utilisation des archives et options permissives.
#   - À utiliser sur VM d’enseignement uniquement (pas de prod).
#
# Utilisation :
#   root# bash wheezy-update.sh
#
# Auteur  : Patrice BRINGUIER
# Contact : patrice.bringuier@univ-paris13.fr
# Date    : 2025-05-15
# Version : 1.0
#------------------------------------------------------------------------------
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

# 2) Suppression de man-db (évite triggers lents)
echo "→ Suppression de man-db et pages de manuels…"
apt-get purge "${APT_OPTS[@]}" -y man-db manpages || true

