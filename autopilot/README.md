# Reliability Autopilot

Candidate differentiator — **not** a PDF core requirement.

Build only after isolation tests pass and restore/load path is designed.

## Safety rules

- Deterministic policies only  
- Allowlisted actions  
- Cooldowns + max retries  
- Idempotency  
- Dry-run mode  
- Global kill switch  
- Audit log + post-action verification  
- Human approval for risky/destructive ops  
- No unrestricted LLM production changes  

## Layout

- `policies/` — YAML policy pack  
- `actions/` — allowlisted executors  
- `audit/` — append-only event records (local/dev path)  
