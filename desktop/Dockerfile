# pc-user-pl — Jan Kowalski's personal computer.
# Extends the pc1 desktop node (Xvfb+openbox+Chromium+noVNC + urirun kvm node)
# and adds trust for the net-user-pl virtual-internet root CA, so Chromium sees
# valid HTTPS on mbank.pl / phone.jan.pl exactly as on the real internet.
#
# Requires the base image built first:  (in urirun-multiplatform-test or pc1)
#   docker build -t pc1-desktop:local ...
FROM pc1-desktop:local

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates libnss3-tools \
    && rm -rf /var/lib/apt/lists/*

COPY setup-ca.sh /usr/local/bin/setup-ca
COPY pc-entrypoint.sh /usr/local/bin/pc-entrypoint
RUN chmod +x /usr/local/bin/setup-ca /usr/local/bin/pc-entrypoint

ENV TWIN_USER="Jan Kowalski" \
    NODE_NAME=pc1
ENTRYPOINT ["/usr/local/bin/pc-entrypoint"]
