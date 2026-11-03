#!/usr/bin/env python3
"""CLI for Reliability Autopilot."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from autopilot.audit import logger as audit
from autopilot.engine import evaluate, load_policies
from autopilot.killswitch import disable as ks_disable
from autopilot.killswitch import enable as ks_enable
from autopilot.killswitch import status as ks_status
from autopilot.models import Signal


def cmd_status(_: argparse.Namespace) -> int:
    print(json.dumps({"kill_switch": ks_status(), "actions_note": "allowlisted only"}, indent=2))
    return 0


def cmd_kill(args: argparse.Namespace) -> int:
    if args.off:
        ks_disable()
        print(json.dumps({"kill_switch": "off"}))
    else:
        ks_enable(args.reason or "cli")
        print(json.dumps({"kill_switch": "on", "reason": args.reason or "cli"}))
    return 0


def cmd_eval(args: argparse.Namespace) -> int:
    signal_data = json.loads(Path(args.signal).read_text(encoding="utf-8"))
    signal = Signal.from_dict(signal_data)
    policies = load_policies(Path(args.policies) if args.policies else None)
    decision = evaluate(
        signal,
        policies,
        dry_run=not args.execute,
        approve=args.approve,
    )
    print(json.dumps(decision.to_dict(), indent=2))
    return 0 if decision.status in {"dry_run", "executed", "skipped"} else 2


def cmd_audit(args: argparse.Namespace) -> int:
    events = audit.read_events(limit=args.limit)
    print(json.dumps(events, indent=2))
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="autopilot", description="Ledgerline Reliability Autopilot")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_status = sub.add_parser("status", help="Show kill switch / health")
    p_status.set_defaults(func=cmd_status)

    p_kill = sub.add_parser("kill", help="Toggle global kill switch")
    p_kill.add_argument("--off", action="store_true", help="Disable kill switch")
    p_kill.add_argument("--reason", default="manual")
    p_kill.set_defaults(func=cmd_kill)

    p_eval = sub.add_parser("eval", help="Evaluate a signal JSON file")
    p_eval.add_argument("--signal", required=True, help="Path to signal JSON")
    p_eval.add_argument("--policies", help="Policy pack JSON (default staging)")
    p_eval.add_argument(
        "--execute",
        action="store_true",
        help="Execute allowlisted action (still needs APPROVE_AUTOPILOT for cloud)",
    )
    p_eval.add_argument("--approve", action="store_true", help="Human approval for risky policies")
    p_eval.set_defaults(func=cmd_eval)

    p_audit = sub.add_parser("audit", help="Show recent audit events")
    p_audit.add_argument("--limit", type=int, default=20)
    p_audit.set_defaults(func=cmd_audit)

    args = parser.parse_args(argv)
    return int(args.func(args))


if __name__ == "__main__":
    raise SystemExit(main())
