from __future__ import annotations

import os
from pathlib import Path

ROOT = Path(__file__).resolve().parent
FLAG_FILE = ROOT / "KILL_SWITCH"


def is_killed() -> bool:
    if os.getenv("AUTOPILOT_KILL_SWITCH", "").strip() in {"1", "true", "TRUE", "yes"}:
        return True
    return FLAG_FILE.exists() and FLAG_FILE.read_text(encoding="utf-8").strip() not in {
        "",
        "0",
        "false",
        "off",
    }


def enable(reason: str = "manual") -> None:
    FLAG_FILE.write_text(f"on\n# {reason}\n", encoding="utf-8")


def disable() -> None:
    if FLAG_FILE.exists():
        FLAG_FILE.unlink()


def status() -> dict:
    return {
        "killed": is_killed(),
        "flag_file": str(FLAG_FILE),
        "env_AUTOPILOT_KILL_SWITCH": os.getenv("AUTOPILOT_KILL_SWITCH", ""),
    }
