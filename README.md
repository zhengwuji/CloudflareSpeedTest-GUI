# CloudflareSpeedTest-GUI

Cloudflare 优选 IP 测速工具的图形化界面 (GUI)

## 功能特点

- 🎯 可视化配置测速参数
- 💾 保存/加载/删除预设配置
- 🚀 一键启动测速
- 🖥️ 简洁美观的界面

## 使用说明

### 前置要求

在程序同目录下需要以下文件：
- `cfst.exe` - CloudflareSpeedTest 命令行工具
- `ip.txt` - IP 段数据文件

### 运行方式

**方式一：直接运行 EXE**

从 [Releases](../../releases) 下载最新的 `CloudflareSpeedTest-GUI.exe`

**方式二：Python 运行**

```bash
pip install PyQt5
python CloudflareSpeedTest-GUI.py
```

## 参数说明

| 参数 | 默认值 | 说明 |
|------|--------|------|
| -n | 200 | 延迟测试线程数 (1-1000) |
| -t | 4 | 延迟测试次数 |
| -dn | 10 | 下载测速数量 |
| -dt | 10 | 下载测速时间(秒) |
| -tp | 443 | 测速端口 |
| -url | - | 测速地址 |
| -httping | - | HTTPing 模式 |
| -cfcolo | HKG,KHH,NRT,LAX | 数据中心地区码 |
| -tl | 9999 | 平均延迟上限(ms) |
| -tll | 0 | 平均延迟下限(ms) |
| -tlr | 1.00 | 丢包率上限 |
| -sl | 0 | 下载速度下限(MB/s) |
| -dd | - | 禁用下载测速 |
| -allip | - | 测速全部 IP |

## 自行构建

```bash
pip install pyinstaller PyQt5
pyinstaller --onefile --windowed --icon=app.ico --add-data "app.ico;." --name CloudflareSpeedTest-GUI CloudflareSpeedTest-GUI.py
```

构建完成后，exe 文件位于 `dist/` 目录

## License

MIT License
