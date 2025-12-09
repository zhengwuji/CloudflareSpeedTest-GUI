#!/bin/sh
# LuCI 缓存清除工具

echo "正在清除 LuCI 缓存..."
rm -rf /tmp/luci-*
echo "LuCI 缓存已清除"

echo "正在重启 rpcd 服务..."
/etc/init.d/rpcd restart 2>/dev/null

echo "完成！请刷新浏览器页面。"
