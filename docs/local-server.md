# Local Server

服务端目录：

```text
server/xiaozhi-esp32-server/main/xiaozhi-server
```

同一服务端快照还保留：

```text
server/xiaozhi-esp32-server/main/manager-api
server/xiaozhi-esp32-server/main/manager-web
server/xiaozhi-esp32-server/main/manager-mobile
```

管理台不是本地硬件语音闭环的必需项，但对后续做完整项目模板有价值，所以保留源码，排除 `.env`、`node_modules` 和构建产物。
当前后端模式和管理台移植状态见 [backend-and-manager.md](backend-and-manager.md)。

本地运行使用：

```bash
tools/run_server.sh
```

## Config

真实配置文件：

```text
server/xiaozhi-esp32-server/data/.config.yaml
```

示例配置：

```text
server/xiaozhi-esp32-server/data/.config.example.yaml
```

服务器启动时，`main/xiaozhi-server/data` 会链接到 `../../data`，从而复用上游推荐的 `data/.config.yaml` 覆盖机制。

推荐不要手写真实配置，而是维护根目录 `.local.env`，再运行：

```bash
tools/render_local_config.sh
```

这样服务器配置和刷机脚本会使用同一套 LAN IP、端口、设备 MAC 和 API key。

## Ports

- `8001`: WebSocket 音频和控制通道。
- `8003`: HTTP OTA 和视觉接口。

OTA 下发给设备的 WebSocket 地址由 `server.websocket` 决定，局域网测试时必须写 Mac 的局域网 IP：

```yaml
server:
  websocket: ws://192.168.1.26:8001/xiaozhi/v1/
```

## Verified Local Loop

实测链路：

```text
device OTA -> server returns websocket config
wake word "你好小智" -> WebSocket connected
ASR text -> LLM request -> TTS audio -> device playback
```

如果设备可以 OTA 但不能语音对话，优先检查：

- `server.auth.allowed_devices` 是否包含设备 MAC。
- `server.websocket` 是否是设备能访问的局域网地址。
- `8001` 和 `8003` 是否正在监听。
- Mac 防火墙是否阻止局域网连接。
