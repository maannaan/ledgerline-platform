#!/usr/bin/env bash
# CI helper — keep pip flags out of workflow YAML (Sonar githubactions rules).
set -euo pipefail
cd "$(dirname "$0")"
pip install "--only-binary=:all:" -r requirements-dev.txt
