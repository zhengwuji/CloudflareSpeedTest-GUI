#!/bin/sh

# 更新 CloudflareST 脚本

LOG_FILE="/tmp/cfspeedtest_update.log"
CFST_BIN="/usr/bin/CloudflareST"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $LOG_FILE
}

log "开始更新 CloudflareST..."

# 获取架构
ARCH=$(uname -m)
case $ARCH in
    x86_64) ARCH_NAME="amd64" ;;
    aarch64) ARCH_NAME="arm64" ;;
    armv7l|armv7) ARCH_NAME="arm" ;;
    mips) ARCH_NAME="mips" ;;
    mipsel) ARCH_NAME="mipsle" ;;
    *) log "不支持的架构: $ARCH"; exit 1 ;;
esac

# 获取代理设置
use_proxy=$(uci -q get cfspeedtest.config.use_proxy || echo "1")
proxy_source=$(uci -q get cfspeedtest.config.proxy_source || echo "mirror")

get_proxy() {
    if [ "$use_proxy" = "1" ]; then
        case $proxy_source in
            ghproxy) echo "https://ghproxy.com/" ;;
            mirror) echo "https://mirror.ghproxy.com/" ;;
            *) echo "https://mirror.ghproxy.com/" ;;
        esac
    fi
}

PROXY=$(get_proxy)
BASE_URL="https://github.com/XIU2/CloudflareSpeedTest/releases/latest/download"
FILE_NAME="CloudflareST_linux_${ARCH_NAME}.tar.gz"

URLS="
    ${PROXY}${BASE_URL}/${FILE_NAME}
    https://mirror.ghproxy.com/${BASE_URL}/${FILE_NAME}
    ${BASE_URL}/${FILE_NAME}
"

# 备份旧版本
[ -f "$CFST_BIN" ] && cp $CFST_BIN ${CFST_BIN}.bak

for url in $URLS; do
    [ -z "$url" ] && continue
    log "尝试: $url"
    wget -q --timeout=60 -O /tmp/cfst.tar.gz "$url" 2>/dev/null
    if [ $? -eq 0 ] && [ -s /tmp/cfst.tar.gz ]; then
        tar -xzf /tmp/cfst.tar.gz -C /tmp 2>/dev/null
        if [ -f /tmp/CloudflareST ]; then
            mv /tmp/CloudflareST $CFST_BIN
            chmod +x $CFST_BIN
            rm -f /tmp/cfst.tar.gz ${CFST_BIN}.bak
            
            VERSION=$($CFST_BIN -v 2>&1 | head -1)
            log "更新成功: $VERSION"
            exit 0
        fi
    fi
done

# 恢复旧版本
[ -f "${CFST_BIN}.bak" ] && mv ${CFST_BIN}.bak $CFST_BIN

log "更新失败"
exit 1
