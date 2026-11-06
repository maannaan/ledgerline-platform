#!/usr/bin/env bash
# Compatibility wrapper → deploy_env.sh staging
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TAG="${GIT_SHA:-$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo manual)}"
exec "$ROOT/infra/scripts/deploy_env.sh" staging "$TAG"
