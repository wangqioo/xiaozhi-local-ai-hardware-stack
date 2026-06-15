# SZPI-S3 Bring-up

本仓库已经包含 `firmware/xiaozhi-esp32/main/boards/szpi-s3`。

## Overlay Contract

SZPI-S3 的本地板卡适配由 `firmware/overlays/szpi-s3/manifest.env` 记录。
它是升级上游 `firmware/xiaozhi-esp32` 快照时的维护入口，声明：

- `BOARD_TYPE=szpi-s3`
- `KCONFIG_SYMBOL=CONFIG_BOARD_TYPE_SZPI_S3`
- `IDF_TARGET=esp32s3`
- board source path: `firmware/xiaozhi-esp32/main/boards/szpi-s3`
- CMake font / emoji defaults
- `CONFIG_USE_DEVICE_AEC=y`

升级或重拉上游固件后，先运行：

```bash
tools/verify_szpi_s3_overlay.sh
```

它会检查 board 目录、CMake 注册、Kconfig 注册、device AEC dependency、
`config.json` 和刷机 defaults 是否仍然和 manifest 一致。

## Hardware Baseline

当前实测板卡：

- Chip: ESP32-S3
- Board type: `szpi-s3`
- Device MAC: `10:51:db:80:e2:e8`
- Serial port example: `/dev/cu.usbmodem112301`
- Local server IP example: `192.168.1.26`

串口和 IP 会随机器和网络变化，以现场为准。

## Flash

```bash
tools/flash_szpi_s3.sh /dev/cu.usbmodem112301
```

脚本会生成临时 defaults：

```text
CONFIG_IDF_TARGET="esp32s3"
CONFIG_BOARD_TYPE_SZPI_S3=y
CONFIG_OTA_URL="http://<LAN_IP>:8003/xiaozhi/ota/"
CONFIG_USE_DEVICE_AEC=y
```

`LAN_IP=... tools/flash_szpi_s3.sh ...` 仍可临时覆盖地址；默认会读取根目录 `.local.env`。

## Monitor

```bash
tools/monitor_szpi_s3.sh /dev/cu.usbmodem112301
```

## Expected Logs

关键现象：

- `Project name: xiaozhi`
- `BOARD_TYPE` / SKU 为 `szpi-s3`
- Wi-Fi 获取局域网 IP
- OTA 请求 `http://<LAN_IP>:8003/xiaozhi/ota/`
- OTA 返回 `ws://<LAN_IP>:8001/xiaozhi/v1/`
- 唤醒词后进入 WebSocket 对话

## Bench Rule

这块板会被其他项目复用。每次测试这个底座时，都要重新刷入本仓库固件，避免误判别的项目固件行为。
