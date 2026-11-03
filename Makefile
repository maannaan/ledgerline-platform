ENV ?= staging
TENANT ?=
TIER ?= shared
AWS_REGION ?= ap-south-1
INFRA_DIR := infra/environments/$(ENV)

.PHONY: help platform-init platform-validate platform-plan platform-apply onboard tenant-list migrate-acme-local isolation-test deploy-staging rollback-staging obs-apply

help:
	@echo "Ledgerline platform targets"
	@echo "  make platform-init ENV=staging"
	@echo "  make platform-validate ENV=staging"
	@echo "  make platform-plan ENV=staging"
	@echo "  make platform-apply ENV=staging   # REQUIRES explicit APPROVE_APPLY=1"
	@echo "  make onboard TENANT=brightpath TIER=shared ENV=staging"
	@echo "  make onboard TENANT=delta TIER=dedicated ENV=staging"
	@echo "  make tenant-list ENV=staging"
	@echo "  make migrate-acme-local"
	@echo "  make isolation-test"

platform-init:
	cd $(INFRA_DIR) && terraform init

platform-validate:
	cd $(INFRA_DIR) && terraform fmt -recursive ../.. && terraform init -backend=false && terraform validate

platform-plan:
	cd $(INFRA_DIR) && terraform plan -input=false

platform-apply:
	@if [ "$(APPROVE_APPLY)" != "1" ]; then \
	  echo "Refusing apply. Re-run with APPROVE_APPLY=1 after billing alarms + cost approval."; \
	  exit 1; \
	fi
	cd $(INFRA_DIR) && terraform apply -input=false

onboard:
	@if [ -z "$(TENANT)" ]; then echo "TENANT is required"; exit 1; fi
	@if [ "$(TIER)" != "shared" ] && [ "$(TIER)" != "dedicated" ]; then echo "TIER must be shared|dedicated"; exit 1; fi
	./infra/scripts/onboard_tenant.sh "$(ENV)" "$(TENANT)" "$(TIER)"

tenant-list:
	./infra/scripts/tenant_list.sh "$(ENV)"

migrate-acme-local:
	./infra/scripts/migrate_acme_local.sh

isolation-test:
	docker compose exec -T \
	  -e DATABASE_URL=postgresql://admin:admin123@db:5432/ledgerline \
	  -e ADMIN_TOKEN -e API_KEY_PEPPER \
	  api python -m pytest

deploy-staging:
	./infra/scripts/deploy_staging.sh

rollback-staging:
	./infra/scripts/rollback_staging.sh

obs-apply:
	./observability/scripts/apply_cloudwatch.sh

ci-local:
	cd app && DATABASE_URL=$${DATABASE_URL:-postgresql://admin:admin123@127.0.0.1:5432/ledgerline} \
	  ADMIN_TOKEN=$${ADMIN_TOKEN:-ll_admin_lab_token_phase2} \
	  API_KEY_PEPPER=$${API_KEY_PEPPER:-ll_pepper_lab_phase2} \
	  python -m pytest
