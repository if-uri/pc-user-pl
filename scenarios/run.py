#!/usr/bin/env python3
# CyberMysz — autonomiczny agent zadań biurowych.
# Author: Tom Sapletta · Part of the ifURI solution.
"""CyberMysz agent — uruchamia zadania z katalogu AUTONOMICZNIE na komputerze pracownika.

Klient kupuje EFEKT: agent startuje razem z systemem, czyta katalog scenariuszy
(`catalog.json` + `tasks/*.json`) i wykonuje je wg harmonogramu — każdy krok to adres
URI dyspozycjonowany do lokalnego węzła urirun (przeglądarka, pulpit, OCR, ERP przez
RDP…). Cała praca zapisuje się jako zdarzenia `run://` i `log://`.

    python3 run.py --list           # pokaż katalog (pakiety + zadania)
    python3 run.py --once           # wykonaj zadania „on-start" i te, których termin minął
    python3 run.py --task mail-do-crm   # wykonaj jedno zadanie
    python3 run.py                  # tryb agenta: pętla wg harmonogramu (dla autostartu)

Bez zależności (tylko stdlib) — działa na dowolnym pulpicie pracownika.
"""
from __future__ import annotations

import argparse
import json
import os
import time
import urllib.request
from datetime import datetime
from pathlib import Path

HERE = Path(__file__).resolve().parent
NODE = os.environ.get("URIRUN_NODE", "http://127.0.0.1:8765")
EVENTBUS = os.environ.get("EVENTBUS_URL", "http://127.0.0.1:28800")
STATE = Path(os.environ.get("CYBERMYSZ_HOME", str(Path.home() / ".cybermysz")))
EXECUTE = os.environ.get("CYBERMYSZ_EXECUTE", "0") == "1"      # domyślnie plan-only (bezpiecznie)


def _log(line: str):
    STATE.mkdir(parents=True, exist_ok=True)
    stamp = "[" + str(int(time.time())) + "]"
    (STATE / "cybermysz.log").open("a").write(f"{stamp} {line}\n")
    print(f"{stamp} {line}")


def _emit(uri, **payload):
    body = json.dumps({"uri": uri, "actor": "cybermysz", "payload": payload}).encode()
    try:
        urllib.request.urlopen(urllib.request.Request(
            f"{EVENTBUS}/emit", data=body, headers={"Content-Type": "application/json"}), timeout=3).read()
    except Exception:
        pass


def load_catalog() -> dict:
    return json.loads((HERE / "catalog.json").read_text())


def load_task(task_id: str) -> dict | None:
    f = HERE / "tasks" / f"{task_id}.json"
    return json.loads(f.read_text()) if f.exists() else None


def _dispatch(uri: str, payload: dict) -> dict:
    """Wykonaj URI na lokalnym węźle (jeśli EXECUTE), inaczej zaplanuj (dry)."""
    if not EXECUTE:
        return {"ok": True, "dry": True}
    body = json.dumps({"uri": uri, "mode": "execute", "payload": payload}).encode()
    try:
        env = json.load(urllib.request.urlopen(urllib.request.Request(
            f"{NODE}/run", data=body, headers={"Content-Type": "application/json"}), timeout=60))
        return {"ok": bool(env.get("ok", True)), "result": env.get("result")}
    except Exception as exc:  # noqa: BLE001
        return {"ok": False, "error": str(exc)[:120]}


def run_task(task_id: str) -> dict:
    task = load_task(task_id)
    if not task:
        _log(f"! zadanie bez przepływu: {task_id} (dodaj tasks/{task_id}.json)")
        return {"id": task_id, "ok": False, "reason": "brak-przeplywu"}
    _emit(f"run://cybermysz/{task_id}/command/start", tytul=task.get("tytul"))
    _log(f"▶ {task_id}: {task.get('tytul')}")
    ok = True
    for i, step in enumerate(task.get("flow", [])):
        out = _dispatch(step["uri"], step.get("payload", {}))
        mark = "·" if out.get("dry") else ("✓" if out.get("ok") else "✗")
        _log(f"    {mark} {step['uri']}  — {step.get('note', '')}")
        ok = ok and out.get("ok", False)
    _emit(f"run://cybermysz/{task_id}/command/done", ok=ok)
    _emit(f"log://cybermysz/{task_id}/command/write", efekt=task.get("tytul"), ok=ok)
    _log(f"  {'✅' if ok else '⚠️'} {task_id} {'wykonane' if EXECUTE else '(plan — ustaw CYBERMYSZ_EXECUTE=1 by wykonać)'}")
    return {"id": task_id, "ok": ok}


def _due_now(harmonogram: str) -> bool:
    """Prosty planer: on-start → tak; 'codziennie HH:MM' / 'HH:MM' → w tej minucie;
    'co N min/godz' → na starcie i cyklicznie (obsługiwane w pętli agenta)."""
    h = (harmonogram or "").lower()
    now = datetime.now()
    if "on-" in h:                                   # wyzwalacz zdarzeniowy — poza planerem czasowym
        return False
    for token in h.replace(",", " ").split():
        if ":" in token:
            try:
                hh, mm = token.split(":")
                return now.hour == int(hh) and now.minute == int(mm)
            except ValueError:
                pass
    return False


def list_catalog():
    cat = load_catalog()
    print("== Pakiety startowe CyberMysz\n")
    for p in cat["packages"]:
        print(f"  {p['nazwa']:<18} od {p['cena_od']} zł — {p['dla_kogo']}")
        print(f"     zadania: {', '.join(p['zadania'])}")
    print("\n== Katalog rozwiązań (zadania)\n")
    for s in cat["solutions"]:
        has = "●" if (HERE / "tasks" / f"{s['id']}.json").exists() else "○"
        print(f"  {has} [{s['plan']:<5} {s['kategoria']:<15}] {s['tytul']}")
        print(f"     efekt: {s['efekt']}  · oszczędność: {s['oszczednosc']}  · od {s['start_cena']} zł")
    print("\n  ● = ma gotowy przepływ (tasks/<id>.json)   ○ = do skonfigurowania przy wdrożeniu")


def run_once():
    cat = load_catalog()
    ran = []
    for s in cat["solutions"]:
        h = (s.get("harmonogram") or "").lower()
        if "on-start" in h or "start" in h or _due_now(h) or (HERE / "tasks" / f"{s['id']}.json").exists() and "on-" not in h and ":" not in h:
            if (HERE / "tasks" / f"{s['id']}.json").exists():
                run_task(s["id"]); ran.append(s["id"])
    if not ran:
        _log("brak zadań do wykonania w tej chwili")
    return ran


def agent_loop():
    _log(f"CyberMysz agent wystartował (EXECUTE={'tak' if EXECUTE else 'nie — plan-only'})")
    _emit("run://cybermysz/agent/command/start", execute=EXECUTE)
    fired = set()
    # na starcie: wykonaj zadania z gotowym przepływem, które nie są zdarzeniowe
    for s in load_catalog()["solutions"]:
        if (HERE / "tasks" / f"{s['id']}.json").exists() and "on-" not in (s.get("harmonogram") or ""):
            run_task(s["id"])
    while True:
        minute_key = datetime.now().strftime("%H:%M")
        for s in load_catalog()["solutions"]:
            if _due_now(s.get("harmonogram", "")) and (s["id"], minute_key) not in fired:
                if (HERE / "tasks" / f"{s['id']}.json").exists():
                    run_task(s["id"]); fired.add((s["id"], minute_key))
        if len(fired) > 500:
            fired.clear()
        time.sleep(30)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--list", action="store_true", help="pokaż katalog")
    ap.add_argument("--once", action="store_true", help="wykonaj należne zadania i wyjdź")
    ap.add_argument("--task", help="wykonaj jedno zadanie po id")
    args = ap.parse_args(argv)
    if args.list:
        list_catalog()
    elif args.task:
        run_task(args.task)
    elif args.once:
        run_once()
    else:
        agent_loop()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
