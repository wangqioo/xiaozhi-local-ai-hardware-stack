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

## Repository Boundary

这个仓库是通用底座。具体比赛项目可以在独立业务仓库中引用它，或者复制它作为起点，然后只改：

- 板级定义。
- OTA 地址。
- 服务端业务能力。
- 设备白名单和密钥配置。

管理台源码保留在仓库中，但默认硬件验证路径不依赖管理台。这样既能保持最短闭环，也保留以后做完整产品后台的扩展空间。
