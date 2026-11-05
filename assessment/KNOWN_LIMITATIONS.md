# Known Limitations

| Area | Limitation | Impact | Next step |
|------|------------|--------|-----------|
| Access logs | If a client sends `?token=`, uvicorn access log may record it (auth still 401) | Secret in log pipelines | Redact query strings / ALB access logs |
| Transport TLS | Staging ALB is **HTTP** until a domain + ACM cert is provided | Browser/client MITM on public ALB DNS | `docs/runbooks/enable-tls.md` + `acm_certificate_arn` |
| Load SLO | Lean idle size (256/512 ×1) cannot hold 200 RPS SLO; **demo profile 512/1024 ×2 PASSes** (p95 131ms) | Must size for peak or accept lean degradation | Keep lean for cost; scale up for demos/load |
| RLS | App-layer tenant filters only (no Postgres RLS yet) | Defense-in-depth gap | Optional harden |
| Autopilot | Deterministic CLI Autopilot shipped (dry-run, kill switch, audit); live AWS actions need `APPROVE_AUTOPILOT=1` | Not a always-on Lambda remediator | Demo via `make autopilot-demo` |
| Questionnaire | Answers updated to staging reality (2026-11-05) | TLS/MFA/SOC still honest gaps | Keep in sync after control changes |
| Prod env | Production Terraform validated, **not applied** (cost gate) | No prod stack | Apply only if assessment needs it |
| Stretch S1–S5 | Multi-region, cost attribution, policy-as-code, secret rotation, Fjord 10x | Deferred | After core demos |
