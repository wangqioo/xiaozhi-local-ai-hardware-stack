# Quick Start

这个流程面向 Mac 本地自建 Xiaozhi 兼容服，并刷入 SZPI-S3 固件。

## 1. Prepare Config

```bash
cd /Users/wq/xiaozhi-local-ai-hardware-stack
# Copy the real Zhipu BigModel API key in your browser first.
export GLM_API_KEY="$(pbpaste)"
tools/prepare_local_runtime.sh
```

`tools/prepare_local_runtime.sh` 会从 `GLM_API_KEY` 或
`XIAOZHI_GLM_API_KEY` 读取智谱 BigModel 密钥，创建/更新 `.local.env`，
生成 `data/.config.yaml`，并运行 `tools/doctor.sh`。脚本不会在输出中回显密钥。
如果复制出来的值带 `GLM:` 前缀，脚本会自动去掉前缀后写入本地配置。

如需手动维护 `.local.env`，字段含义如下：

- `XIAOZHI_LAN_IP`: Mac 在同一局域网里的 IP，例如 `192.168.1.26`。
- `XIAOZHI_DEVICE_MAC`: 设备 MAC，例如实测板子的 `10:51:db:80:e2:e8`。
- `XIAOZHI_GLM_API_KEY`: 智谱 BigModel 兼容 OpenAI API key。
- `XIAOZHI_WS_PORT` / `XIAOZHI_HTTP_PORT`: 默认分别是 `8001` 和 `8003`。

手动编辑后重新生成真实服务器配置：

```bash
tools/render_local_config.sh
```

真实配置文件不要提交到 Git。

## 2. Install Server Runtime

```bash
tools/download_sensevoice_model.sh
tools/setup_server_env.sh
```

Mac arm64 会自动使用 `requirements-macos-arm64.txt`，里面固定了本机实测可安装的 `sherpa_onnx==1.12.26` 和 `vosk==0.3.44`。

## 3. Run Preflight

```bash
tools/doctor.sh
```

预检会检查本地配置、占位符、SenseVoice 模型、conda 环境、ffmpeg、常用端口和 ESP-IDF 路径。`FAIL` 需要先修；`WARN` 通常表示服务还没启动或刷机环境还没准备好。

改动脚本或文档后，可以运行轻量验证：

```bash
tools/verify.sh
```

## 4. Run Local Server

```bash
tools/run_server.sh
```

预期端口：

- WebSocket: `8001`
- HTTP OTA: `8003`

检查端口：

```bash
tools/check_ports.sh
```

## 5. Flash SZPI-S3 Firmware

每次这块板被别的项目占用后，测试本项目都要重新刷本仓库固件。

```bash
tools/flash_szpi_s3.sh /dev/cu.usbmodem112301
```

刷机脚本会优先读取 `.local.env` 里的 `XIAOZHI_LAN_IP` 和 `XIAOZHI_HTTP_PORT`。串口号以实际 `ls /dev/cu.usbmodem*` 为准。

## 6. Monitor and Test

```bash
tools/monitor_szpi_s3.sh /dev/cu.usbmodem112301
```

设备联网后，OTA 会返回：

```text
ws://<Mac LAN IP>:8001/xiaozhi/v1/
```

对设备说 `你好小智`，预期链路：

```text
Wake word -> WebSocket connect -> ASR -> LLM -> TTS -> speaker playback
```
