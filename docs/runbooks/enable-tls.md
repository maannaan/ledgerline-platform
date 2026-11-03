# Enable TLS on staging ALB

ACM public certificates need a **domain you control**. Default ALB DNS (`*.elb.amazonaws.com`) cannot get a public ACM cert.

## Steps

1. Own a domain (Route 53 or external DNS).
2. Request ACM cert in **ap-south-1** (same region as the ALB):
   ```bash
   aws acm request-certificate \
     --region ap-south-1 \
     --domain-name api.staging.example.com \
     --validation-method DNS
   ```
3. Add the DNS validation CNAME ACM returns; wait until status `ISSUED`.
4. Point `api.staging.example.com` → ALB DNS (alias/CNAME).
5. Set in `infra/environments/staging/terraform.tfvars` (gitignored):
   ```hcl
   acm_certificate_arn = "arn:aws:acm:ap-south-1:ACCOUNT:certificate/ID"
   ```
6. Apply:
   ```bash
   cd infra/environments/staging && terraform apply
   ```
7. Confirm: `https://api.staging.example.com/ready` and HTTP redirects to HTTPS.

Until then, staging remains HTTP-only (honest limitation for assessment demos without a domain).
