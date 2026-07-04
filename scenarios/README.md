# CyberMysz — scenariusze i autonomiczne wdrożenie na komputerze pracownika

Klient kupuje **efekt, nie technologię**. Ten folder to gotowy do wdrożenia zestaw:
katalog zadań (`catalog.json`), przepływy (`tasks/*.json`) i **agent, który wykonuje je
autonomicznie po starcie systemu** (`run.py` + `autostart/`).

## Jak to działa (model autonomiczny)

```
start systemu → autostart → agent CyberMysz (run.py)
                                 │  czyta catalog.json + tasks/*.json
                                 │  wg harmonogramu wykonuje przepływy
                                 ▼
  każdy krok = adres URI  →  lokalny węzeł urirun (przeglądarka, pulpit, OCR, ERP/RDP)
                          →  zapis jako run:// i log:// (audytowalny ślad)
```

Agent jest **jednym procesem bez zależności** (tylko Python stdlib) — działa tak samo na
Linuksie i Windows. Domyślnie **plan-only** (pokazuje co by zrobił); wykonanie włącza się
świadomie przy zatwierdzonym wdrożeniu (`CYBERMYSZ_EXECUTE=1`).

## Jak wdrożyć?

### Linux (pulpit pracownika / pc-user-pl)
```bash
cd scenarios
./install.sh              # kopiuje do ~/.cybermysz, włącza autostart (plan-only)
./install.sh --execute    # to samo, ale zadania są FAKTYCZNIE wykonywane
./install.sh --uninstall  # wyłącz autostart
```
Autostart przez `systemd --user` (fallback: XDG autostart). Podgląd:
`journalctl --user -u cybermysz -f`.

### Windows 11 (aplikacje Windows-only: Płatnik, InsERT, Comarch)
```bash
docker compose -f ../win/compose.win.yml up -d      # wymaga /dev/kvm
```
`oem/install.bat` na 1. starcie ufa lokalnemu CA, instaluje pakiet biurowy + agenta i
zakłada autostart (folder Startup). Pulpit Windows: `http://localhost:8006`; RDP dla
pulpitu Linux: `windows-erp:3389`.

### W bliźniaku (twin) — bez instalacji
Katalog jest montowany w `compose.pc.yml` → `/opt/cybermysz/scenarios`; na pulpicie jest
launcher „CyberMysz — katalog zadań", a agenta uruchamia się ręcznie:
`python3 /opt/cybermysz/scenarios/run.py --list`.

## Pakiety startowe

| Pakiet | Dla kogo | Od | Zadania |
|---|---|---|---|
| **Biuro Start** | małe firmy, administracja, obsługa | 699 zł | raport dzienny, mail→CRM, status zamówień |
| **Księgowość Start** | biura rachunkowe | 999 zł | faktura PDF→ERP, status płatności, raport należności |
| **E-commerce Start** | sklepy i obsługa | 1199 zł | dodawanie produktów, status zamówień, reklamacje |

## Katalog zadań

`python3 run.py --list` pokaże pełną listę (13 rozwiązań: Biuro, Księgowość, Sprzedaż,
Logistyka, HR, E-commerce, Obsługa, Zakupy, Testy). Każde ma efekt, oszczędność i cenę
konfiguracji. `●` = ma gotowy przepływ, `○` = konfigurowane przy wdrożeniu do systemów klienta.

## Dodanie nowego scenariusza

1. Dopisz pozycję w `catalog.json` (kategoria, plan, efekt, harmonogram).
2. Dodaj przepływ `tasks/<id>.json` — lista kroków `{uri, payload, note}`. URI celują w
   systemy klienta (`crm://`, `erp://`, `shop://`) i pulpit (`app://`, `kvm://`).
3. Deterministyczne kontrole (uzgodnienie, spójność) wpinaj przez `recon://`, `audit://` —
   tam agent nie zgaduje, tylko liczy (patrz `urirun-capability`).

## Bezpieczeństwo wdrożenia

- **plan-only domyślnie** — nic nie klika, dopóki wdrożenie nie jest zatwierdzone;
- każdy krok zapisany jako `log://` — pełny audyt co agent zrobił;
- harmonogramy proste i przewidywalne (`codziennie 8:00`, `co 30 min`, `on-nowa-faktura`).
