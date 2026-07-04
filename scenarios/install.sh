#!/usr/bin/env bash
# CyberMysz — wdrożenie na komputerze pracownika: kopiuje scenariusze do ~/.cybermysz
# i włącza autostart po zalogowaniu (systemd --user, z fallbackiem XDG autostart).
#
#   ./install.sh              # instaluj + włącz (plan-only, bezpiecznie)
#   ./install.sh --execute    # to samo, ale zadania będą FAKTYCZNIE wykonywane
#   ./install.sh --uninstall  # wyłącz i usuń autostart
set -euo pipefail
SRC="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/.cybermysz/scenarios"
EXECUTE=0

case "${1:-}" in
  --uninstall)
    systemctl --user disable --now cybermysz.service 2>/dev/null || true
    rm -f "$HOME/.config/systemd/user/cybermysz.service" "$HOME/.config/autostart/cybermysz.desktop"
    echo "CyberMysz: autostart wyłączony."; exit 0 ;;
  --execute) EXECUTE=1 ;;
esac

echo "• kopiuję scenariusze → $DEST"
mkdir -p "$DEST"; cp -r "$SRC/"* "$DEST/"

if command -v systemctl >/dev/null && systemctl --user show-environment >/dev/null 2>&1; then
  echo "• instaluję usługę systemd (użytkownik)"
  mkdir -p "$HOME/.config/systemd/user"
  sed "s/CYBERMYSZ_EXECUTE=0/CYBERMYSZ_EXECUTE=$EXECUTE/" \
      "$SRC/autostart/cybermysz.service" > "$HOME/.config/systemd/user/cybermysz.service"
  systemctl --user daemon-reload
  systemctl --user enable --now cybermysz.service
  echo "• włączone. Podgląd:  journalctl --user -u cybermysz -f"
else
  echo "• brak systemd --user → fallback XDG autostart"
  mkdir -p "$HOME/.config/autostart"
  cp "$SRC/autostart/cybermysz.desktop" "$HOME/.config/autostart/"
fi

echo "Gotowe. Tryb: $([ "$EXECUTE" = 1 ] && echo 'WYKONUJE zadania' || echo 'plan-only (bezpiecznie)')."
echo "Katalog:  python3 $DEST/run.py --list"
