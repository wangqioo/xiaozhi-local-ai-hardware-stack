#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tools/local_env.sh
source "${SCRIPT_DIR}/local_env.sh"

ROOT_DIR="$(resolve_root_dir)"
PACK_ROOT="${ROOT_DIR}/project-packs"
DOCS_ROOT="${ROOT_DIR}/server/xiaozhi-esp32-server/docs"

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

check_pack_manifest() {
  local manifest="$1"
  # shellcheck disable=SC1090
  source "$manifest"

  local required=(
    PACK_ID
    PACK_NAME
    RUNTIME_PROFILE_ADAPTER
    PROMPT_CAPABILITIES
    CONTEXT_CAPABILITIES
    TOOL_CAPABILITIES
    VISION_CAPABILITIES
    DEVICE_ACTION_CAPABILITIES
    MANAGEMENT_CAPABILITIES
    DOCS
  )
  local missing=()
  local name
  for name in "${required[@]}"; do
    if [[ -z "${!name:-}" ]]; then
      missing+=("$name")
    fi
  done

  if [[ "${#missing[@]}" -gt 0 ]]; then
    fail "project pack required fields" "${manifest}: ${missing[*]}"
  else
    pass "project pack required fields" "${PACK_ID}"
  fi

  local missing_docs=()
  local doc
  IFS=',' read -r -a docs <<< "${DOCS}"
  for doc in "${docs[@]}"; do
    if [[ ! -f "${DOCS_ROOT}/${doc}" ]]; then
      missing_docs+=("$doc")
    fi
  done

  if [[ "${#missing_docs[@]}" -gt 0 ]]; then
    fail "project pack docs" "${manifest}: ${missing_docs[*]}"
  else
    pass "project pack docs" "${PACK_ID}"
  fi
}

echo "Project pack verify"
echo "Root: ${ROOT_DIR}"
echo

if [[ ! -d "${PACK_ROOT}" ]]; then
  fail "project pack manifest" "missing ${PACK_ROOT}"
else
  found=0
  while IFS= read -r manifest; do
    found=$((found + 1))
    pass "project pack manifest" "${manifest}"
    check_pack_manifest "${manifest}"
  done < <(find "${PACK_ROOT}" -mindepth 2 -maxdepth 2 -name manifest.env -type f | sort)

  if [[ "${found}" -eq 0 ]]; then
    fail "project pack manifest" "no manifest.env files under ${PACK_ROOT}"
  fi
fi

echo
if [[ "${failures}" -gt 0 ]]; then
  echo "Project pack verify: failed (${failures} failure(s))"
  exit 1
fi

echo "Project pack verify: ok"
