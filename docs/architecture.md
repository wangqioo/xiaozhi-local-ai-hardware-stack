# Architecture

本仓库把 Xiaozhi 的固件和兼容服务器打包成一个本地 AI 硬件底座。

## Runtime Roles

- SZPI-S3 / ESP32-S3: 负责屏幕、麦克风、扬声器、Wi-Fi、OTA 和 WebSocket 音频链路。
- Mac local server: 运行 Xiaozhi 兼容服务器，处理 OTA、WebSocket、ASR、LLM、TTS。
- Manager API/Web/Mobile: 可选管理台，用于后续设备配置、模型配置、项目协作和运营化管理。
- K230: 在 Grind Buddy 这类项目中只负责图像处理和识别，不承担联网、屏幕、麦克风或扬声器驱动。
- Cloud API: 由本地服务器调用第三方 LLM/TTS/ASR 服务；设备侧不直接持有 API key。

## Data Flow

```text
User voice
  -> ESP32-S3 microphone
  -> WebSocket audio stream
  -> local Xiaozhi-compatible server
  -> ASR
  -> LLM
  -> TTS
  -> WebSocket audio stream
  -> ESP32-S3 speaker
```

## Why Local Compatible Server

我们当前使用的是自建 Xiaozhi 兼容服，不是官方云服务。这样做的好处：

- 设备不需要官方配对流程。
- API key 只放在本地服务器配置里。
- 服务器可以按比赛项目定制 ASR、LLM、TTS、视觉分析和业务逻辑。
- 同一个固件/服务器底座可以复用于多个 AI 硬件项目。

## Runtime Seams

### Device Admission

`server/xiaozhi-esp32-server/main/xiaozhi-server/core/device_admission.py`
是设备准入的共享 seam。OTA、WebSocket 和本地 admin 绑定页都通过它处理：

- `allowed_devices` 白名单。
- OTA 下发 WebSocket token。
- 未绑定设备的 activation code。
- WebSocket `Authorization: Bearer ...` 校验。
- 本地绑定成功后的内存准入更新。

这样 OTA handler 只负责 HTTP/OTA 响应，WebSocket server 只负责连接生命周期，
admin handler 只负责绑定页面和持久化，准入规则不会在三个 adapter 里重复漂移。

### OTA Contract

`server/xiaozhi-esp32-server/main/xiaozhi-server/core/ota_contract.py`
是 OTA 协议解析 seam。它集中处理：

- 设备上报解析：`device-id`、`client-id`、board/model、firmware version。
- WebSocket URL fallback：配置为占位符时使用本机 LAN IP 和端口。
- 固件版本比较和候选固件选择。
- OTA 下载 URL 从 vision base URL 派生。

`OTAHandler` 仍然是 aiohttp adapter，负责 HTTP request/response、CORS、
MQTT/WebSocket 分支和固件文件扫描；协议规则本身可以通过纯 Python 测试覆盖。

### Runtime Profile

`server/xiaozhi-esp32-server/main/xiaozhi-server/config/runtime_profile.py`
是运行配置解析 seam。它把本地 YAML 或 manager-api 返回的 raw config 归一成
`RuntimeProfile`，集中描述：

- 配置来源：`local` 或 `manager-api`。
- WebSocket/HTTP 端口和公开 URL。
- `auth_key` 优先级：本地配置 > manager secret > 自动生成。
- 设备认证开关和白名单。
- 当前选择的 ASR/LLM/TTS/Memory/Intent 等模块。

当前启动入口先使用它统一解析 auth 和端口。后续如果继续深化，可让模块初始化、
私有配置和 manager-api adapter 都围绕 `RuntimeProfile` 扩展，而不是继续传递 raw map。

### Project Capability Pack

`project-packs/*/manifest.env` 是项目能力包 seam。它不直接改变运行时行为，
而是先把一个业务项目会扩展的能力显式记录下来：

- prompt 能力。
- HTTP context provider。
- function_call / MCP endpoint 工具。
- MCP vision HTTP。
- 设备动作。
- 可选管理能力。

`tools/verify_project_packs.sh` 会检查 manifest 必填字段和引用文档是否存在。
等具体业务项目出现后，可以把这个 manifest 扩展成真正的 adapter，把能力解析进
`RuntimeProfile`，而不是把 prompts、tools、vision、device actions 分散到多个地方。

## Repository Boundary

这个仓库是通用底座。具体比赛项目可以在独立业务仓库中引用它，或者复制它作为起点，然后只改：

- 板级定义。
- OTA 地址。
- 服务端业务能力。
- 设备白名单和密钥配置。

管理台源码保留在仓库中，但默认硬件验证路径不依赖管理台。这样既能保持最短闭环，也保留以后做完整产品后台的扩展空间。
管理台来源、依赖和移植策略见 [backend-and-manager.md](backend-and-manager.md)。
