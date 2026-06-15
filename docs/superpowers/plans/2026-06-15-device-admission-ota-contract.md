# Device Admission OTA Contract Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Centralize Xiaozhi device admission so OTA provisioning, WebSocket authentication, and local device binding share one runtime contract.

**Architecture:** Add `core/device_admission.py` as the deep module for allowed-device policy, token issuing/verification, and activation-code state. Keep OTA, WebSocket, and local admin handlers as adapters so external JSON and WebSocket auth behavior remain unchanged.

**Tech Stack:** Python standard library, existing `core.auth.AuthManager`, shell-based repo verification via `tools/verify.sh`.

---

### Task 1: DeviceAdmission Contract

**Files:**
- Create: `server/xiaozhi-esp32-server/main/xiaozhi-server/core/device_admission.py`
- Create: `tests/test_device_admission.py`
- Modify: `tools/verify.sh`

- [ ] Write Python unit tests for whitelist provisioning, activation provisioning, valid token verification, invalid token rejection, and one-time activation consume.
- [ ] Run `python3 tests/test_device_admission.py` and confirm it fails because `core.device_admission` does not exist.
- [ ] Implement `DeviceAdmission` with a small interface: `provision_websocket`, `verify_websocket`, `verify_activation_code`, and `allow_device`.
- [ ] Run `python3 tests/test_device_admission.py` and confirm it passes.
- [ ] Add `tests/test_device_admission.py` to `tools/verify.sh`.

### Task 2: Adapter Integration

**Files:**
- Modify: `server/xiaozhi-esp32-server/main/xiaozhi-server/core/api/ota_handler.py`
- Modify: `server/xiaozhi-esp32-server/main/xiaozhi-server/core/websocket_server.py`
- Modify: `server/xiaozhi-esp32-server/main/xiaozhi-server/core/api/device_admin.py`
- Modify: `server/xiaozhi-esp32-server/main/xiaozhi-server/core/http_server.py` if shared admission must be injected.

- [ ] Update `OTAHandler` to call `DeviceAdmission.provision_websocket` when building the WebSocket OTA response.
- [ ] Update `WebSocketServer._handle_auth` to call `DeviceAdmission.verify_websocket`.
- [ ] Update `DeviceAdminHandler` to consume activation codes and add allowed devices through `DeviceAdmission`.
- [ ] Preserve current public responses: OTA still returns `websocket.token` and optional `activation`; failed WebSocket auth still closes the connection with `认证失败`.

### Task 3: Verification

**Files:**
- Modify: `tools/verify.sh`

- [ ] Run `python3 tests/test_device_admission.py`.
- [ ] Run `python3 -m py_compile` over changed Python modules.
- [ ] Run `tools/verify.sh`.
- [ ] Run `git diff --check`.
