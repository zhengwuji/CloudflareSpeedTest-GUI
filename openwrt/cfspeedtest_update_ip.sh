#!/bin/sh

# 更新 IP 库脚本

LOG_FILE="/tmp/cfspeedtest_update.log"
IP_FILE="/tmp/ip.txt"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $LOG_FILE
}

log "开始更新 IP 库..."

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
RAW_URL="https://raw.githubusercontent.com/XIU2/CloudflareSpeedTest/master/ip.txt"

URLS="
    ${PROXY}${RAW_URL}
    https://cdn.jsdelivr.net/gh/XIU2/CloudflareSpeedTest@master/ip.txt
    ${RAW_URL}
"

for url in $URLS; do
    [ -z "$url" ] && continue
    log "尝试: $url"
    wget -q --timeout=15 -O $IP_FILE "$url" 2>/dev/null
    if [ $? -eq 0 ] && [ -s $IP_FILE ]; then
        lines=$(wc -l < $IP_FILE)
        log "更新成功，共 $lines 行"
        exit 0
    fi
done

log "更新失败"
exit 1
