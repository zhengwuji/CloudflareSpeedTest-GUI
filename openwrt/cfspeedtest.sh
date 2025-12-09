#!/bin/sh

# CloudflareSpeedTest 执行脚本
# 用于 OpenWrt LuCI 界面

CONFIG_FILE="/etc/config/cfspeedtest"
RESULT_FILE="/tmp/cfspeedtest_result.csv"
LOG_FILE="/tmp/cfspeedtest.log"
IP_FILE="/tmp/ip.txt"

# 下载 CloudflareST 二进制文件 (如果不存在)
download_cfst() {
    if [ ! -f "/usr/bin/CloudflareST" ]; then
        echo "正在下载 CloudflareST..." >> $LOG_FILE
        
        # 获取架构
        ARCH=$(uname -m)
        case $ARCH in
            x86_64) ARCH_NAME="amd64" ;;
            aarch64) ARCH_NAME="arm64" ;;
            armv7l) ARCH_NAME="arm" ;;
            mips) ARCH_NAME="mips" ;;
            mipsel) ARCH_NAME="mipsle" ;;
            *) echo "不支持的架构: $ARCH" >> $LOG_FILE; exit 1 ;;
        esac
        
        DOWNLOAD_URL="https://github.com/XIU2/CloudflareSpeedTest/releases/latest/download/CloudflareST_linux_${ARCH_NAME}.tar.gz"
        
        # 尝试多个下载源
        URLS="
            https://mirror.ghproxy.com/${DOWNLOAD_URL}
            https://ghproxy.com/${DOWNLOAD_URL}
            ${DOWNLOAD_URL}
        "
        
        for url in $URLS; do
            wget -q -O /tmp/cfst.tar.gz "$url" && break
        done
        
        if [ -f "/tmp/cfst.tar.gz" ]; then
            tar -xzf /tmp/cfst.tar.gz -C /tmp
            mv /tmp/CloudflareST /usr/bin/
            chmod +x /usr/bin/CloudflareST
            rm -f /tmp/cfst.tar.gz
            echo "CloudflareST 下载完成" >> $LOG_FILE
        else
            echo "CloudflareST 下载失败" >> $LOG_FILE
            exit 1
        fi
    fi
}

# 下载 IP 库
download_ip() {
    echo "正在更新 IP 库..." >> $LOG_FILE
    
    URLS="
        https://mirror.ghproxy.com/https://raw.githubusercontent.com/XIU2/CloudflareSpeedTest/master/ip.txt
        https://ghproxy.com/https://raw.githubusercontent.com/XIU2/CloudflareSpeedTest/master/ip.txt
        https://cdn.jsdelivr.net/gh/XIU2/CloudflareSpeedTest@master/ip.txt
        https://raw.githubusercontent.com/XIU2/CloudflareSpeedTest/master/ip.txt
    "
    
    for url in $URLS; do
        wget -q -O $IP_FILE "$url" && break
    done
    
    if [ -f "$IP_FILE" ] && [ -s "$IP_FILE" ]; then
        echo "IP 库更新成功" >> $LOG_FILE
    else
        echo "IP 库更新失败，使用默认" >> $LOG_FILE
    fi
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
}

# 构建命令
build_cmd() {
    CMD="/usr/bin/CloudflareST"
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
    [ -n "$CFCOLO" ] && CMD="$CMD -cfcolo $CFCOLO"
    [ "$DISABLE_DL" = "1" ] && CMD="$CMD -dd"
    [ "$TEST_ALL" = "1" ] && CMD="$CMD -allip"
    
    echo $CMD
}

# 主函数
main() {
    echo "========== 开始测速 $(date) ==========" > $LOG_FILE
    
    download_cfst
    download_ip
    read_config
    
    CMD=$(build_cmd)
    echo "执行命令: $CMD" >> $LOG_FILE
    
    cd /tmp
    eval $CMD >> $LOG_FILE 2>&1
    
    echo "========== 测速完成 $(date) ==========" >> $LOG_FILE
    
    # 显示最优 IP
    if [ -f "$RESULT_FILE" ]; then
        BEST_IP=$(sed -n '2p' $RESULT_FILE | cut -d',' -f1)
        echo "最优 IP: $BEST_IP" >> $LOG_FILE
    fi
}

main
