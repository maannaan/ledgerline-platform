from __future__ import annotations

import os
import subprocess
from pathlib import Path
from typing import Any

from autopilot.actions.registry import action
from autopilot.models import Policy, Signal

REPO = Path(__file__).resolve().parents[2]


@action("notify_only")
def notify_only(signal: Signal, policy: Policy, dry_run: bool) -> dict[str, Any]:
    msg = f"ALERT policy={policy.id} signal={signal.name} env={signal.environment}"
    return {"would_notify": msg} if dry_run else {"notified": msg}


@action("ecs_scale_within_cap")
def ecs_scale_within_cap(signal: Signal, policy: Policy, dry_run: bool) -> dict[str, Any]:
    desired = int(signal.attributes.get("desired_count", 2))
    cap = int(policy.max_capacity or 2)
    target = min(desired, cap)
    region = signal.attributes.get("aws_region", "ap-south-1")
    cluster = signal.attributes.get("cluster", "ll-staging-cluster")
    service = signal.attributes.get("ecs_service", "ll-staging-api")
    cmd = [
        "aws",
        "ecs",
        "update-service",
        "--region",
        region,
        "--cluster",
        cluster,
        "--service",
        service,
        "--desired-count",
        str(target),
    ]
    if dry_run:
        return {"would_run": cmd, "target_desired": target, "cap": cap}
    # Live scale only with explicit execute gate (never silent).
    if os.getenv("APPROVE_AUTOPILOT") != "1":
        return {"blocked": "APPROVE_AUTOPILOT=1 required for live scale", "would_run": cmd}
    subprocess.run(cmd, check=True)
    return {"ran": cmd, "target_desired": target}


@action("rollback_previous_deploy")
def rollback_previous_deploy(signal: Signal, policy: Policy, dry_run: bool) -> dict[str, Any]:
    script = REPO / "infra" / "scripts" / "rollback_staging.sh"
    if dry_run:
        return {"would_run": str(script), "note": "uses saved prior taskdef digest"}
    if os.getenv("APPROVE_AUTOPILOT") != "1":
        return {"blocked": "APPROVE_AUTOPILOT=1 required for live rollback", "would_run": str(script)}
    subprocess.run(["bash", str(script)], check=True, cwd=str(REPO))
    return {"ran": str(script)}


@action("shed_heavy_reports")
def shed_heavy_reports(signal: Signal, policy: Policy, dry_run: bool) -> dict[str, Any]:
    """
    Documented shed: rely on app HEAVY_REPORT_MAX_CONCURRENT already deployed.
    Autopilot records intent; does not mutate DB.
    """
    detail = {
        "mechanism": "HEAVY_REPORT_MAX_CONCURRENT + statement_timeout",
        "tenant_hint": signal.attributes.get("tenant", "cobalt"),
    }
    return {"would_shed": detail} if dry_run else {"shed_acknowledged": detail}


@action("db_restore")
def db_restore(signal: Signal, policy: Policy, dry_run: bool) -> dict[str, Any]:
    """Prohibited without human approval — never auto-executes."""
    return {
        "blocked": "db_restore requires human approval and APPROVE_RESTORE=1",
        "runbook": "docs/runbooks/database-restore.md",
        "dry_run": dry_run,
        "signal": signal.name,
    }
