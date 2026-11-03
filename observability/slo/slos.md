# Service Level Objectives

## SLO-1 Availability

- **Target:** 99.9% successful eligible requests per calendar month  
- **Eligible:** responses from ALB/API excluding `4xx` caused by client auth/validation errors  
- **Good:** non-5xx (and not timed-out) eligible requests  
- **Rationale:** Reasonable starting commitment for a small B2B SaaS; leaves ~43 minutes/month error budget  

## SLO-2 Latency (`/records`)

- **Target:** 95% of authenticated `/records` GET/POST requests complete in **&lt; 300 ms**  
- **Measurement:** `ledgerline_http_request_duration_seconds` histogram / ALB target response time  
- **Rationale:** Matches assessment load-test threshold (`p(95)&lt;300`)  

## SLO-3 Tenant isolation (hard objective)

- **Target:** Zero cross-tenant data exposure incidents  
- **Measurement:** automated isolation tests in CI + security findings  
- **Rationale:** Not an error-budget trade-off; any breach is sev-1  

## Observation windows

Until sustained production traffic exists, treat monthly SLOs as **proposed objectives** and report synthetic/load-test windows separately with sample size.
