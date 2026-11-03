# Runbook: Onboard a tenant

**Owner:** platform on-call  
**Environments:** `staging` | `production` (prod apply requires separate approval)  
**Tools:** `make onboard`, Terraform, Secrets Manager, bootstrap script

## Preconditions

- Approved ticket with: `tenant_id` (slug), `tier` (`shared`|`dedicated`), region (`ap-south-1`), retention, plan limits, owner email  
- Budget headroom checked (dedicated adds a full RDS + KMS key)  
- Caller can run AWS CLI in the target account/region

## Procedure

1. **Receive & validate metadata**
   - `tenant_id` unique, lowercase `[a-z0-9-]`, not reserved (`admin`, `shared`, …)
   - Dedicated only when contract requires own DB/KMS (e.g. Delta / Evergreen class)

2. **Record intent**
   ```bash
   cd /path/to/ledgerline-platform
   make onboard TENANT=<id> TIER=shared ENV=staging
   # or: TIER=dedicated
   ```
   This updates `infra/tenants/<env>.json` and `tenant.auto.tfvars.json`. It does **not** apply Terraform unless you set `APPROVE_APPLY=1`.

3. **Provision infrastructure**
   ```bash
   APPROVE_APPLY=1 make platform-apply ENV=staging
   ```
   - Shared: registry entry only (uses shared RDS + shared KMS)  
   - Dedicated: new RDS + KMS (+ optional notes in tfvars)

4. **Schema / connectivity**
   - Shared tenants: API `apply_schema` on startup already creates tables; no per-tenant schema.  
   - Dedicated: point a one-off task / migrate job at the dedicated `DATABASE_URL` (Secrets Manager / Terraform output) and confirm `/ready` path with that URL.

5. **Issue credentials (hashed at rest)**
   ```bash
   # From a trusted shell with ADMIN_TOKEN + API_KEY_PEPPER + DATABASE_URL for the target DB:
   # Prefer AUTO_GENERATE_KEYS or SEED_API_KEYS for lab; production: generate one key, show once.
   python app/bootstrap_auth.py
   ```
   Store only `key_hash` in DB. Deliver plaintext key via approved channel (1Password / encrypted ticket). **Never commit keys.**

6. **Isolation + smoke**
   ```bash
   # Negative: spoof X-Tenant-Id while using another tenant's Bearer → 403
   curl -s -o /dev/null -w "%{http_code}\n" -H "Authorization: Bearer <key>" \
     -H "X-Tenant-Id: other-tenant" "$BASE_URL/records"
   # Positive: list/create for the new tenant → 200/201
   make isolation-test   # local CI suite
   ```

7. **Activate**
   - Confirm tenant appears in `make tenant-list ENV=staging`
   - Note owner, date, tier, DB target in the ticket / audit log
   - Send endpoint + credential; mark ticket done

## Rollback

- Shared: revoke API key (`UPDATE api_keys SET revoked_at=now()`); remove from manifest + apply if needed  
- Dedicated: revoke keys; schedule RDS delete only after data retention approval (`skip_final_snapshot` false in prod)

## Verification checklist

- [ ] Tenant in registry  
- [ ] Auth works; cross-tenant denied  
- [ ] Dedicated resources exist only if tier=dedicated  
- [ ] No secrets in git  
