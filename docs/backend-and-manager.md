# Backend And Manager

This document records the current backend mode and the status of the copied
Xiaozhi manager modules.

## Current Backend Mode

The verified local loop currently runs only the Python `xiaozhi-server`:

```text
ESP32-S3 device
  -> OTA on :8003
  -> WebSocket on :8001
  -> local xiaozhi-server
  -> ASR -> LLM -> TTS
```

The active config file is:

```text
server/xiaozhi-esp32-server/data/.config.yaml
```

It is rendered from `.local.env` by:

```bash
tools/prepare_local_runtime.sh
tools/render_local_config.sh
```

The current local profile is:

- WebSocket: `ws://<LAN_IP>:8001/xiaozhi/v1/`
- OTA / HTTP: `http://<LAN_IP>:8003/xiaozhi/ota/`
- Device auth: enabled, with `server.auth.allowed_devices`
- VAD: `SileroVAD`
- ASR: `FunASR` using `models/SenseVoiceSmall`
- LLM: `ChatGLMLLM` using Zhipu BigModel OpenAI-compatible API
- VLLM: `ChatGLMVLLM` using Zhipu BigModel OpenAI-compatible API
- TTS: `EdgeTTS`
- Memory: `nomem`
- Intent: `function_call`

Secrets such as GLM API keys live in ignored local files and must not be
committed.

## Manager Source

The manager modules are copied from the upstream
`xinnan-tech/xiaozhi-esp32-server` project:

```text
server/xiaozhi-esp32-server/main/manager-api
server/xiaozhi-esp32-server/main/manager-web
server/xiaozhi-esp32-server/main/manager-mobile
```

They are not from the `78/xiaozhi-esp32` firmware repository. That upstream is
the device firmware source. The manager modules are part of the server-side
project.

## Manager Components

`manager-api` is the management backend:

- Java 21
- Spring Boot
- Maven
- MySQL 8
- Redis
- Liquibase migrations
- MyBatis Plus
- Shiro-based auth
- Knife4j/OpenAPI docs

`manager-web` is the web control panel:

- Vue 2
- Vue CLI
- Element UI
- Calls `manager-api`

`manager-mobile` is the mobile/H5 console:

- uni-app
- Vue 3
- Vite
- pnpm

## Why Manager Is Not Active Yet

The current verified loop intentionally uses file-based local config because it
has the smallest operational surface:

```text
xiaozhi-server -> data/.config.yaml
```

The manager mode adds more moving parts:

```text
manager-web / manager-mobile
  -> manager-api
  -> MySQL / Redis
  -> xiaozhi-server pulls runtime config from manager-api
  -> ESP32-S3 device
```

This is useful for productization, but it should not replace the file-based
mode until the manager backend has been verified locally.

## Migration Direction

The recommended migration path is to keep the upstream manager backend mostly
intact first, then localize it:

1. Add local startup scripts for `manager-api` and `manager-web`.
2. Add a manager doctor script for Java, Maven, Node, MySQL, Redis, and ports.
3. Add local manager config defaults for this stack.
4. Start `manager-api` without changing the working `xiaozhi-server` config.
5. Start `manager-web` and verify login/config screens.
6. Add an explicit switch between:
   - local file mode: `xiaozhi-server -> data/.config.yaml`
   - manager mode: `xiaozhi-server -> manager-api`
7. Only after manager mode is verified, remove or hide upstream modules that are
   not needed for this local hardware stack.

Avoid rewriting the manager backend before it runs. Copying it is simple; making
it lightweight is a separate refactor.
