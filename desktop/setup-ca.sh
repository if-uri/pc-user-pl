#!/bin/bash
# Trust the virtual-internet root CA — system store + Chromium's NSS db.
set -eu
CA=/opt/ca/rootCA.pem
[ -f "$CA" ] || { echo "no CA at $CA (mount net-user-pl/ca/out) — HTTPS will warn"; exit 0; }

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
