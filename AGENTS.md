# AGENTS.md — Ledgerline Platform (Predixion Assessment)

Instructions for every future Agent session on this repository.

## Before doing any work

1. Read [`assessment/CURRENT_STATE.md`](assessment/CURRENT_STATE.md) first.
2. Read only the relevant requirement IDs in [`assessment/REQUIREMENTS_MATRIX.md`](assessment/REQUIREMENTS_MATRIX.md).
3. Read relevant sections of [`assessment/SOURCE_OF_TRUTH.md`](assessment/SOURCE_OF_TRUTH.md) — do not re-summarize the entire assessment.
4. Preserve decisions in [`assessment/DECISION_LOG.md`](assessment/DECISION_LOG.md).

## Source priority

1. Original PDF: `assessment/source/Founding Engineer 1-Week Live Assessment.pdf`
2. Playbook: `assessment/source/ledgerline_assessment_cursor_playbook.html`
3. Actual source code and evidence in this repo
4. Candidate enhancements (e.g. Reliability Autopilot) — never silently override PDF requirements

If PDF and playbook disagree, follow the PDF and document the discrepancy.

## Operating rules

- Inspect only relevant files; do not re-read the whole repository by default.
- Do not invent completed features, test results, or cloud evidence.
- Status labels: `NOT_STARTED | IN_PROGRESS | IMPLEMENTED | TESTED | CLOUD_VERIFIED | BLOCKED | DEFERRED`.
- Never mark `TESTED` or `CLOUD_VERIFIED` without saved evidence.
- Update `CURRENT_STATE.md`, matrix statuses, and founder docs after meaningful work.
- Ask before destructive or billable actions (`terraform apply/destroy`, prod load tests, IAM broadening, public exposure).
- Do not commit secrets, `.env`, keys, Terraform state with secrets, or real customer data.
- Git root must be this project directory — never commit from a parent/home git repo.
- Reliability Autopilot is a differentiator only after core security/reliability evidence is credible.

## Response format after implementation tasks

Use: Current task → Changes made → Verification → Assessment status → Persistent context updated → Founder readiness → Risks/blockers → Next action.
