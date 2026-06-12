#!/usr/bin/env bash
set -euo pipefail

for port in 8001 8003; do
  echo "== TCP :${port} =="
  if command -v lsof >/dev/null 2>&1; then
    lsof -nP -iTCP:"${port}" -sTCP:LISTEN || true
  else
    echo "lsof not found"
  fi
done
