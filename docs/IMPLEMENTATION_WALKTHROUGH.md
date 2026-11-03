# Implementation Walkthrough

Skeleton for founder defense. Expand per major feature after implementation.

## Template per feature

- What it does  
- Why it exists  
- Files / functions  
- Request or data flow  
- Happy path  
- Failure path  
- Detection  
- Recovery  
- Tests / evidence  
- Alternatives considered  
- Limitations  

## Features (to fill)

| Feature | Status | Section |
|---------|--------|---------|
| Reference app baseline | Extracted + locally verified vulnerable | Phase 0–1 |
| Auth + tenant derivation | Bearer API key → `api_keys` hash → `Principal.tenant_id` (`auth.py`) | Phase 2 TESTED |
| Isolation tests | `app/tests/test_tenant_isolation.py` (10 tests) | Phase 2 TESTED |
| Terraform platform | NOT_STARTED | |
| Observability / SLOs | NOT_STARTED | |
| Backup / restore | NOT_STARTED | |
| Reliability Autopilot | NOT_STARTED | |
