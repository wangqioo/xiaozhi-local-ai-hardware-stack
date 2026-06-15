#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: LAN_IP=192.168.1.26 $0 /dev/cu.usbmodemXXXX"
  exit 1
fi

PORT="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tools/local_env.sh
source "${SCRIPT_DIR}/local_env.sh"

ROOT_DIR="$(resolve_root_dir)"
init_stack_facts "${ROOT_DIR}"
FIRMWARE_DIR="${ROOT_DIR}/firmware/xiaozhi-esp32"
IDF_PATH="${IDF_PATH:-${HOME}/esp-idf}"
BUILD_DIR="${BUILD_DIR:-build-szpi-s3-local}"
SDKCONFIG_FILE="/tmp/xiaozhi-sdkconfig-szpi-s3-local"
LOCAL_DEFAULTS="/tmp/xiaozhi-sdkconfig-szpi-s3-local.defaults"

if [[ -f "${XIAOZHI_LOCAL_ENV_FILE}" ]]; then
  load_local_env "${ROOT_DIR}"
else
  XIAOZHI_LAN_IP="${LAN_IP:-192.168.1.26}"
  XIAOZHI_HTTP_PORT="${XIAOZHI_HTTP_PORT:-8003}"
  XIAOZHI_WS_PORT="${XIAOZHI_WS_PORT:-8001}"
fi

LAN_IP="${LAN_IP:-${XIAOZHI_LAN_IP}}"
XIAOZHI_LAN_IP="${LAN_IP}"
export XIAOZHI_LAN_IP XIAOZHI_HTTP_PORT XIAOZHI_WS_PORT
"${SCRIPT_DIR}/render_local_config.sh" --firmware-defaults "${LOCAL_DEFAULTS}" >/dev/null

ensure_xtensa_esp32s3_toolchain() {
  if command -v xtensa-esp32s3-elf-gcc >/dev/null 2>&1; then
    return 0
  fi

  local idf_tools_root="${IDF_TOOLS_PATH:-${HOME}/.espressif}/tools"
  local toolchain_bin
  toolchain_bin="$(find "${idf_tools_root}/xtensa-esp-elf" -path '*/xtensa-esp-elf/bin/xtensa-esp32s3-elf-gcc' -type f 2>/dev/null | sort | tail -n 1)"
  if [[ -n "${toolchain_bin}" ]]; then
    PATH="$(dirname "${toolchain_bin}"):${PATH}"
    export PATH
  fi
}

cd "${FIRMWARE_DIR}"
source "${IDF_PATH}/export.sh"
ensure_xtensa_esp32s3_toolchain
idf.py -p "${PORT}" \
  -B "${BUILD_DIR}" \
  -DSDKCONFIG="${SDKCONFIG_FILE}" \
  -DSDKCONFIG_DEFAULTS="sdkconfig.defaults;sdkconfig.defaults.esp32s3;${LOCAL_DEFAULTS}" \
  build flash
