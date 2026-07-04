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

# ── Office layer ──────────────────────────────────────────────────────────────
# The software an average Polish office worker actually has on their machine.
# Polish-company staples that are Windows-only (Płatnik, InsERT/Comarch) or
# web-only (KSeF, ePUAP) are represented by the twin's WEB apps instead
# (see office/apps/*.desktop → mbank.pl, gov.pl, poczta.jan.pl on netpl).
#   - LibreOffice (Writer/Calc/Impress) with full Polish l10n + spellcheck,
#     plus Carlito/Caladea fonts (metric-compatible with Calibri/Cambria, so
#     documents from MS-Office shops render correctly);
#   - Thunderbird (the most common desktop mail client in PL offices);
#   - GnuCash — the open bookkeeping stand-in for the accounting suite;
#   - GIMP, Evince (PDF), PCManFM (files), Mousepad, Galculator, Xarchiver
#     (+7z/zip) — the everyday toolbox;
#   - pl_PL.UTF-8 locale + Europe/Warsaw so dates/currency look native.
RUN apt-get update && apt-get install -y --no-install-recommends \
      locales tzdata \
      libreoffice-writer libreoffice-calc libreoffice-impress \
      libreoffice-gtk3 libreoffice-l10n-pl hunspell-pl hyphen-pl mythes-pl \
      fonts-crosextra-carlito fonts-crosextra-caladea \
      thunderbird thunderbird-l10n-pl \
      gnucash gimp evince \
      pcmanfm mousepad galculator xarchiver p7zip-full unzip zip \
    && sed -i 's/^# *pl_PL.UTF-8 UTF-8/pl_PL.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen \
    && ln -fs /usr/share/zoneinfo/Europe/Warsaw /etc/localtime \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=pl_PL.UTF-8 \
    LC_ALL=pl_PL.UTF-8 \
    TZ=Europe/Warsaw

# Twin web apps (valid HTTPS thanks to setup-ca) + a human-friendly openbox menu
# + sample documents every Polish office recognises (invoice, letterhead, CRM CSV).
# The .desktop entries also make these launchable through the mesh:
#   app://pc1/desktop/command/launch {"app": "mbank"}
COPY office/apps/ /usr/share/applications/
COPY office/menu.xml /etc/xdg/openbox/menu.xml
COPY office/samples/ /root/Dokumenty/

COPY setup-ca.sh /usr/local/bin/setup-ca
COPY pc-entrypoint.sh /usr/local/bin/pc-entrypoint
RUN chmod +x /usr/local/bin/setup-ca /usr/local/bin/pc-entrypoint

ENV TWIN_USER="Jan Kowalski" \
    NODE_NAME=pc1
ENTRYPOINT ["/usr/local/bin/pc-entrypoint"]
