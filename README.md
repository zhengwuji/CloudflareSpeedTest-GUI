# CloudflareSpeedTest-GUI

Cloudflare 优选 IP 测速工具的图形化界面 (GUI)

## 功能特点

- 🖥️ 测速结果实时显示
- 📊 进度条显示测速进度
- 📋 结果查看器 (表格展示，支持排序筛选)
- 📋 一键复制最优 IP
- 🌙 深色/浅色主题切换
- 📌 系统托盘支持
- 🔄 自动更新 IP 库 (国内代理源)
- 📜 测速历史记录

## 📥 下载

从 [Releases](../../releases) 页面下载最新版本：

- **Windows**: `CloudflareSpeedTest-GUI.exe`
- **OpenWrt**: `luci-app-cfspeedtest_1.0.0_all.ipk`

---

## 🖥️ Windows 使用说明

### 前置要求

在程序同目录下需要以下文件：
- `cfst.exe` - CloudflareSpeedTest 命令行工具
- `ip.txt` - IP 段数据文件 (可通过程序自动更新)

### 运行方式

**方式一：直接运行 EXE**

下载 `CloudflareSpeedTest-GUI.exe` 双击运行

**方式二：Python 运行**

```bash
pip install PyQt5 requests
python CloudflareSpeedTest-GUI.py
```

---

## 📡 OpenWrt 使用说明

### 安装方法

1. 下载 `luci-app-cfspeedtest_1.0.0_all.ipk`
2. 登录 OpenWrt LuCI 界面
3. 进入 **系统 → 软件包 → 上传软件包**
4. 选择下载的 ipk 文件并安装
5. 安装完成后在 **服务** 菜单中找到 **CF优选IP**

### 功能说明

- 自动下载适合路由器架构的 CloudflareST 二进制
- 支持 x86_64, ARM64, ARM, MIPS 等架构
- 通过 LuCI 界面配置测速参数
- 使用国内代理源更新 IP 库

### 手动安装

```bash
# SSH 登录路由器后执行
opkg install luci-app-cfspeedtest_1.0.0_all.ipk
/etc/init.d/cfspeedtest enable
```

---

## 参数说明

| 参数 | 默认值 | 说明 |
|------|--------|------|
| -n | 200 | 延迟测试线程数 (1-1000) |
| -t | 4 | 延迟测试次数 |
| -dn | 10 | 下载测速数量 |
| -dt | 10 | 下载测速时间(秒) |
| -tp | 443 | 测速端口 |
| -url | cf.xiu2.xyz | 测速地址 |
| -httping | - | HTTPing 模式 |
| -cfcolo | HKG,KHH,NRT,LAX | 数据中心地区码 |
| -tl | 9999 | 平均延迟上限(ms) |
| -tll | 0 | 平均延迟下限(ms) |
| -tlr | 1.00 | 丢包率上限 |
| -sl | 0 | 下载速度下限(MB/s) |
| -dd | - | 禁用下载测速 |
| -allip | - | 测速全部 IP |

---

## 自行构建

### Windows

```bash
pip install pyinstaller PyQt5 requests
pyinstaller --onefile --windowed --name CloudflareSpeedTest-GUI CloudflareSpeedTest-GUI.py
```

### OpenWrt

使用 GitHub Actions 自动构建，或参考 `openwrt/` 目录手动打包。

---

## 📁 项目结构

```
├── CloudflareSpeedTest-GUI.py  # Windows GUI 主程序
├── requirements.txt            # Python 依赖
├── .github/
│   └── workflows/
│       └── build.yml           # 自动构建配置
└── openwrt/                    # OpenWrt LuCI 包
    ├── luci/
    │   ├── controller/         # LuCI 控制器
    │   └── model/cbi/          # LuCI CBI 配置页面
    ├── cfspeedtest.config      # UCI 配置文件
    ├── cfspeedtest.init        # init.d 启动脚本
    └── cfspeedtest.sh          # 测速执行脚本
```

---

## License

MIT License
