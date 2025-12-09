# CloudflareSpeedTest-GUI

🚀 **Cloudflare IP 优选工具** - 图形化界面，支持 Windows 和 OpenWrt

[![Build Release](https://github.com/zhengwuji/CloudflareSpeedTest-GUI/actions/workflows/build.yml/badge.svg)](https://github.com/zhengwuji/CloudflareSpeedTest-GUI/actions/workflows/build.yml)
[![GitHub Release](https://img.shields.io/github/v/release/zhengwuji/CloudflareSpeedTest-GUI)](https://github.com/zhengwuji/CloudflareSpeedTest-GUI/releases)
[![License](https://img.shields.io/github/license/zhengwuji/CloudflareSpeedTest-GUI)](LICENSE)

## 📖 简介

基于 [XIU2/CloudflareSpeedTest](https://github.com/XIU2/CloudflareSpeedTest) 开发的图形化界面工具，让 Cloudflare IP 测速更加简单便捷。

## ✨ 功能特性

### Windows 桌面版
- 🖥️ 现代化图形界面
- 🌙 深色/浅色主题切换
- 📊 测速结果实时显示
- 📋 一键复制最优 IP
- 📌 系统托盘最小化
- 🔄 自动更新 IP 库
- 📜 历史记录保存

### OpenWrt LuCI 版
- ⚙️ 可视化配置界面
- 📺 实时日志查看
- 📊 测速结果可视化
- 📜 历史记录管理
- ⏰ 定时测速任务
- 🚀 自动应用最优 IP
- 📝 自定义 IP 段
- 📤 结果导出 (CSV/JSON)

### 第三方应用联动
- 🔗 **Shadowsocksr Plus+** - 自动更新节点 IP
- 🔗 **PassWall2** - 自动更新节点地址
- 🔗 **Bypass** - 自动更新服务器
- 🔗 **OpenClash** - 自动更新配置
- 🔗 **MosDNS** - 自动更新 IP 文件
- 🔗 **Hosts** - 自动添加域名解析
- 🔗 **DNS/dnsmasq** - 自动添加 DNS 记录

## 📦 下载安装

### 从 Releases 下载

前往 [Releases 页面](https://github.com/zhengwuji/CloudflareSpeedTest-GUI/releases) 下载最新版本。

| 平台 | 文件 | 说明 |
|------|------|------|
| Windows | `CloudflareSpeedTest-GUI.exe` | Windows 7+ 双击运行 |
| OpenWrt | `luci-app-cfspeedtest_x.x.x_all.ipk` | **推荐** OpenWrt 21.02+ / Kwrt / iStoreOS |
| OpenWrt | `luci-app-cfspeedtest_x.x.x_legacy.ipk` | OpenWrt 18.x - 22.x 传统版本 |
| OpenWrt | `luci-clear-cache_1.0.0_all.ipk` | LuCI 缓存管理工具 (独立) |

### OpenWrt 安装命令

```bash
# 上传 ipk 文件到 /tmp 目录后执行
opkg install /tmp/luci-app-cfspeedtest_x.x.x_all.ipk

# 清除缓存并刷新
rm -rf /tmp/luci-*
```

## 🖼️ 界面预览

### Windows 版
- 现代化深色主题界面
- 实时显示测速进度
- 表格显示测速结果
- 系统托盘最小化

### OpenWrt LuCI 版

安装后在 **服务 → CF优选IP** 中访问：

| 菜单 | 功能 |
|------|------|
| 基本设置 | 测速参数配置、测速控制 |
| 实时日志 | 查看测速进度和日志 |
| 测速结果 | 可视化显示测速结果 |
| 历史记录 | 查看历史测速记录 |
| 定时任务 | 配置定时自动测速 |
| 自定义IP | 管理自定义 IP 段 |
| 高级设置 | 代理设置、版本管理 |
| 第三方应用 | 配置第三方应用联动 |

## 🔧 使用说明

### 基本测速参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| 延迟线程数 | 同时测试延迟的线程数 | 200 |
| 延迟测试次数 | 每个 IP 测试次数 | 4 |
| 下载测速数量 | 进行下载测速的 IP 数量 | 10 |
| 下载测速时间 | 每个 IP 下载测速时长(秒) | 10 |
| 测速端口 | 使用的端口号 | 443 |
| 平均延迟上限 | 过滤高延迟 IP (ms) | 9999 |
| 下载速度下限 | 过滤低速 IP (MB/s) | 0 |

### HTTPing 模式

启用 HTTPing 模式时可以指定数据中心地区码：

```
HKG - 香港
KHH - 高雄
NRT - 东京成田
LAX - 洛杉矶
SIN - 新加坡
ICN - 首尔
```

多个地区用逗号分隔：`HKG,KHH,NRT,LAX`

### 第三方应用联动配置

1. 进入 **服务 → CF优选IP → 第三方应用**
2. 选择要联动的应用标签页
3. 开启对应应用
4. 填写节点 ID 或配置项
5. 保存设置

测速完成后会自动将最优 IP 应用到配置的第三方应用。

## 🧹 LuCI 缓存管理工具

独立的 LuCI 缓存清除工具，解决安装应用后页面显示异常的问题。

### 功能
- ✅ 安装/卸载 IPK 时自动清除缓存
- ✅ 手动清除缓存按钮
- ✅ 可配置开关

### 安装
```bash
opkg install luci-clear-cache_1.0.0_all.ipk
```

### 位置
**系统 → LuCI缓存管理**

### 命令行使用
```bash
clear_luci_cache
```

## 📋 更新日志

### v1.0.x
- ✅ Windows 图形界面
- ✅ OpenWrt LuCI 界面 (JS 版本)
- ✅ OpenWrt LuCI 界面 (Legacy 版本)
- ✅ 第三方应用联动 (SSR Plus+, PassWall2, Bypass, OpenClash, MosDNS)
- ✅ 定时测速任务
- ✅ 自定义 IP 段
- ✅ 历史记录管理
- ✅ LuCI 缓存管理工具

## 🙏 致谢

- [XIU2/CloudflareSpeedTest](https://github.com/XIU2/CloudflareSpeedTest) - 核心测速引擎
- [OpenWrt](https://openwrt.org/) - 路由器固件
- [LuCI](https://github.com/openwrt/luci) - Web 管理界面

## 📄 许可证

MIT License

## ⭐ Star History

如果觉得有帮助，请给个 ⭐ Star 支持一下！

---

**Made with ❤️ by zhengwuji**
