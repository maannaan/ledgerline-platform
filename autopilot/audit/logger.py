from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

DEFAULT_LOG = Path(__file__).resolve().parent / "events.jsonl"


def append_event(event: dict[str, Any], path: Path | None = None) -> Path:
    log_path = path or DEFAULT_LOG
    log_path.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "ts": datetime.now(timezone.utc).isoformat(),
        **event,
    }
    with log_path.open("a", encoding="utf-8") as f:
        f.write(json.dumps(payload, sort_keys=True) + "\n")
    return log_path


def read_events(path: Path | None = None, limit: int = 50) -> list[dict[str, Any]]:
    log_path = path or DEFAULT_LOG
    if not log_path.exists():
        return []
    lines = log_path.read_text(encoding="utf-8").splitlines()
    out = []
    for line in lines[-limit:]:
        if line.strip():
            out.append(json.loads(line))
    return out
