# Runbook: Database restore

**Status:** Skeleton — complete after Phase 5 restore drill.

1. Declare incident; identify tenant/DB/region.  
2. Confirm restore point + approval.  
3. Restore to **new** isolated DB (do not overwrite first).  
4. Record start, end, recovery point (RTO/RPO).  
5. Validate schema, counts, app health.  
6. Controlled connection switch.  
7. Monitor; keep original for rollback/forensics.  
