#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
pip install "--only-binary=:all:" pip-audit==2.7.3
pip-audit -r requirements.txt --progress-spinner off
