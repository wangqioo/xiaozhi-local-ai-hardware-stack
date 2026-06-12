#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVER_ROOT="${ROOT_DIR}/server/xiaozhi-esp32-server"
SERVER_DIR="${SERVER_ROOT}/main/xiaozhi-server"
CONFIG_FILE="${SERVER_ROOT}/data/.config.yaml"
EXAMPLE_FILE="${SERVER_ROOT}/data/.config.example.yaml"
ENV_NAME="${XIAOZHI_CONDA_ENV:-xiaozhi-esp32-server}"

if [[ ! -f "${CONFIG_FILE}" ]]; then
  echo "Missing ${CONFIG_FILE}"
  echo "Create it from ${EXAMPLE_FILE} and fill in LAN IP, device MAC and API keys."
  exit 1
fi

if [[ ! -e "${SERVER_DIR}/data" ]]; then
  ln -s ../../data "${SERVER_DIR}/data"
fi

cd "${SERVER_DIR}"
exec conda run --no-capture-output -n "${ENV_NAME}" python app.py
