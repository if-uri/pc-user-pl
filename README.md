# pc-user-pl — Jan Kowalski's personal computer

The **computer of an average citizen** in the isolated digital twin: a virtual
desktop (Xvfb + openbox + Chromium + noVNC) running a real `urirun` node with
the KVM connector, joined to the virtual internet and trusting its local CA — so
Chromium sees valid HTTPS on `mbank.pl` / `phone.jan.pl` just like the real web.
Everything Jan does is driven through the urirun mesh (`kvm://`, `app://`).

Trio: [net-user-pl](https://github.com/digitaltwin-run/net-user-pl) (network) · **pc-user-pl** (computer) · [mobile-user-pl](https://github.com/digitaltwin-run/mobile-user-pl) (phone). Orchestrated by [`pc1`](https://github.com/digitaltwin-run/pc1).

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
| Pakiet biurowy | **LibreOffice Writer / Calc / Impress / Base** z polską lokalizacją, słownikiem (hunspell/hyphen/mythes), fontami Carlito/Caladea; **Gnumeric** jako drugi arkusz |
| Poczta | **Thunderbird** (PL) |
| Księgowość | **GnuCash** — otwarty odpowiednik pakietu księgowego |
| Praca z PDF/fakturami | **Okular** (podgląd+adnotacje), **pdfarranger** (łączenie/dzielenie), **qpdf**, **simple-scan** (skanowanie faktur) |
| Praca z danymi | **Meld** (porównanie plików/eksportów — uzgadnianie), **KeePassXC** (menedżer haseł) |
| Cross-system | **Remmina** (+RDP/VNC) → połączenie z serwerem **Windows** (Płatnik/InsERT/ERP), **FileZilla** (SFTP/FTP do serwera) |
| Przeglądarki | Chromium + **Firefox ESR** (PL) — część e-usług pinuje jeden silnik |
| Narzędzia | Evince, PCManFM, Mousepad, **Qalculate** (VAT/odsetki), **Flameshot** (zrzuty), Galculator, Xarchiver + 7z/zip, GIMP, **Java (JRE)** dla apletów gov |
| Locale | `pl_PL.UTF-8`, strefa `Europe/Warsaw` |

Web-aplikacje biznesowe/rządowe — gotowe launchery (`office/apps/*.desktop`, także
w menu openboksa): **mBank**, **Poczta firmowa**, **e-Urząd (gov.pl)**, **Telefon Jana**,
**CRM firmowy**, **Panel sklepu**, **KSeF (e-Faktury)**, **ZUS PUE**, **ERP/Płatnik przez RDP**
(→ `windows-erp`), oraz **CyberMysz — katalog zadań**.

Aplikacje Windows-only (Płatnik ZUS, InsERT/Subiekt, Comarch Optima) mają teraz
**prawdziwy wirtualny Windows 11** — patrz [`win/`](win/) — a pulpit Linux łączy się z
nimi przez RDP (`remmina`), jak w biurze z serwerem Windows.

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

## CyberMysz — scenariusze i autonomiczne wdrożenie

Folder [`scenarios/`](scenarios/) to gotowy do wdrożenia **katalog zadań biurowych**
(pakiety Biuro/Księgowość/E-commerce Start + 13 rozwiązań: mail→CRM, faktura PDF→ERP,
raport dzienny, status zamówień, reklamacje…) oraz **agent, który wykonuje je
autonomicznie po starcie systemu**:

```bash
python3 scenarios/run.py --list        # katalog (pakiety + zadania, efekt, oszczędność, cena)
python3 scenarios/run.py --task mail-do-crm   # jedno zadanie (plan-only)
scenarios/install.sh                   # wdróż: autostart z systemem (systemd --user / XDG)
```

Każdy krok zadania to adres URI dyspozycjonowany do lokalnego węzła urirun; cała praca
zapisuje się jako `run://` i `log://`. Domyślnie **plan-only** (bezpiecznie), wykonanie
włącza się świadomie (`install.sh --execute`). Pełny model wdrożenia i „Jak wdrożyć?" →
[`scenarios/README.md`](scenarios/README.md).

## Wirtualny Windows 11 (aplikacje Windows-only)

Do scenariuszy **cross-system** — [`win/`](win/) uruchamia prawdziwy Windows 11 w
kontenerze (QEMU/KVM), spięty z `netpl`, z zaufanym lokalnym CA i provisioningiem
(`oem/install.bat`: pakiet biurowy, RDP, agent CyberMysz + autostart):

```bash
docker compose -f win/compose.win.yml up -d    # wymaga /dev/kvm
# pulpit Windows:  http://localhost:8006   · RDP z pulpitu Linux: windows-erp:3389
```

Tam żyją Płatnik ZUS / InsERT / Comarch (instalowane z ich instalatorów), a pulpit Linux
łączy się z nimi przez `remmina` — jak w prawdziwym biurze z serwerem Windows. Dzięki temu
przepływ „faktura PDF → ERP" testuje się **realnie przez dwa systemy**.
