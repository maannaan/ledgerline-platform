from __future__ import annotations

import json
from pathlib import Path

from autopilot.engine import evaluate, load_policies
from autopilot.killswitch import disable, enable, is_killed
from autopilot.models import Signal

POLICIES = Path(__file__).resolve().parents[1] / "policies" / "staging.json"


def test_dry_run_rollback_proposal(tmp_path):
    disable()
    policies = load_policies(POLICIES)
    signal = Signal.from_dict(
        json.loads(
            (Path(__file__).resolve().parents[1] / "fixtures" / "deploy_health_failed.json").read_text()
        )
    )
    audit = tmp_path / "a.jsonl"
    d = evaluate(signal, policies, dry_run=True, audit_path=audit)
    assert d.status == "dry_run"
    assert d.action == "rollback_previous_deploy"
    assert audit.exists()


def test_restore_requires_approval_on_execute(tmp_path):
    disable()
    policies = load_policies(POLICIES)
    signal = Signal(
        name="data_corruption",
        environment="staging",
        service="api",
        attributes={"window": "t1"},
    )
    d = evaluate(signal, policies, dry_run=False, approve=False, audit_path=tmp_path / "b.jsonl")
    assert d.status == "blocked"
    assert d.reason == "human_approval_required"


def test_kill_switch_blocks(tmp_path):
    enable("test")
    try:
        assert is_killed()
        policies = load_policies(POLICIES)
        signal = Signal(name="cpu_high", environment="staging", service="api", value=99)
        d = evaluate(signal, policies, dry_run=True, audit_path=tmp_path / "c.jsonl")
        assert d.status == "blocked"
        assert d.reason == "global_kill_switch"
    finally:
        disable()


def test_cpu_below_threshold_skips(tmp_path):
    disable()
    policies = load_policies(POLICIES)
    signal = Signal(name="cpu_high", environment="staging", service="api", value=10)
    d = evaluate(signal, policies, dry_run=True, audit_path=tmp_path / "d.jsonl")
    assert d.status == "skipped"
