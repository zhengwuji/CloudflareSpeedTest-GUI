#!/bin/sh

# 自动应用最优IP到第三方应用
# 由测速脚本完成后调用

LOG_FILE="/tmp/cfspeedtest.log"
RESULT_FILE="/tmp/cfspeedtest_result.csv"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [第三方应用] $1" >> $LOG_FILE
}

# 获取最优IP
get_best_ip() {
    if [ -f "$RESULT_FILE" ]; then
        sed -n '2p' $RESULT_FILE | cut -d',' -f1
    fi
}

BEST_IP=$(get_best_ip)
if [ -z "$BEST_IP" ]; then
    log "没有找到最优IP"
    exit 1
fi

log "最优IP: $BEST_IP"

# ========== ShadowsocksR Plus+ ==========
apply_ssrplus() {
    local enabled=$(uci -q get cfspeedtest.config.ssrplus_enabled || echo "0")
    [ "$enabled" != "1" ] && return
    
    local server=$(uci -q get cfspeedtest.config.ssrplus_server)
    local field=$(uci -q get cfspeedtest.config.ssrplus_field || echo "server")
    local restart=$(uci -q get cfspeedtest.config.ssrplus_restart || echo "1")
    
    if [ -n "$server" ]; then
        log "应用到 ShadowsocksR Plus+: 节点=$server, 字段=$field"
        uci set shadowsocksr.$server.$field="$BEST_IP"
        uci commit shadowsocksr
        
        if [ "$restart" = "1" ]; then
            /etc/init.d/shadowsocksr restart 2>/dev/null
            log "ShadowsocksR Plus+ 已重启"
        fi
    else
        log "ShadowsocksR Plus+ 未配置节点"
    fi
}

# ========== PassWall2 ==========
apply_passwall2() {
    local enabled=$(uci -q get cfspeedtest.config.passwall2_enabled || echo "0")
    [ "$enabled" != "1" ] && return
    
    local node=$(uci -q get cfspeedtest.config.passwall2_node)
    local field=$(uci -q get cfspeedtest.config.passwall2_field || echo "address")
    local restart=$(uci -q get cfspeedtest.config.passwall2_restart || echo "1")
    
    if [ -n "$node" ]; then
        log "应用到 PassWall2: 节点=$node, 字段=$field"
        uci set passwall2.$node.$field="$BEST_IP"
        uci commit passwall2
        
        if [ "$restart" = "1" ]; then
            /etc/init.d/passwall2 restart 2>/dev/null
            log "PassWall2 已重启"
        fi
    else
        log "PassWall2 未配置节点"
    fi
}

# ========== Bypass ==========
apply_bypass() {
    local enabled=$(uci -q get cfspeedtest.config.bypass_enabled || echo "0")
    [ "$enabled" != "1" ] && return
    
    local server=$(uci -q get cfspeedtest.config.bypass_server)
    local restart=$(uci -q get cfspeedtest.config.bypass_restart || echo "1")
    
    if [ -n "$server" ]; then
        log "应用到 Bypass: 节点=$server"
        uci set bypass.$server.server="$BEST_IP"
        uci commit bypass
        
        if [ "$restart" = "1" ]; then
            /etc/init.d/bypass restart 2>/dev/null
            log "Bypass 已重启"
        fi
    else
        log "Bypass 未配置节点"
    fi
}

# ========== DNS ==========
apply_dns() {
    local enabled=$(uci -q get cfspeedtest.config.dns_enabled || echo "0")
    [ "$enabled" != "1" ] && return
    
    local domain=$(uci -q get cfspeedtest.config.dns_domain)
    local restart=$(uci -q get cfspeedtest.config.dns_restart || echo "1")
    
    if [ -n "$domain" ]; then
        log "应用到 DNS: 域名=$domain"
        # 添加到 dnsmasq 配置
        uci -q delete dhcp.cfspeedtest
        uci set dhcp.cfspeedtest=domain
        uci set dhcp.cfspeedtest.name="$domain"
        uci set dhcp.cfspeedtest.ip="$BEST_IP"
        uci commit dhcp
        
        if [ "$restart" = "1" ]; then
            /etc/init.d/dnsmasq restart 2>/dev/null
            log "dnsmasq 已重启"
        fi
    else
        log "DNS 未配置域名"
    fi
}

# ========== HOST ==========
apply_host() {
    local enabled=$(uci -q get cfspeedtest.config.host_enabled || echo "0")
    [ "$enabled" != "1" ] && return
    
    local restart=$(uci -q get cfspeedtest.config.host_restart || echo "1")
    
    # 获取域名列表
    local domains=$(uci -q get cfspeedtest.config.host_domains)
    
    if [ -n "$domains" ]; then
        log "应用到 HOST: 域名=$domains"
        
        # 删除旧的 cfspeedtest 标记的条目
        sed -i '/#cfspeedtest$/d' /etc/hosts
        
        # 添加新条目
        for domain in $domains; do
            echo "$BEST_IP $domain #cfspeedtest" >> /etc/hosts
            log "添加 HOST: $BEST_IP -> $domain"
        done
        
        if [ "$restart" = "1" ]; then
            /etc/init.d/dnsmasq restart 2>/dev/null
            log "dnsmasq 已重启 (HOST)"
        fi
    else
        log "HOST 未配置域名"
    fi
}

# ========== MosDNS ==========
apply_mosdns() {
    local enabled=$(uci -q get cfspeedtest.config.mosdns_enabled || echo "0")
    [ "$enabled" != "1" ] && return
    
    local file=$(uci -q get cfspeedtest.config.mosdns_file || echo "/etc/mosdns/rule/cloudflare.txt")
    local restart=$(uci -q get cfspeedtest.config.mosdns_restart || echo "1")
    
    log "应用到 MosDNS: 文件=$file"
    
    # 确保目录存在
    mkdir -p $(dirname "$file")
    
    # 写入IP
    echo "$BEST_IP" > "$file"
    log "已写入 IP 到 $file"
    
    if [ "$restart" = "1" ]; then
        /etc/init.d/mosdns restart 2>/dev/null
        log "MosDNS 已重启"
    fi
}

# ========== OpenClash ==========
apply_openclash() {
    local enabled=$(uci -q get cfspeedtest.config.openclash_enabled || echo "0")
    [ "$enabled" != "1" ] && return
    
    local restart=$(uci -q get cfspeedtest.config.openclash_restart || echo "1")
    
    log "应用到 OpenClash"
    
    # 写入自定义 hosts
    mkdir -p /etc/openclash/custom
    echo "$BEST_IP" > /etc/openclash/custom/openclash_custom_hosts.list
    
    if [ "$restart" = "1" ]; then
        /etc/init.d/openclash restart 2>/dev/null
        log "OpenClash 已重启"
    fi
}

# 执行所有应用
log "========== 开始应用到第三方应用 =========="
apply_ssrplus
apply_passwall2
apply_bypass
apply_dns
apply_host
apply_mosdns
apply_openclash
log "========== 第三方应用应用完成 =========="
