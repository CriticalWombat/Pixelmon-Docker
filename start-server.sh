#!/usr/bin/env bash
set -euo pipefail

cd /server

# EULA (set EULA=true at runtime)
echo "eula=${EULA}" > eula.txt

# First-run persistence setup
mkdir -p /data/world /data/config /data/logs /data/mods
ln -sfn /data/mods mods

# Seed mods into /data/mods if not present
for f in /mods/*; do
  bn="$(basename "$f")"
  if [ ! -e "/data/mods/$bn" ]; then
    cp "$f" "/data/mods/$bn"
  fi
done

# server.properties (create if missing)
if [ ! -f /data/server.properties ]; then
  cat > /data/server.properties <<EOF
server-port=${SERVER_PORT}
enable-rcon=${RCON_ENABLE}
rcon.port=${RCON_PORT}
online-mode=true
motd=Pixelmon Reforged 9.1.13
max-players=20
EOF
fi
ln -sfn /data/server.properties server.properties

# JVM flags
JAVA_OPTS="-Xms${Xms} -Xmx${Xmx}"

exec java ${JAVA_OPTS} -jar forge.jar nogui
