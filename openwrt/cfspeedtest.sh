#!/bin/sh

# CloudflareSpeedTest 执行脚本
# 用于 OpenWrt LuCI 界面 - 增强版

CONFIG_FILE="/etc/config/cfspeedtest"
RESULT_FILE="/tmp/cfspeedtest_result.csv"
LOG_FILE="/tmp/cfspeedtest.log"
IP_FILE="/tmp/ip.txt"
CUSTOM_IP_FILE="/etc/cfspeedtest/custom_ip.txt"
HISTORY_FILE="/etc/cfspeedtest/history.json"
CFST_BIN="/usr/bin/CloudflareST"

# 创建必要目录
mkdir -p /etc/cfspeedtest

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $LOG_FILE
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# 获取代理URL
get_proxy_url() {
    local use_proxy=$(uci -q get cfspeedtest.config.use_proxy || echo "1")
    local proxy_source=$(uci -q get cfspeedtest.config.proxy_source || echo "mirror")
    local custom_proxy=$(uci -q get cfspeedtest.config.custom_proxy || echo "")
    
    if [ "$use_proxy" = "1" ]; then
        case $proxy_source in
            ghproxy) echo "https://ghproxy.com/" ;;
            mirror) echo "https://mirror.ghproxy.com/" ;;
            fastgit) echo "https://raw.fastgit.org/" ;;
            custom) echo "$custom_proxy" ;;
            *) echo "https://mirror.ghproxy.com/" ;;
        esac
    else
        echo ""
    fi
}

# 下载 CloudflareST 二进制文件
download_cfst() {
    if [ -f "$CFST_BIN" ]; then
        log "CloudflareST 已安装"
        return 0
    fi
    
    log "正在下载 CloudflareST..."
    
    # 获取架构
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) ARCH_NAME="amd64" ;;
        aarch64) ARCH_NAME="arm64" ;;
        armv7l|armv7) ARCH_NAME="arm" ;;
        mips) ARCH_NAME="mips" ;;
        mipsel) ARCH_NAME="mipsle" ;;
        *) log "不支持的架构: $ARCH"; return 1 ;;
    esac
    
    local PROXY=$(get_proxy_url)
    local BASE_URL="https://github.com/XIU2/CloudflareSpeedTest/releases/latest/download"
    local FILE_NAME="CloudflareST_linux_${ARCH_NAME}.tar.gz"
    
    # 尝试多个下载源
    local URLS="
        ${PROXY}${BASE_URL}/${FILE_NAME}
        https://mirror.ghproxy.com/${BASE_URL}/${FILE_NAME}
        https://ghproxy.com/${BASE_URL}/${FILE_NAME}
        ${BASE_URL}/${FILE_NAME}
    "
    
    for url in $URLS; do
        [ -z "$url" ] && continue
        log "尝试下载: $url"
        wget -q --timeout=30 -O /tmp/cfst.tar.gz "$url" 2>/dev/null
        if [ $? -eq 0 ] && [ -s /tmp/cfst.tar.gz ]; then
            tar -xzf /tmp/cfst.tar.gz -C /tmp 2>/dev/null
            if [ -f /tmp/CloudflareST ]; then
                mv /tmp/CloudflareST $CFST_BIN
                chmod +x $CFST_BIN
                rm -f /tmp/cfst.tar.gz
                log "CloudflareST 下载完成"
                return 0
            fi
        fi
    done
    
    log "CloudflareST 下载失败"
    return 1
}

# 下载 IP 库
download_ip() {
    local use_custom=$(uci -q get cfspeedtest.config.use_custom_ip || echo "0")
    
    if [ "$use_custom" = "1" ] && [ -f "$CUSTOM_IP_FILE" ]; then
        log "使用自定义 IP 段"
        cp "$CUSTOM_IP_FILE" "$IP_FILE"
        return 0
    fi
    
    log "正在更新 IP 库..."
    
    local PROXY=$(get_proxy_url)
    local RAW_URL="https://raw.githubusercontent.com/XIU2/CloudflareSpeedTest/master/ip.txt"
    
    local URLS="
        ${PROXY}${RAW_URL}
        https://mirror.ghproxy.com/${RAW_URL}
        https://ghproxy.com/${RAW_URL}
        https://cdn.jsdelivr.net/gh/XIU2/CloudflareSpeedTest@master/ip.txt
        https://fastly.jsdelivr.net/gh/XIU2/CloudflareSpeedTest@master/ip.txt
        ${RAW_URL}
    "
    
    for url in $URLS; do
        [ -z "$url" ] && continue
        log "尝试下载 IP 库: $url"
        wget -q --timeout=15 -O $IP_FILE "$url" 2>/dev/null
        if [ $? -eq 0 ] && [ -s $IP_FILE ]; then
            local lines=$(wc -l < $IP_FILE)
            log "IP 库更新成功，共 $lines 行"
            return 0
        fi
    done
    
    log "IP 库更新失败"
    return 1
}

# 读取配置
read_config() {
    THREAD=$(uci -q get cfspeedtest.config.thread || echo "200")
    COUNT=$(uci -q get cfspeedtest.config.count || echo "4")
    DN=$(uci -q get cfspeedtest.config.download_num || echo "10")
    DT=$(uci -q get cfspeedtest.config.download_time || echo "10")
    PORT=$(uci -q get cfspeedtest.config.port || echo "443")
    URL=$(uci -q get cfspeedtest.config.url || echo "https://cf.xiu2.xyz/url")
    HTTPING=$(uci -q get cfspeedtest.config.httping || echo "0")
    CFCOLO=$(uci -q get cfspeedtest.config.cfcolo || echo "")
    TL=$(uci -q get cfspeedtest.config.tl || echo "9999")
    TLL=$(uci -q get cfspeedtest.config.tll || echo "0")
    TLR=$(uci -q get cfspeedtest.config.tlr || echo "1.00")
    SL=$(uci -q get cfspeedtest.config.sl || echo "0")
    RESULT_NUM=$(uci -q get cfspeedtest.config.result_num || echo "10")
    DISABLE_DL=$(uci -q get cfspeedtest.config.disable_download || echo "0")
    TEST_ALL=$(uci -q get cfspeedtest.config.test_all || echo "0")
    AUTO_APPLY=$(uci -q get cfspeedtest.config.auto_apply || echo "0")
    APPLY_TARGET=$(uci -q get cfspeedtest.config.apply_target || echo "hosts")
}

# 构建命令
build_cmd() {
    CMD="$CFST_BIN"
    CMD="$CMD -n $THREAD"
    CMD="$CMD -t $COUNT"
    CMD="$CMD -dn $DN"
    CMD="$CMD -dt $DT"
    CMD="$CMD -tp $PORT"
    CMD="$CMD -url $URL"
    CMD="$CMD -tl $TL"
    CMD="$CMD -tll $TLL"
    CMD="$CMD -tlr $TLR"
    CMD="$CMD -sl $SL"
    CMD="$CMD -p $RESULT_NUM"
    CMD="$CMD -f $IP_FILE"
    CMD="$CMD -o $RESULT_FILE"
    
    [ "$HTTPING" = "1" ] && CMD="$CMD -httping"
    [ -n "$CFCOLO" ] && [ "$HTTPING" = "1" ] && CMD="$CMD -cfcolo $CFCOLO"
    [ "$DISABLE_DL" = "1" ] && CMD="$CMD -dd"
    [ "$TEST_ALL" = "1" ] && CMD="$CMD -allip"
    
    echo $CMD
}

# 保存历史记录
save_history() {
    if [ ! -f "$RESULT_FILE" ]; then
        return
    fi
    
    local BEST_IP=$(sed -n '2p' $RESULT_FILE | cut -d',' -f1)
    local BEST_LATENCY=$(sed -n '2p' $RESULT_FILE | cut -d',' -f3)
    local BEST_SPEED=$(sed -n '2p' $RESULT_FILE | cut -d',' -f5)
    local TOTAL=$(wc -l < $RESULT_FILE)
    TOTAL=$((TOTAL - 1))
    
    local TIME=$(date '+%Y-%m-%d %H:%M:%S')
    
    # 读取现有历史
    local HISTORY="[]"
    if [ -f "$HISTORY_FILE" ]; then
        HISTORY=$(cat $HISTORY_FILE 2>/dev/null || echo "[]")
    fi
    
    # 添加新记录 (使用简单的 JSON 操作)
    local NEW_RECORD="{\"time\":\"$TIME\",\"best_ip\":\"$BEST_IP\",\"best_latency\":\"$BEST_LATENCY\",\"best_speed\":\"$BEST_SPEED\",\"total_results\":$TOTAL}"
    
    # 保存 (最多50条)
    echo "$HISTORY" | sed 's/^\[//' | sed 's/\]$//' > /tmp/history_tmp.txt
    if [ -s /tmp/history_tmp.txt ]; then
        echo "[$NEW_RECORD,$(head -c 10000 /tmp/history_tmp.txt)]" | sed 's/,\]/]/' > $HISTORY_FILE
    else
        echo "[$NEW_RECORD]" > $HISTORY_FILE
    fi
    rm -f /tmp/history_tmp.txt
    
    log "历史记录已保存"
}

# 自动应用最优IP
auto_apply() {
    if [ "$AUTO_APPLY" != "1" ]; then
        return
    fi
    
    local BEST_IP=$(sed -n '2p' $RESULT_FILE | cut -d',' -f1)
    if [ -z "$BEST_IP" ]; then
        log "没有找到最优 IP"
        return
    fi
    
    log "自动应用最优 IP: $BEST_IP 到 $APPLY_TARGET"
    
    case $APPLY_TARGET in
        hosts)
            local DOMAINS=$(uci -q get cfspeedtest.config.apply_domains || echo "cf.example.com")
            for domain in $DOMAINS; do
                sed -i "/$domain/d" /etc/hosts
                echo "$BEST_IP $domain" >> /etc/hosts
            done
            /etc/init.d/dnsmasq restart
            log "已应用到 hosts"
            ;;
        passwall)
            local NODE=$(uci -q get cfspeedtest.config.passwall_node)
            if [ -n "$NODE" ]; then
                uci set passwall.$NODE.address="$BEST_IP"
                uci commit passwall
                /etc/init.d/passwall restart
                log "已应用到 Passwall"
            fi
            ;;
        ssrplus)
            local NODE=$(uci -q get cfspeedtest.config.ssrplus_node)
            if [ -n "$NODE" ]; then
                uci set shadowsocksr.$NODE.server="$BEST_IP"
                uci commit shadowsocksr
                /etc/init.d/shadowsocksr restart
                log "已应用到 SSR Plus"
            fi
            ;;
        openclash)
            echo "$BEST_IP" > /etc/openclash/custom/openclash_custom_hosts.list
            /etc/init.d/openclash restart
            log "已应用到 OpenClash"
            ;;
    esac
}

# 主函数
main() {
    echo "" > $LOG_FILE
    log "=========================================="
    log "CloudflareSpeedTest 开始测速"
    log "=========================================="
    
    # 下载必要文件
    download_cfst || exit 1
    download_ip || exit 1
    
    # 读取配置
    read_config
    
    # 构建并执行命令
    CMD=$(build_cmd)
    log "执行命令: $CMD"
    log "------------------------------------------"
    
    cd /tmp
    eval $CMD 2>&1 | while read line; do
        echo "$line"
        echo "$line" >> $LOG_FILE
    done
    
    log "------------------------------------------"
    log "测速完成"
    
    # 显示最优结果
    if [ -f "$RESULT_FILE" ]; then
        local BEST_IP=$(sed -n '2p' $RESULT_FILE | cut -d',' -f1)
        local BEST_LATENCY=$(sed -n '2p' $RESULT_FILE | cut -d',' -f3)
        local BEST_SPEED=$(sed -n '2p' $RESULT_FILE | cut -d',' -f5)
        log "最优 IP: $BEST_IP"
        log "延迟: ${BEST_LATENCY}ms"
        log "速度: ${BEST_SPEED}MB/s"
        
        # 保存历史
        save_history
        
        # 自动应用
        auto_apply
        
        # 应用到第三方应用
        if [ -x "/usr/bin/cfspeedtest_apply" ]; then
            log "执行第三方应用联动..."
            /usr/bin/cfspeedtest_apply
        fi
    fi
    
    log "=========================================="
}

# 执行
main
