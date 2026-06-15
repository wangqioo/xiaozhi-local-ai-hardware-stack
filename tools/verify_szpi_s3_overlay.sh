#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tools/local_env.sh
source "${SCRIPT_DIR}/local_env.sh"

ROOT_DIR="$(resolve_root_dir)"
MANIFEST_FILE="${ROOT_DIR}/firmware/overlays/szpi-s3/manifest.env"
CMAKE_FILE="${ROOT_DIR}/firmware/xiaozhi-esp32/main/CMakeLists.txt"
KCONFIG_FILE="${ROOT_DIR}/firmware/xiaozhi-esp32/main/Kconfig.projbuild"
RENDER="${SCRIPT_DIR}/render_local_config.sh"

failures=0

print_check() {
  local status="$1"
  local name="$2"
  local detail="$3"
  printf '%-4s %s - %s\n' "$status" "$name" "$detail"
}

pass() {
  print_check "PASS" "$1" "$2"
}

fail() {
  failures=$((failures + 1))
  print_check "FAIL" "$1" "$2"
}

require_file() {
  local file="$1"
  local label="$2"
  if [[ -f "$file" ]]; then
    pass "$label" "$file"
  else
    fail "$label" "missing $file"
  fi
}

require_text() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  local detail="$4"
  if grep -Fq -- "$pattern" "$file"; then
    pass "$label" "$detail"
  else
    fail "$label" "missing ${pattern} in ${file}"
  fi
}

check_manifest() {
  if [[ ! -f "${MANIFEST_FILE}" ]]; then
    fail "manifest" "missing ${MANIFEST_FILE}"
    return
  fi

  # shellcheck disable=SC1090
  source "${MANIFEST_FILE}"

  local required=(
    BOARD_TYPE
    KCONFIG_SYMBOL
    KCONFIG_NAME
    IDF_TARGET
    BOARD_DIR
    BOARD_SOURCE
    CONFIG_HEADER
    CONFIG_JSON
    CMAKE_TEXT_FONT
    CMAKE_ICON_FONT
    CMAKE_EMOJI_COLLECTION
    REQUIRES_DEVICE_AEC
  )
  local missing=()
  local name
  for name in "${required[@]}"; do
    if [[ -z "${!name:-}" ]]; then
      missing+=("$name")
    fi
  done

  if [[ "${#missing[@]}" -gt 0 ]]; then
    fail "manifest" "missing values: ${missing[*]}"
  else
    pass "manifest" "${MANIFEST_FILE}"
  fi
}

check_board_files() {
  local board_path="${ROOT_DIR}/${BOARD_DIR}"
  local missing=()
  local file
  for file in "${CONFIG_HEADER}" "${CONFIG_JSON}" "${BOARD_SOURCE}" "README.md"; do
    if [[ ! -f "${board_path}/${file}" ]]; then
      missing+=("${file}")
    fi
  done

  if [[ "${#missing[@]}" -gt 0 ]]; then
    fail "board files" "missing in ${board_path}: ${missing[*]}"
  else
    pass "board files" "${board_path}"
  fi
}

check_cmake_registration() {
  require_file "${CMAKE_FILE}" "cmake file"
  if [[ ! -f "${CMAKE_FILE}" ]]; then
    return
  fi

  local cmake_symbol="${KCONFIG_SYMBOL#CONFIG_}"
  local board_line="set(BOARD_TYPE \"${BOARD_TYPE}\")"
  local text_font_line="set(BUILTIN_TEXT_FONT ${CMAKE_TEXT_FONT})"
  local icon_font_line="set(BUILTIN_ICON_FONT ${CMAKE_ICON_FONT})"
  local emoji_line="set(DEFAULT_EMOJI_COLLECTION ${CMAKE_EMOJI_COLLECTION})"

  if grep -Fq "elseif(CONFIG_${cmake_symbol})" "${CMAKE_FILE}" \
    && grep -Fq "${board_line}" "${CMAKE_FILE}" \
    && grep -Fq "${text_font_line}" "${CMAKE_FILE}" \
    && grep -Fq "${icon_font_line}" "${CMAKE_FILE}" \
    && grep -Fq "${emoji_line}" "${CMAKE_FILE}"; then
    pass "cmake registration" "${KCONFIG_SYMBOL} -> ${BOARD_TYPE}"
  else
    fail "cmake registration" "missing ${KCONFIG_SYMBOL} board branch details"
  fi
}

check_kconfig_registration() {
  require_file "${KCONFIG_FILE}" "kconfig file"
  if [[ ! -f "${KCONFIG_FILE}" ]]; then
    return
  fi

  if grep -Fq "config ${KCONFIG_NAME}" "${KCONFIG_FILE}" \
    && grep -Fq "depends on IDF_TARGET_ESP32S3" "${KCONFIG_FILE}"; then
    pass "kconfig registration" "${KCONFIG_NAME}"
  else
    fail "kconfig registration" "missing ${KCONFIG_NAME} with ESP32-S3 dependency"
  fi
}

check_device_aec_dependency() {
  if [[ "${REQUIRES_DEVICE_AEC}" != "y" ]]; then
    pass "device AEC dependency" "not required"
    return
  fi

  if grep -Fq "|| ${KCONFIG_NAME}" "${KCONFIG_FILE}"; then
    pass "device AEC dependency" "${KCONFIG_NAME}"
  else
    fail "device AEC dependency" "${KCONFIG_NAME} not included in USE_DEVICE_AEC dependency list"
  fi
}

check_board_config_json() {
  local config_json="${ROOT_DIR}/${BOARD_DIR}/${CONFIG_JSON}"
  require_file "${config_json}" "board config.json file"
  if [[ ! -f "${config_json}" ]]; then
    return
  fi

  if grep -Fq "\"target\": \"${IDF_TARGET}\"" "${config_json}" \
    && grep -Fq "\"name\": \"${BOARD_TYPE}\"" "${config_json}" \
    && grep -Fq "\"CONFIG_USE_DEVICE_AEC=y\"" "${config_json}"; then
    pass "board config.json" "${CONFIG_JSON}"
  else
    fail "board config.json" "target/build name/sdkconfig_append do not match manifest"
  fi
}

check_firmware_defaults() {
  local tmp defaults
  tmp="$(mktemp -d)"
  defaults="${tmp}/sdkconfig.defaults"

  LAN_IP=10.0.0.99 XIAOZHI_STACK_ROOT="${ROOT_DIR}" bash "${RENDER}" --firmware-defaults "${defaults}" >/dev/null

  if grep -Fq "CONFIG_IDF_TARGET=\"${IDF_TARGET}\"" "${defaults}" \
    && grep -Fq "${KCONFIG_SYMBOL}=y" "${defaults}" \
    && grep -Fq "CONFIG_USE_DEVICE_AEC=y" "${defaults}" \
    && grep -Fq 'CONFIG_OTA_URL="http://10.0.0.99:8003/xiaozhi/ota/"' "${defaults}"; then
    pass "firmware defaults" "${defaults}"
  else
    fail "firmware defaults" "generated defaults do not match manifest"
  fi
}

echo "SZPI-S3 overlay verify"
echo "Root: ${ROOT_DIR}"
echo

check_manifest
if [[ -f "${MANIFEST_FILE}" ]]; then
  check_board_files
  check_cmake_registration
  check_kconfig_registration
  check_device_aec_dependency
  check_board_config_json
  check_firmware_defaults
fi

echo
if [[ "${failures}" -gt 0 ]]; then
  echo "SZPI-S3 overlay verify: failed (${failures} failure(s))"
  exit 1
fi

echo "SZPI-S3 overlay verify: ok"
