#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERIFY_OVERLAY="${REPO_ROOT}/tools/verify_szpi_s3_overlay.sh"
MANIFEST="${REPO_ROOT}/firmware/overlays/szpi-s3/manifest.env"

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

assert_manifest_value() {
  local expected="$1"
  if ! grep -Fxq -- "$expected" "$MANIFEST"; then
    echo "Expected manifest entry: $expected" >&2
    cat "$MANIFEST" >&2
    fail "missing manifest entry"
  fi
}

test_manifest_records_szpi_s3_overlay_contract() {
  [[ -f "$MANIFEST" ]] || fail "missing overlay manifest"

  assert_manifest_value "BOARD_TYPE=szpi-s3"
  assert_manifest_value "KCONFIG_SYMBOL=CONFIG_BOARD_TYPE_SZPI_S3"
  assert_manifest_value "KCONFIG_NAME=BOARD_TYPE_SZPI_S3"
  assert_manifest_value "IDF_TARGET=esp32s3"
  assert_manifest_value "BOARD_DIR=firmware/xiaozhi-esp32/main/boards/szpi-s3"
  assert_manifest_value "BOARD_SOURCE=szpi_s3_board.cc"
  assert_manifest_value "CONFIG_JSON=config.json"
  assert_manifest_value "REQUIRES_DEVICE_AEC=y"
}

test_overlay_verify_passes_for_current_snapshot() {
  local out
  out="$(mktemp)"

  bash "$VERIFY_OVERLAY" > "$out"

  assert_contains "$out" "PASS manifest"
  assert_contains "$out" "PASS board files"
  assert_contains "$out" "PASS cmake registration"
  assert_contains "$out" "PASS kconfig registration"
  assert_contains "$out" "PASS device AEC dependency"
  assert_contains "$out" "PASS board config.json"
  assert_contains "$out" "PASS firmware defaults"
  assert_contains "$out" "SZPI-S3 overlay verify: ok"
}

test_manifest_records_szpi_s3_overlay_contract
test_overlay_verify_passes_for_current_snapshot
echo "szpi-s3 overlay tests passed"
