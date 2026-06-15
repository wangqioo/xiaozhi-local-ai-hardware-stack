#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERIFY_PACKS="${REPO_ROOT}/tools/verify_project_packs.sh"
EXAMPLE_PACK="${REPO_ROOT}/project-packs/example-local/manifest.env"

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
  if ! grep -Fxq -- "$expected" "$EXAMPLE_PACK"; then
    echo "Expected manifest entry: $expected" >&2
    cat "$EXAMPLE_PACK" >&2
    fail "missing manifest entry"
  fi
}

test_example_pack_manifest_declares_runtime_capabilities() {
  [[ -f "$EXAMPLE_PACK" ]] || fail "missing example project pack manifest"

  assert_manifest_value "PACK_ID=example-local"
  assert_manifest_value "PACK_NAME=\"Example Local Device Pack\""
  assert_manifest_value "RUNTIME_PROFILE_ADAPTER=local-yaml"
  assert_manifest_value "PROMPT_CAPABILITIES=system_prompt"
  assert_manifest_value "CONTEXT_CAPABILITIES=http_context_provider"
  assert_manifest_value "TOOL_CAPABILITIES=function_call,mcp_endpoint"
  assert_manifest_value "VISION_CAPABILITIES=mcp_vision_http"
  assert_manifest_value "DEVICE_ACTION_CAPABILITIES=mcp_device_action"
  assert_manifest_value "MANAGEMENT_CAPABILITIES=none"
}

test_project_pack_verify_passes() {
  local out
  out="$(mktemp)"

  bash "$VERIFY_PACKS" > "$out"

  assert_contains "$out" "PASS project pack manifest"
  assert_contains "$out" "PASS project pack required fields"
  assert_contains "$out" "PASS project pack docs"
  assert_contains "$out" "Project pack verify: ok"
}

test_example_pack_manifest_declares_runtime_capabilities
test_project_pack_verify_passes
echo "project pack tests passed"
