#!/bin/bash
# Trust the CA, then hand off to the pc1 desktop node entrypoint.
#
# The root CA is a host-generated volume mount (net-user-pl/ca/out) that can lag
# behind container boot — running `bash ca/gen.sh` and `docker compose up` are
# separate steps. So trust it EVENTUALLY in the background (retry until it
# appears) instead of racing once at boot and leaving HTTPS untrusted forever.
# The desktop boots immediately either way; Chromium reads the NSS db on each
# launch (app://launch happens after boot), by which time trust is in place.
set -eu

trust_ca() {
  for _ in $(seq 1 60); do          # ~2 min: covers the gen.sh / compose race
    if /usr/local/bin/setup-ca; then
      return 0
    fi
    sleep 2
  done
  echo "pc-user-pl: CA never appeared at /opt/ca/rootCA.pem — HTTPS will warn" >&2
}

trust_ca &
echo "pc-user-pl: logged in as ${TWIN_USER:-user}"
exec /usr/local/bin/pc1-desktop
