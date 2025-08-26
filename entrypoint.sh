#!/usr/bin/env sh
set -euo pipefail

# Ensure expected dirs exist
mkdir -p /server /mods /data

# If /data isn't writable by minecraft (uid 10001), fix ownership
if ! su-exec 10001:10001 sh -c 'test -w /data'; then
  echo "[entrypoint] /data not writable by uid 10001; fixing ownership..."
  chown -R 10001:10001 /data
fi

# Also ensure runtime dirs are owned correctly
chown -R 10001:10001 /server /mods

# Drop privileges and start the server manager script
exec su-exec 10001:10001 /usr/local/bin/start-server
