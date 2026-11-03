# Reliability Autopilot

**Differentiator** (not PDF-scored). Deterministic detect → policy → allowlisted action → verify/audit.  
No LLM executes production changes.

## Safety

| Control | How |
|---------|-----|
| Allowlist | Only actions in `actions/builtins.py` |
| Dry-run | Default; `--execute` optional |
| Kill switch | `python -m autopilot.cli kill` or `AUTOPILOT_KILL_SWITCH=1` |
| Approval | `requires_approval` policies need `--approve`; cloud needs `APPROVE_AUTOPILOT=1` |
| Caps | `max_capacity`, `max_attempts`, `cooldown_seconds` |
| Audit | Append-only `audit/events.jsonl` |
| Native first | ECS circuit breaker / task replace preferred; Autopilot proposes bounded extras |

## Quick demo (no cloud writes)

```bash
make autopilot-demo
# or:
./autopilot/demo.sh
```

## CLI

```bash
PYTHONPATH=. python3 -m autopilot.cli status
PYTHONPATH=. python3 -m autopilot.cli eval --signal autopilot/fixtures/cpu_high.json
PYTHONPATH=. python3 -m autopilot.cli eval --signal autopilot/fixtures/data_corruption.json --execute
PYTHONPATH=. python3 -m autopilot.cli kill --reason "pause"
PYTHONPATH=. python3 -m autopilot.cli kill --off
PYTHONPATH=. python3 -m autopilot.cli audit --limit 20
```

## Tests

```bash
PYTHONPATH=. python3 -m pytest autopilot/tests -q
```

## Positioning for founders

> Small policy-driven remediation layer. We chose deterministic allowlists over an autonomous agent because tenant data and restores must stay auditable and human-gated.
