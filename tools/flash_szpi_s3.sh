#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: LAN_IP=192.168.1.26 $0 /dev/cu.usbmodemXXXX"
  exit 1
fi

PORT="$1"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIRMWARE_DIR="${ROOT_DIR}/firmware/xiaozhi-esp32"
IDF_PATH="${IDF_PATH:-${HOME}/esp-idf}"
LAN_IP="${LAN_IP:-192.168.1.26}"
BUILD_DIR="${BUILD_DIR:-build-szpi-s3-local}"
SDKCONFIG_FILE="/tmp/xiaozhi-sdkconfig-szpi-s3-local"
LOCAL_DEFAULTS="/tmp/xiaozhi-sdkconfig-szpi-s3-local.defaults"

cat > "${LOCAL_DEFAULTS}" <<EOF
CONFIG_IDF_TARGET="esp32s3"
CONFIG_BOARD_TYPE_SZPI_S3=y
CONFIG_OTA_URL="http://${LAN_IP}:8003/xiaozhi/ota/"
CONFIG_USE_DEVICE_AEC=y
EOF

cd "${FIRMWARE_DIR}"
source "${IDF_PATH}/export.sh"
idf.py -p "${PORT}" \
  -B "${BUILD_DIR}" \
  -DSDKCONFIG="${SDKCONFIG_FILE}" \
  -DSDKCONFIG_DEFAULTS="sdkconfig.defaults;sdkconfig.defaults.esp32s3;${LOCAL_DEFAULTS}" \
  build flash
