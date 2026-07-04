#!/bin/bash
# Trust the CA, then hand off to the pc1 desktop node entrypoint.
set -eu
/usr/local/bin/setup-ca || true
echo "pc-user-pl: logged in as ${TWIN_USER:-user}"
exec /usr/local/bin/pc1-desktop
