# Quick Start

这个流程面向 Mac 本地自建 Xiaozhi 兼容服，并刷入 SZPI-S3 固件。

## 1. Prepare Config

```bash
cd /Users/wq/xiaozhi-local-ai-hardware-stack
cp server/xiaozhi-esp32-server/data/.config.example.yaml server/xiaozhi-esp32-server/data/.config.yaml
```

编辑 `server/xiaozhi-esp32-server/data/.config.yaml`：

- `YOUR_MAC_LAN_IP`: Mac 在同一局域网里的 IP，例如 `192.168.1.26`。
- `AA:BB:CC:DD:EE:FF`: 设备 MAC，例如实测板子的 `10:51:db:80:e2:e8`。
- `YOUR_DASHSCOPE_API_KEY`: 阿里 DashScope 兼容 OpenAI API key。

真实配置文件不要提交到 Git。

## 2. Install Server Runtime

```bash
tools/download_sensevoice_model.sh
tools/setup_server_env.sh
```

Mac arm64 会自动使用 `requirements-macos-arm64.txt`，里面固定了本机实测可安装的 `sherpa_onnx==1.12.26` 和 `vosk==0.3.44`。

## 3. Run Local Server

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

## 4. Flash SZPI-S3 Firmware

每次这块板被别的项目占用后，测试本项目都要重新刷本仓库固件。

```bash
LAN_IP=192.168.1.26 tools/flash_szpi_s3.sh /dev/cu.usbmodem112301
```

串口号以实际 `ls /dev/cu.usbmodem*` 为准。

## 5. Monitor and Test

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
