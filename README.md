# Xiaozhi Local AI Hardware Stack

这个仓库是一个可复用的本地 AI 硬件底座：把 Xiaozhi ESP32 固件、Xiaozhi 兼容服务器后端、SZPI-S3 板级适配、Mac 本地运行脚本和开发文档放在一起。

它不是某一个比赛项目的业务仓库，而是后续做 Grind Buddy、AI 硬件捉虫、桌面陪伴设备、语音网关等项目时可以直接复用的基础工程。

## Included

- `firmware/xiaozhi-esp32/`: Xiaozhi ESP32 固件源码快照，已带 `main/boards/szpi-s3` 板级适配。
- `server/xiaozhi-esp32-server/`: Xiaozhi 兼容服务器源码快照，包含本地语音服务、管理 API、管理 Web 和移动端管理台源码。
- `tools/`: 本地服务器启动、模型下载、端口检查、SZPI-S3 刷机和串口监视脚本。
- `docs/`: 架构、快速开始、服务器、刷机和安全说明。

## Not Included

以下内容不会进 Git：

- `data/.config.yaml`: 真实 API key、设备白名单、本机 IP。
- `models/**/model.pt`: 大模型权重文件。
- `build*/`, `managed_components/`, `node_modules/`: 构建产物和依赖缓存。

## Server Layout

```text
server/xiaozhi-esp32-server/main/xiaozhi-server   # 设备直连的 Xiaozhi 兼容语音服务
server/xiaozhi-esp32-server/main/manager-api      # 管理台后端
server/xiaozhi-esp32-server/main/manager-web      # Web 管理台源码
server/xiaozhi-esp32-server/main/manager-mobile   # 移动端管理台源码
```

局域网硬件闭环只需要先跑 `xiaozhi-server`；管理台是后续做设备配置、项目复用和多人协作时的可选入口。当前后端模式和管理台移植状态见 [docs/backend-and-manager.md](docs/backend-and-manager.md)。

## Quick Start

```bash
cd /Users/wq/xiaozhi-local-ai-hardware-stack
# Copy the real Zhipu BigModel API key in your browser first.
export GLM_API_KEY="$(pbpaste)"
tools/prepare_local_runtime.sh
tools/download_sensevoice_model.sh
tools/setup_server_env.sh
tools/doctor.sh
tools/run_server.sh
```

另开终端刷固件：

```bash
cd /Users/wq/xiaozhi-local-ai-hardware-stack
LAN_IP=192.168.1.26 tools/flash_szpi_s3.sh /dev/cu.usbmodem112301
tools/monitor_szpi_s3.sh /dev/cu.usbmodem112301
```

详细步骤见 [docs/quickstart.md](docs/quickstart.md)。

## Verified Baseline

当前实测基线：

- 服务器运行在 Mac，本地 WebSocket 端口 `8001`，HTTP OTA 端口 `8003`。
- 固件刷入 SZPI-S3 后，通过 OTA 获取 `ws://<Mac LAN IP>:8001/xiaozhi/v1/`。
- 设备唤醒词 `你好小智` 可以连接本地服务器，并完成 ASR -> LLM -> TTS -> 播放闭环。

## Development Checks

```bash
tools/verify.sh
```

`verify.sh` 运行本仓库的轻量测试、shell 语法检查、关键 Python 入口编译检查和敏感文件跟踪检查。它不会联网、启动服务或刷固件。
