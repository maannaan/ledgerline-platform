# Runbook: Onboard a tenant

**Status:** Skeleton — implement with real commands in Phase 3/6.

1. Receive approved tenant metadata (id, tier, region, limits).  
2. Validate uniqueness and tier requirements.  
3. Run onboarding command for environment.  
4. Provision DB/key/secrets per tier.  
5. Migrate schema; connectivity check.  
6. Issue credentials via secure channel (never commit).  
7. Run isolation + smoke tests.  
8. Activate tenant; audit event.  
