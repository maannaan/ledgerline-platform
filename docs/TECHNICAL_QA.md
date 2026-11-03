# Technical Q&A (founder prep)

Add five likely questions after each major phase. Do not invent answers for unfinished work.

## Phase 0

**Q1: Why keep the FastAPI app instead of rewriting?**  
A: PDF allows rewrite if endpoints behave the same. Keeping FastAPI maximizes time for isolation, IaC, restore, and evidence — what founders score most.

**Q2: Why is the app still insecure after Phase 0?**  
A: Phase 0 only extracts and documents. Fixes start Phase 2 so we can show before/after and tests.

**Q3: What is Reliability Autopilot?**  
A: Optional differentiator: deterministic policies, allowlisted actions, dry-run, kill switch, audit. Not an LLM with cloud credentials. Built after core gates.

**Q4: What is your cloud spend plan?**  
A: ~3–4 day window, target ~$25–40 against ~$170 credits, soft max $75. Billing alarms before apply.

**Q5: Where is the source of truth?**  
A: Assessment PDF first, then playbook, then this repo’s evidence. Discrepancies go in DECISION_LOG.

## Phase 1

**Q1: How do you know the flaws are real?**  
A: Live curls in `docs/evidence/phase1/baseline-smoke.txt` — including SQL injection returning Brightpath rows under an Acme header.

**Q2: Why seed 20k Acme records already?**  
A: PDF seed path; needed for migration/load later. Cobalt 5k seeded for heavy-report tests.

**Q3: Did you change security in Phase 1?**  
A: No application security fixes. Only Compose DB healthcheck so the baseline boots reliably.

**Q4: What is the single worst finding?**  
A: Search SQL injection that returns **all tenants'** data — confidentiality break, not just missing auth.

**Q5: What would you fix first on Monday?**  
A: Auth + parameterized tenant-scoped queries + isolation tests (Phase 2).

## Phase 2

**Q1: Where does tenant identity come from?**  
A: Only from the authenticated API key row (`tenant_id`). Never from `X-Tenant-Id`.

**Q2: What happens if I send Acme’s key with `X-Tenant-Id: brightpath`?**  
A: HTTP 403 — mismatch rejected.

**Q3: How are API keys stored?**  
A: Peppered SHA-256 hashes in `api_keys`. Plaintext shown once at bootstrap; lab values in gitignored `.env`.

**Q4: How do you prove isolation?**  
A: `pytest` negative suite + saved live curls in `docs/evidence/phase2/`.

**Q5: What’s still weak?**  
A: No cloud Secrets Manager/TLS yet; container root; access logs can echo query-string tokens if clients misuse the API.
