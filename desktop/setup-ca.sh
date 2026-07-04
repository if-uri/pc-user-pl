#!/bin/bash
# Trust the virtual-internet root CA — system store + Chromium's NSS db.
# Returns non-zero when the CA isn't present yet, so the entrypoint can retry
# (the CA is a host-generated volume mount that may lag behind container boot).
set -eu
CA=/opt/ca/rootCA.pem
[ -f "$CA" ] || { echo "no CA at $CA (mount net-user-pl/ca/out) — not trusted yet"; exit 1; }

cp "$CA" /usr/local/share/ca-certificates/netpl-root.crt
update-ca-certificates >/dev/null 2>&1 || true

# Chromium reads $HOME/.pki/nssdb
NSSDB="${HOME:-/root}/.pki/nssdb"
mkdir -p "$NSSDB"
if [ ! -f "$NSSDB/cert9.db" ]; then
  certutil -N --empty-password -d "sql:$NSSDB"
fi
certutil -A -n netpl-root -t "C,," -i "$CA" -d "sql:$NSSDB" 2>/dev/null || true
echo "virtual-internet CA trusted (system + NSS)"
