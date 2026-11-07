ENV ?= staging
TENANT ?=
TIER ?= shared
AWS_REGION ?= ap-south-1
INFRA_DIR := infra/environments/$(ENV)

IMAGE_TAG ?=
.PHONY: help platform-init platform-validate platform-plan platform-apply onboard tenant-list migrate-acme-local isolation-test deploy-staging rollback-staging deploy-env rollback-env obs-apply restore-drill load-baseline load-noisy load-smoke autopilot-demo autopilot-test autopilot-status

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
	@echo "  make deploy-env ENV=staging IMAGE_TAG=<tag>"
	@echo "  make rollback-env ENV=staging IMAGE_TAG=<tag>"
	@echo "  make restore-drill          # REQUIRES APPROVE_RESTORE=1"
	@echo "  make load-smoke / load-baseline / load-noisy  # needs BASE_URL TENANTS"
	@echo "  make autopilot-demo / autopilot-test / autopilot-status"

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
	cd $(INFRA_DIR) && terraform apply -input=false -auto-approve

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

deploy-env:
	@test -n "$(IMAGE_TAG)" || (echo "IMAGE_TAG required"; exit 1)
	./infra/scripts/deploy_env.sh "$(ENV)" "$(IMAGE_TAG)"

rollback-env:
	@test -n "$(IMAGE_TAG)" || (echo "IMAGE_TAG required"; exit 1)
	./infra/scripts/rollback_env.sh "$(ENV)" "$(IMAGE_TAG)"

obs-apply:
	./observability/scripts/apply_cloudwatch.sh

restore-drill:
	APPROVE_RESTORE=$(APPROVE_RESTORE) ./infra/scripts/restore_rds_drill.sh

load-smoke:
	@test -n "$(BASE_URL)" || (echo "BASE_URL required"; exit 1)
	@test -n "$(TENANTS)" || (echo "TENANTS required"; exit 1)
	mkdir -p loadtest/results
	k6 run -e BASE_URL="$(BASE_URL)" -e TENANTS="$(TENANTS)" -e RATE=20 -e DURATION=30s \
	  --summary-export=loadtest/results/smoke-summary.json loadtest/load.js

load-baseline:
	@test -n "$(BASE_URL)" || (echo "BASE_URL required"; exit 1)
	@test -n "$(TENANTS)" || (echo "TENANTS required"; exit 1)
	mkdir -p loadtest/results
	k6 run -e BASE_URL="$(BASE_URL)" -e TENANTS="$(TENANTS)" -e RATE=$${RATE:-200} -e DURATION=$${DURATION:-10m} \
	  --summary-export=loadtest/results/baseline-summary.json loadtest/load.js

load-noisy:
	@test -n "$(BASE_URL)" || (echo "BASE_URL required"; exit 1)
	@test -n "$(TENANTS)" || (echo "TENANTS required"; exit 1)
	@test -n "$(NOISY_KEY)" || (echo "NOISY_KEY (cobalt) required"; exit 1)
	mkdir -p loadtest/results
	k6 run -e BASE_URL="$(BASE_URL)" -e TENANTS="$(TENANTS)" -e NOISY=1 -e NOISY_KEY="$(NOISY_KEY)" \
	  -e RATE=$${RATE:-200} -e DURATION=$${DURATION:-10m} \
	  --summary-export=loadtest/results/noisy-summary.json loadtest/load.js

ci-local:
	cd app && DATABASE_URL=$${DATABASE_URL:-postgresql://admin:admin123@127.0.0.1:5432/ledgerline} \
	  ADMIN_TOKEN=$${ADMIN_TOKEN:-ll_admin_lab_token_phase2} \
	  API_KEY_PEPPER=$${API_KEY_PEPPER:-ll_pepper_lab_phase2} \
	  python -m pytest

autopilot-demo:
	chmod +x autopilot/demo.sh
	./autopilot/demo.sh

autopilot-test:
	PYTHONPATH=. python3 -m pytest autopilot/tests -q

autopilot-status:
	PYTHONPATH=. python3 -m autopilot.cli status
