@echo off
REM CyberMysz — provisioning wirtualnego Windows 11 pracownika (uruchamiane RAZ na 1. starcie).
REM Ufa lokalnemu CA bliźniaka, instaluje polskie aplikacje biurowe i agenta CyberMysz.
setlocal enableextensions

echo === CyberMysz provisioning Windows 11 ===

REM 1) Zaufaj lokalnemu root CA bliźniaka (ważny HTTPS jak na produkcji)
if exist C:\OEM\ca\rootCA.pem (
  certutil -addstore -f Root C:\OEM\ca\rootCA.pem
  echo   [OK] root CA zainstalowany w magazynie Zaufane
) else (
  echo   [--] brak C:\OEM\ca\rootCA.pem (pomijam zaufanie CA)
)

REM 2) Menedżer pakietów (winget) + aplikacje biurowe pracownika
REM    (Płatnik ZUS / InsERT / Comarch instaluje się osobno z ich instalatorów —
REM     tu przygotowujemy środowisko: pakiet biurowy, przeglądarka, PDF, runtime.)
winget install -e --id TheDocumentFoundation.LibreOffice --silent --accept-package-agreements --accept-source-agreements
winget install -e --id Mozilla.Firefox --silent --accept-package-agreements --accept-source-agreements
winget install -e --id 7zip.7zip --silent --accept-package-agreements --accept-source-agreements
winget install -e --id Python.Python.3.12 --silent --accept-package-agreements --accept-source-agreements
winget install -e --id Microsoft.VCRedist.2015+.x64 --silent --accept-package-agreements --accept-source-agreements
echo   [OK] aplikacje biurowe zainstalowane (LibreOffice, Firefox, 7zip, Python)

REM 3) Włącz RDP (żeby pulpit Linux mógł się łączyć: windows-erp:3389)
reg add "HKLM\System\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f
netsh advfirewall firewall set rule group="remote desktop" new enable=Yes
echo   [OK] RDP włączony (cel: windows-erp:3389)

REM 4) Zainstaluj agenta CyberMysz + autostart po zalogowaniu
if exist C:\OEM\scenarios\run.py (
  mkdir "%USERPROFILE%\.cybermysz" 2>nul
  xcopy /E /I /Y C:\OEM\scenarios "%USERPROFILE%\.cybermysz\scenarios" >nul
  REM autostart: skrót w folderze Autostart uzytkownika
  set STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup
  echo python "%USERPROFILE%\.cybermysz\scenarios\run.py" > "%STARTUP%\cybermysz.cmd"
  echo   [OK] agent CyberMysz zainstalowany + autostart po zalogowaniu
) else (
  echo   [--] brak C:\OEM\scenarios (agent nie zainstalowany)
)

echo === Gotowe. Windows 11 pracownika przygotowany. ===
