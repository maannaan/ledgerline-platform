# Known Limitations

| Area | Limitation | Impact | Next step |
|------|------------|--------|-----------|
| Access logs | If a client sends `?token=`, uvicorn access log may record it (auth still 401) | Secret in log pipelines | Redact query strings / ALB access logs |
| Transport TLS | Staging ALB is **HTTP** until a domain + ACM cert is provided | Browser/client MITM on public ALB DNS | `docs/runbooks/enable-tls.md` + `acm_certificate_arn` |
| CI on GitHub | Workflow file ready; Actions green only after **your** first push | T4.1 not CLOUD_VERIFIED yet | `docs/GITHUB_FIRST_PUSH.md` |
| RLS | App-layer tenant filters only (no Postgres RLS yet) | Defense-in-depth gap | Optional harden |
| Autopilot | Scaffold only | No wow demo yet | Phase 7 after gate |
| Questionnaire | Partially answered | Delta pack incomplete | Update as controls land |
| Prod env | Production Terraform validated, **not applied** (cost gate) | No prod stack | Apply only if assessment needs it |
