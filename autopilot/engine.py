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

STATE_PATH = Path(__file__).resolve().parent / "audit" / "state.json"
DEFAULT_POLICIES = Path(__file__).resolve().parent / "policies" / "staging.json"


def load_policies(path: Path | None = None) -> list[Policy]:
    policy_path = path or DEFAULT_POLICIES
    data = json.loads(policy_path.read_text(encoding="utf-8"))
    return [Policy.from_dict(p) for p in data.get("policies", [])]


def _load_state() -> dict[str, Any]:
    if not STATE_PATH.exists():
        return {"attempts": {}}
    return json.loads(STATE_PATH.read_text(encoding="utf-8"))


def _save_state(state: dict[str, Any]) -> None:
    STATE_PATH.parent.mkdir(parents=True, exist_ok=True)
    STATE_PATH.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")


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


def evaluate(
    signal: Signal,
    policies: list[Policy],
    *,
    dry_run: bool = True,
    approve: bool = False,
    audit_path: Path | None = None,
) -> Decision:
    if is_killed():
        decision = Decision(
            status="blocked",
            policy_id=None,
            action=None,
            reason="global_kill_switch",
            idempotency_key="kill",
        )
        audit.append_event({"type": "decision", **decision.to_dict()}, audit_path)
        return decision

    policy = match_policy(signal, policies)
    if policy is None:
        decision = Decision(
            status="skipped",
            policy_id=None,
            action=None,
            reason="no_matching_policy",
            idempotency_key="none",
            details={"signal": signal.name},
        )
        audit.append_event({"type": "decision", **decision.to_dict()}, audit_path)
        return decision

    key = idempotency_key(signal, policy)
    state = _load_state()
    attempts = state.setdefault("attempts", {})
    record = attempts.get(key, {"count": 0, "last_ts": None})

    now = datetime.now(timezone.utc)
    if record.get("last_ts"):
        last = datetime.fromisoformat(record["last_ts"])
        delta = (now - last).total_seconds()
        if delta < policy.cooldown_seconds and record["count"] > 0:
            decision = Decision(
                status="blocked",
                policy_id=policy.id,
                action=policy.action,
                reason="cooldown_active",
                idempotency_key=key,
                details={"cooldown_seconds": policy.cooldown_seconds, "elapsed": delta},
            )
            audit.append_event({"type": "decision", **decision.to_dict()}, audit_path)
            return decision

    if record["count"] >= policy.max_attempts and not dry_run:
        decision = Decision(
            status="blocked",
            policy_id=policy.id,
            action=policy.action,
            reason="max_attempts_exceeded",
            idempotency_key=key,
            details={"max_attempts": policy.max_attempts},
        )
        audit.append_event({"type": "decision", **decision.to_dict()}, audit_path)
        return decision

    if policy.requires_approval and not approve and not dry_run:
        decision = Decision(
            status="blocked",
            policy_id=policy.id,
            action=policy.action,
            reason="human_approval_required",
            idempotency_key=key,
            details={"tenant_blast_radius": policy.tenant_blast_radius},
        )
        audit.append_event({"type": "decision", **decision.to_dict()}, audit_path)
        return decision

    try:
        fn = registry.get(policy.action)
    except KeyError as exc:
        decision = Decision(
            status="error",
            policy_id=policy.id,
            action=policy.action,
            reason=str(exc),
            idempotency_key=key,
        )
        audit.append_event({"type": "decision", **decision.to_dict()}, audit_path)
        return decision

    result = fn(signal, policy, dry_run)
    status = "dry_run" if dry_run else "executed"
    if isinstance(result, dict) and result.get("blocked"):
        status = "blocked"

    if not dry_run and status == "executed":
        record["count"] = int(record.get("count", 0)) + 1
        record["last_ts"] = now.isoformat()
        attempts[key] = record
        _save_state(state)

    decision = Decision(
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
    )
    audit.append_event({"type": "decision", **decision.to_dict()}, audit_path)
    return decision
