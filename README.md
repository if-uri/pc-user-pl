# pc-user-pl — Jan Kowalski's personal computer

The **computer of an average citizen** in the isolated digital twin: a virtual
desktop (Xvfb + openbox + Chromium + noVNC) running a real `urirun` node with
the KVM connector, joined to the virtual internet and trusting its local CA — so
Chromium sees valid HTTPS on `mbank.pl` / `phone.jan.pl` just like the real web.
Everything Jan does is driven through the urirun mesh (`kvm://`, `app://`).

Trio: [net-user-pl](https://github.com/if-uri/net-user-pl) (network) · **pc-user-pl** (computer) · [mobile-user-pl](https://github.com/if-uri/mobile-user-pl) (phone). Orchestrated by `pc1`.

## Build

The desktop extends the `pc1-desktop:local` base image (built by the `pc1`
project). Because it derives from a local-only tag, use the legacy builder:

```bash
DOCKER_BUILDKIT=0 docker build -t pc-user-pl-desktop:local desktop
```

## Run

Needs net-user-pl up (creates `netpl` and the CA under `../net-user-pl/ca/out`):

```bash
docker network create netpl                      # idempotent
docker compose -f compose.pc.yml up -d
# watch Jan work live:
xdg-open http://127.0.0.1:26080/vnc.html
```

The node is reachable at `http://127.0.0.1:28765` for `urirun host add-node`.

## What it adds over the base desktop

- installs the net-user-pl root CA into the system store **and** Chromium's NSS
  db (so HTTPS validates with no warning) — see `desktop/setup-ca.sh`;
- joins the `netpl` network so `mbank.pl`, `phone.jan.pl` resolve;
- identifies the session as **Jan Kowalski** (`TWIN_USER`).

Trust is contained to this image only — the CA is never installed on the host.

## Office software (the Polish workplace layer)

Beyond the browser, Jan's PC now carries the software an average Polish office
actually runs — so mesh-driven scenarios (`kvm://`, `app://`) can exercise real
document work, not just web pages:

| Obszar | Aplikacje |
|---|---|
| Pakiet biurowy | **LibreOffice Writer / Calc / Impress** z polską lokalizacją, słownikiem (hunspell/hyphen/mythes) i fontami Carlito/Caladea (metrycznie zgodne z Calibri/Cambria — dokumenty z firm na MS Office renderują się poprawnie) |
| Poczta | **Thunderbird** (PL) |
| Księgowość | **GnuCash** — otwarty odpowiednik pakietu księgowego |
| Codzienne narzędzia | Evince (PDF), PCManFM (pliki), Mousepad, Galculator, Xarchiver + 7z/zip, GIMP |
| Locale | `pl_PL.UTF-8`, strefa `Europe/Warsaw` |

Aplikacje popularne w polskich firmach, które są Windows-only (Płatnik ZUS,
InsERT, Comarch) albo web-only (KSeF, ePUAP), reprezentuje warstwa **webowa
bliźniaka** — gotowe launchery (`office/apps/*.desktop`, także w menu openboksa
pod prawym przyciskiem):

- **mBank — bankowość** → `https://mbank.pl`
- **Poczta firmowa** → `https://poczta.jan.pl`
- **e-Urząd** → `https://gov.pl`
- **Telefon Jana** → `https://phone.jan.pl`

Przykładowe dokumenty leżą w `/root/Dokumenty` (`faktura-vat.fods` z formułami
VAT 23%, `pismo-firmowe.fodt`, `kontrahenci.csv`) — od razu jest na czym testować
scenariusze "otwórz fakturę i sprawdź kwotę brutto".

Wszystko jest wystawione przez XDG, więc mesh widzi i uruchamia te aplikacje:

```bash
urirun run 'app://pc1/desktop/query/list'                       # zawiera libreoffice-*, thunderbird, mbank…
urirun run 'app://pc1/desktop/command/launch' --payload '{"app": "libreoffice-calc"}'
urirun run 'app://pc1/desktop/command/launch' --payload '{"app": "mbank"}'
```

Uwaga: warstwa biurowa powiększa obraz o ~1.5 GB (LibreOffice+GIMP+GnuCash) —
to celowy koszt wierności bliźniaka biurowego.
