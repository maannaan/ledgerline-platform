# First push to GitHub (you run these — agent does not commit/push)

Repo: https://github.com/maannaan/ledgerline-platform.git  
Local root: `/Users/apple/Desktop/Manan/ledgerline-platform`  
Do **not** run git from `/Users/apple` (that is a different repo).

## One-time remote

```bash
cd /Users/apple/Desktop/Manan/ledgerline-platform
git remote remove origin 2>/dev/null || true
git remote add origin https://github.com/maannaan/ledgerline-platform.git
git remote -v
```

## Stage safe files only

Secrets stay out via `.gitignore` (`.env`, `.cloud-lab-keys`, `*.tfvars`, tfstate, etc.).

```bash
cd /Users/apple/Desktop/Manan/ledgerline-platform

git add \
  .env.example .gitignore .github AGENTS.md Makefile README.md SECURITY.md \
  app assessment autopilot docker-compose.yml docs infra loadtest observability

# Optional Cursor rules for the assessment:
git add .cursor/rules 2>/dev/null || true

git status
# Confirm NOTHING secrets-like is staged (.env, tfvars, keys, tfstate).
```

## Commit + push (your message / your push)

```bash
git branch -M main
git commit -m "$(cat <<'EOF'
Initial Ledgerline platform: secure API, staging IaC, CI, observability.

EOF
)"
git push -u origin main
```

If GitHub already has a README-only first commit, use:

```bash
git pull origin main --rebase
git push -u origin main
```

## After push

1. Open **Actions** on the repo — workflow `ci` should run (pytest, pip-audit, Trivy, terraform validate).
2. Confirm SNS email for CloudWatch alarms if not already.
3. Paste a green Actions URL into `docs/evidence/phase4/` when CI passes (marks T4.1 CLOUD_VERIFIED).
