#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLASH="${REPO_ROOT}/tools/flash_szpi_s3.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_contains() {
  local file="$1"
  local expected="$2"
  if ! grep -Fq -- "$expected" "$file"; then
    echo "Expected to find: $expected" >&2
    echo "--- ${file} ---" >&2
    cat "$file" >&2
    fail "missing expected text"
  fi
}

make_fixture() {
  local root="$1"
  mkdir -p "${root}/firmware/xiaozhi-esp32"
  mkdir -p "${root}/server/xiaozhi-esp32-server/data"
  cp "${REPO_ROOT}/server/xiaozhi-esp32-server/data/.config.example.yaml" \
    "${root}/server/xiaozhi-esp32-server/data/.config.example.yaml"
  cp -R "${REPO_ROOT}/tools" "${root}/tools"
  cat > "${root}/.local.env" <<'ENV'
XIAOZHI_LAN_IP=10.0.0.42
XIAOZHI_DEVICE_MAC=22:33:44:55:66:77
XIAOZHI_GLM_API_KEY=testglmkey1234567890.secretpart123456
XIAOZHI_WS_PORT=18001
XIAOZHI_HTTP_PORT=18003
ENV
}

make_fake_idf() {
  local fake_idf="$1"
  local fake_bin="$2"
  local log_file="$3"
  mkdir -p "$fake_idf" "$fake_bin"
  cat > "${fake_idf}/export.sh" <<'EXPORT'
export IDF_FAKE_EXPORTED=1
if [[ -n "${IDF_TOOLS_PATH:-}" ]]; then
  export PATH="${IDF_TOOLS_PATH}/tools/riscv32-esp-elf/esp-14.2.0_20260121/riscv32-esp-elf/bin:${PATH}"
fi
EXPORT
  cat > "${fake_bin}/idf.py" <<'IDFPY'
#!/usr/bin/env bash
printf 'XTENSA=%s\n' "$(command -v xtensa-esp32s3-elf-gcc || true)" > "${IDF_FAKE_LOG}"
printf '%s\n' "$@" >> "${IDF_FAKE_LOG}"
exit 0
IDFPY
  chmod +x "${fake_bin}/idf.py"
  export IDF_FAKE_LOG="$log_file"
}

make_fake_idf_toolchains() {
  local idf_tools_path="$1"
  local version="esp-14.2.0_20260121"
  local riscv_bin="${idf_tools_path}/tools/riscv32-esp-elf/${version}/riscv32-esp-elf/bin"
  local xtensa_bin="${idf_tools_path}/tools/xtensa-esp-elf/${version}/xtensa-esp-elf/bin"
  mkdir -p "$riscv_bin" "$xtensa_bin"

  cat > "${riscv_bin}/riscv32-esp-elf-gcc" <<'FAKE_RISCV'
#!/usr/bin/env bash
echo "fake riscv toolchain"
FAKE_RISCV
  cat > "${xtensa_bin}/xtensa-esp32s3-elf-gcc" <<'FAKE_XTENSA'
#!/usr/bin/env bash
echo "fake xtensa toolchain"
FAKE_XTENSA
  chmod +x "${riscv_bin}/riscv32-esp-elf-gcc" "${xtensa_bin}/xtensa-esp32s3-elf-gcc"
}

test_flash_uses_local_env_for_defaults() {
  local tmp fake_idf fake_bin fake_tools log_file defaults_file
  tmp="$(mktemp -d)"
  fake_idf="${tmp}/esp-idf"
  fake_bin="${tmp}/bin"
  fake_tools="${tmp}/idf-tools"
  log_file="${tmp}/idf.log"
  defaults_file="/tmp/xiaozhi-sdkconfig-szpi-s3-local.defaults"
  make_fixture "$tmp"
  make_fake_idf "$fake_idf" "$fake_bin" "$log_file"
  make_fake_idf_toolchains "$fake_tools"

  PATH="${fake_bin}:$PATH" XIAOZHI_STACK_ROOT="$tmp" IDF_PATH="$fake_idf" IDF_TOOLS_PATH="$fake_tools" \
    bash "${tmp}/tools/flash_szpi_s3.sh" /dev/fake >/dev/null

  assert_contains "$defaults_file" 'CONFIG_OTA_URL="http://10.0.0.42:18003/xiaozhi/ota/"'
  assert_contains "$log_file" "-DSDKCONFIG_DEFAULTS=sdkconfig.defaults;sdkconfig.defaults.esp32s3;${defaults_file}"
  assert_contains "$log_file" "XTENSA=${fake_tools}/tools/xtensa-esp-elf/esp-14.2.0_20260121/xtensa-esp-elf/bin/xtensa-esp32s3-elf-gcc"
}

test_flash_uses_local_env_for_defaults
echo "flash local env tests passed"
