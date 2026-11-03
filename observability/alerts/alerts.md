# Alerts (≥3, SLO-tied)

## A1 — Availability burn (5xx)

- **Signal:** ALB HTTPCode_Target_5XX_Count / request count  
- **Condition:** &gt;1% 5xx for 5 minutes  
- **Why:** Protects availability SLO before full budget burn  
- **Notify:** email `mananpaliwal30@gmail.com` (SNS)  

## A2 — Latency SLO risk (`/records` / target response)

- **Signal:** ALB TargetResponseTime p95 (or CloudWatch extended statistic)  
- **Condition:** p95 &gt; 0.3s for 10 minutes  
- **Why:** Matches latency SLO / load-test gate  
- **Notify:** same SNS  

## A3 — Database / dependency saturation

- **Signal:** ECS RunningTaskCount &lt; Desired, OR UnHealthyHostCount ≥ 1 for 5 minutes  
- **Why:** Catches dependency/task failure before total outage  
- **Notify:** same SNS  

## Noise control

- No overnight paging for single-point spikes; use multi-minute windows.
- Exclude intentional canary/load-test periods via annotation in incident notes.
