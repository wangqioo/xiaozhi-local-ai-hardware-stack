# Doctor Preflight Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a local preflight command that tells whether the Xiaozhi hardware loop is ready to run before flashing or demoing.

**Architecture:** `tools/doctor.sh` is a small shell module with one interface: run it from anywhere and get PASS/WARN/FAIL checks for the local loop. The implementation reads the repository root, supports `XIAOZHI_STACK_ROOT` for tests, and keeps hardware-only checks as warnings unless the user opts in.

**Tech Stack:** Bash, existing Xiaozhi config layout, pure shell tests under `tests/`.

---

### Task 1: Test the Doctor Interface

**Files:**
- Create: `tests/test_doctor.sh`

- [ ] **Step 1: Write the failing test**

Create `tests/test_doctor.sh` with three behaviours:

```bash
#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCTOR="${REPO_ROOT}/tools/doctor.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_contains() {
  local file="$1"
  local expected="$2"
  if ! grep -Fq "$expected" "$file"; then
    echo "Expected to find: $expected" >&2
    echo "--- output ---" >&2
    cat "$file" >&2
    fail "missing expected text"
  fi
}

make_fixture() {
  local root="$1"
  mkdir -p "${root}/server/xiaozhi-esp32-server/data"
  mkdir -p "${root}/server/xiaozhi-esp32-server/main/xiaozhi-server/models/SenseVoiceSmall"
}

make_fake_bin() {
  local bin_dir="$1"
  mkdir -p "$bin_dir"
  cat > "${bin_dir}/conda" <<'FAKE_CONDA'
#!/usr/bin/env bash
if [[ "${1:-}" == "env" && "${2:-}" == "list" ]]; then
  echo "xiaozhi-esp32-server  /tmp/xiaozhi-esp32-server"
  exit 0
fi
echo "fake conda" >&2
exit 0
FAKE_CONDA
  cat > "${bin_dir}/ffmpeg" <<'FAKE_FFMPEG'
#!/usr/bin/env bash
echo "ffmpeg version fake"
FAKE_FFMPEG
  cat > "${bin_dir}/lsof" <<'FAKE_LSOF'
#!/usr/bin/env bash
exit 1
FAKE_LSOF
  chmod +x "${bin_dir}/conda" "${bin_dir}/ffmpeg" "${bin_dir}/lsof"
}

test_missing_config_fails() {
  local tmp out
  tmp="$(mktemp -d)"
  out="${tmp}/out.txt"
  make_fixture "$tmp"

  if XIAOZHI_STACK_ROOT="$tmp" bash "$DOCTOR" >"$out" 2>&1; then
    cat "$out" >&2
    fail "doctor should fail without data/.config.yaml"
  fi

  assert_contains "$out" "FAIL config file"
}

test_placeholder_config_fails() {
  local tmp out fake_bin
  tmp="$(mktemp -d)"
  out="${tmp}/out.txt"
  fake_bin="${tmp}/bin"
  make_fixture "$tmp"
  make_fake_bin "$fake_bin"
  printf 'model' > "${tmp}/server/xiaozhi-esp32-server/main/xiaozhi-server/models/SenseVoiceSmall/model.pt"
  cat > "${tmp}/server/xiaozhi-esp32-server/data/.config.yaml" <<'YAML'
server:
  websocket: ws://YOUR_MAC_LAN_IP:8001/xiaozhi/v1/
  vision_explain: http://YOUR_MAC_LAN_IP:8003/mcp/vision/explain
YAML

  if PATH="${fake_bin}:$PATH" XIAOZHI_STACK_ROOT="$tmp" bash "$DOCTOR" >"$out" 2>&1; then
    cat "$out" >&2
    fail "doctor should fail when config still has placeholders"
  fi

  assert_contains "$out" "FAIL config placeholders"
}

test_ready_fixture_passes_with_warnings_allowed() {
  local tmp out fake_bin
  tmp="$(mktemp -d)"
  out="${tmp}/out.txt"
  fake_bin="${tmp}/bin"
  make_fixture "$tmp"
  make_fake_bin "$fake_bin"
  printf 'model' > "${tmp}/server/xiaozhi-esp32-server/main/xiaozhi-server/models/SenseVoiceSmall/model.pt"
  cat > "${tmp}/server/xiaozhi-esp32-server/data/.config.yaml" <<'YAML'
server:
  websocket: ws://192.168.1.26:8001/xiaozhi/v1/
  vision_explain: http://192.168.1.26:8003/mcp/vision/explain
  auth:
    enabled: true
    allowed_devices:
      - "10:51:db:80:e2:e8"
LLM:
  ChatGLMLLM:
    api_key: glmdoctorfixture1234567890.secretpart123456
YAML

  PATH="${fake_bin}:$PATH" XIAOZHI_STACK_ROOT="$tmp" bash "$DOCTOR" >"$out" 2>&1

  assert_contains "$out" "PASS config file"
  assert_contains "$out" "PASS SenseVoice model"
  assert_contains "$out" "PASS conda env"
  assert_contains "$out" "Doctor summary: ready"
}

test_missing_config_fails
test_placeholder_config_fails
test_ready_fixture_passes_with_warnings_allowed
echo "doctor tests passed"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test_doctor.sh`

Expected: failure because `tools/doctor.sh` does not exist yet.

### Task 2: Implement the Preflight Module

**Files:**
- Create: `tools/doctor.sh`

- [ ] **Step 1: Write minimal implementation**

Create `tools/doctor.sh` with checks for:

- `data/.config.yaml` exists.
- `.config.yaml` does not contain placeholder values.
- `server.websocket` is not localhost.
- `SenseVoiceSmall/model.pt` exists and is non-empty.
- `conda` is installed.
- `XIAOZHI_CONDA_ENV` exists, defaulting to `xiaozhi-esp32-server`.
- `ffmpeg` is installed.
- ports `8001` and `8003` are reported as PASS when listening, WARN otherwise.
- `IDF_PATH/export.sh` is WARN when missing.

- [ ] **Step 2: Run test to verify it passes**

Run: `bash tests/test_doctor.sh`

Expected: `doctor tests passed`.

### Task 3: Document the Preflight

**Files:**
- Modify: `README.md`
- Modify: `docs/quickstart.md`

- [ ] **Step 1: Add preflight command to quickstart**

Insert `tools/doctor.sh` before running the server and mention it should be run again after editing `.config.yaml`.

- [ ] **Step 2: Run verification**

Run:

```bash
bash tests/test_doctor.sh
bash -n tools/*.sh tests/test_doctor.sh
python3 -m py_compile server/xiaozhi-esp32-server/main/xiaozhi-server/app.py server/xiaozhi-esp32-server/main/xiaozhi-server/config/config_loader.py server/xiaozhi-esp32-server/main/xiaozhi-server/core/http_server.py server/xiaozhi-esp32-server/main/xiaozhi-server/core/api/ota_handler.py server/xiaozhi-esp32-server/main/xiaozhi-server/core/websocket_server.py
tools/verify.sh
```

Expected: all commands exit 0.
