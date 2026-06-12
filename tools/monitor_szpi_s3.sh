#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 /dev/cu.usbmodemXXXX"
  exit 1
fi

PORT="$1"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIRMWARE_DIR="${ROOT_DIR}/firmware/xiaozhi-esp32"
IDF_PATH="${IDF_PATH:-${HOME}/esp-idf}"
BUILD_DIR="${BUILD_DIR:-build-szpi-s3-local}"

cd "${FIRMWARE_DIR}"
source "${IDF_PATH}/export.sh"
idf.py -p "${PORT}" -B "${BUILD_DIR}" monitor
