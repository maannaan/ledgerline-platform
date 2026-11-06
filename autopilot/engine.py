from __future__ import annotations

import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from autopilot.actions import registry
from autopilot.audit import logger as audit
from autopilot.killswitch import is_killed
from autopilot.models import Decision, Policy, Signal

_AUDIT_DIR = Path(__file__).resolve().parent / "audit"
STATE_PATH = _AUDIT_DIR / "state.json"
DEFAULT_POLICIES = Path(__file__).resolve().parent / "policies" / "staging.json"


def load_policies(path: Path | None = None) -> list[Policy]:
    policy_path = path or DEFAULT_POLICIES
    data = json.loads(policy_path.read_text(encoding="utf-8"))
    return [Policy.from_dict(p) for p in data.get("policies", [])]


def _load_state() -> dict[str, Any]:
    if not STATE_PATH.exists():
        return {"attempts": {}}
    return json.loads(STATE_PATH.read_text(encoding="utf-8"))


def _resolved_state_path() -> Path:
    """Ensure state file stays under autopilot/audit (no path traversal)."""
    path = STATE_PATH.resolve()
    audit_root = _AUDIT_DIR.resolve()
    if path.parent != audit_root or path.name != "state.json":
        raise ValueError("refusing to write state outside autopilot/audit")
    return path


def _save_state(state: dict[str, Any]) -> None:
    # Path is a package constant under autopilot/audit (never user-controlled).
    path = _resolved_state_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = json.dumps(state, indent=2) + "\n"
    with open(path, "w", encoding="utf-8") as handle:  # NOSONAR pythonsecurity:S2083
        handle.write(payload)


def idempotency_key(signal: Signal, policy: Policy) -> str:
    raw = f"{policy.id}|{signal.name}|{signal.environment}|{signal.service}|{signal.attributes.get('window', '')}"
    return hashlib.sha256(raw.encode()).hexdigest()[:16]


def match_policy(signal: Signal, policies: list[Policy]) -> Policy | None:
    for policy in policies:
        if not policy.enabled:
            continue
        if policy.signal != signal.name:
            continue
        if signal.environment not in policy.environments:
            continue
        if signal.service not in policy.services:
            continue
        if policy.threshold is not None and signal.value is not None:
            if signal.value < policy.threshold:
                continue
        return policy
    return None


def _decision(
    *,
    status: str,
    policy_id: str | None,
    action: str | None,
    reason: str,
    idempotency_key: str,
    details: dict[str, Any] | None = None,
    audit_path: Path | None = None,
) -> Decision:
    decision = Decision(
        status=status,
        policy_id=policy_id,
        action=action,
        reason=reason,
        idempotency_key=idempotency_key,
        details=details or {},
    )
    audit.append_event({"type": "decision", **decision.to_dict()}, audit_path)
    return decision


def _precheck_blocks(
    policy: Policy,
    key: str,
    record: dict[str, Any],
    *,
    dry_run: bool,
    approve: bool,
    now: datetime,
    audit_path: Path | None,
) -> Decision | None:
    if record.get("last_ts"):
        last = datetime.fromisoformat(record["last_ts"])
        delta = (now - last).total_seconds()
        if delta < policy.cooldown_seconds and record["count"] > 0:
            return _decision(
                status="blocked",
                policy_id=policy.id,
                action=policy.action,
                reason="cooldown_active",
                idempotency_key=key,
                details={"cooldown_seconds": policy.cooldown_seconds, "elapsed": delta},
                audit_path=audit_path,
            )

    if record["count"] >= policy.max_attempts and not dry_run:
        return _decision(
            status="blocked",
            policy_id=policy.id,
            action=policy.action,
            reason="max_attempts_exceeded",
            idempotency_key=key,
            details={"max_attempts": policy.max_attempts},
            audit_path=audit_path,
        )

    if policy.requires_approval and not approve and not dry_run:
        return _decision(
            status="blocked",
            policy_id=policy.id,
            action=policy.action,
            reason="human_approval_required",
            idempotency_key=key,
            details={"tenant_blast_radius": policy.tenant_blast_radius},
            audit_path=audit_path,
        )
    return None


def evaluate(
    signal: Signal,
    policies: list[Policy],
    *,
    dry_run: bool = True,
    approve: bool = False,
    audit_path: Path | None = None,
) -> Decision:
    if is_killed():
        return _decision(
            status="blocked",
            policy_id=None,
            action=None,
            reason="global_kill_switch",
            idempotency_key="kill",
            audit_path=audit_path,
        )

    policy = match_policy(signal, policies)
    if policy is None:
        return _decision(
            status="skipped",
            policy_id=None,
            action=None,
            reason="no_matching_policy",
            idempotency_key="none",
            details={"signal": signal.name},
            audit_path=audit_path,
        )

    key = idempotency_key(signal, policy)
    state = _load_state()
    attempts = state.setdefault("attempts", {})
    record = attempts.get(key, {"count": 0, "last_ts": None})
    now = datetime.now(timezone.utc)

    blocked = _precheck_blocks(
        policy, key, record, dry_run=dry_run, approve=approve, now=now, audit_path=audit_path
    )
    if blocked is not None:
        return blocked

    try:
        fn = registry.get(policy.action)
    except KeyError as exc:
        return _decision(
            status="error",
            policy_id=policy.id,
            action=policy.action,
            reason=str(exc),
            idempotency_key=key,
            audit_path=audit_path,
        )

    result = fn(signal, policy, dry_run)
    status = "dry_run" if dry_run else "executed"
    if isinstance(result, dict) and result.get("blocked"):
        status = "blocked"

    if not dry_run and status == "executed":
        record["count"] = int(record.get("count", 0)) + 1
        record["last_ts"] = now.isoformat()
        attempts[key] = record
        _save_state(state)

    return _decision(
        status=status,
        policy_id=policy.id,
        action=policy.action,
        reason="ok",
        idempotency_key=key,
        details={
            "verification": policy.verification,
            "result": result,
            "blast_radius": policy.tenant_blast_radius,
        },
        audit_path=audit_path,
    )
