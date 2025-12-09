module("luci.controller.cfspeedtest", package.seeall)

local fs = require "nixio.fs"
local sys = require "luci.sys"
local http = require "luci.http"
local json = require "luci.jsonc"

function index()
    entry({"admin", "services", "cfspeedtest"}, alias("admin", "services", "cfspeedtest", "settings"), _("CF优选IP"), 80).dependent = true
    entry({"admin", "services", "cfspeedtest", "settings"}, cbi("cfspeedtest/settings"), _("基本设置"), 1).leaf = true
    entry({"admin", "services", "cfspeedtest", "log"}, cbi("cfspeedtest/log"), _("实时日志"), 2).leaf = true
    entry({"admin", "services", "cfspeedtest", "result"}, cbi("cfspeedtest/result"), _("测速结果"), 3).leaf = true
    entry({"admin", "services", "cfspeedtest", "history"}, cbi("cfspeedtest/history"), _("历史记录"), 4).leaf = true
    entry({"admin", "services", "cfspeedtest", "schedule"}, cbi("cfspeedtest/schedule"), _("定时任务"), 5).leaf = true
    entry({"admin", "services", "cfspeedtest", "iplist"}, cbi("cfspeedtest/iplist"), _("自定义IP"), 6).leaf = true
    entry({"admin", "services", "cfspeedtest", "advanced"}, cbi("cfspeedtest/advanced"), _("高级设置"), 7).leaf = true
    
    -- API 接口
    entry({"admin", "services", "cfspeedtest", "api", "status"}, call("api_status")).leaf = true
    entry({"admin", "services", "cfspeedtest", "api", "run"}, call("api_run")).leaf = true
    entry({"admin", "services", "cfspeedtest", "api", "stop"}, call("api_stop")).leaf = true
    entry({"admin", "services", "cfspeedtest", "api", "log"}, call("api_log")).leaf = true
    entry({"admin", "services", "cfspeedtest", "api", "result"}, call("api_result")).leaf = true
    entry({"admin", "services", "cfspeedtest", "api", "history"}, call("api_history")).leaf = true
    entry({"admin", "services", "cfspeedtest", "api", "update_ip"}, call("api_update_ip")).leaf = true
    entry({"admin", "services", "cfspeedtest", "api", "update_cfst"}, call("api_update_cfst")).leaf = true
    entry({"admin", "services", "cfspeedtest", "api", "cfst_version"}, call("api_cfst_version")).leaf = true
    entry({"admin", "services", "cfspeedtest", "api", "apply_best"}, call("api_apply_best")).leaf = true
    entry({"admin", "services", "cfspeedtest", "api", "export"}, call("api_export")).leaf = true
    entry({"admin", "services", "cfspeedtest", "api", "clear_history"}, call("api_clear_history")).leaf = true
    entry({"admin", "services", "cfspeedtest", "api", "clear_cache"}, call("api_clear_cache")).leaf = true
end

-- 获取状态
function api_status()
    local e = {}
    e.running = sys.call("pgrep -f CloudflareST > /dev/null") == 0
    e.cfst_exists = fs.access("/usr/bin/CloudflareST")
    e.ip_exists = fs.access("/tmp/ip.txt") or fs.access("/etc/cfspeedtest/ip.txt")
    
    -- 获取最优IP
    local result_file = "/tmp/cfspeedtest_result.csv"
    if fs.access(result_file) then
        local file = io.open(result_file, "r")
        if file then
            file:read("*line") -- 跳过表头
            local line = file:read("*line")
            if line then
                local parts = {}
                for part in line:gmatch("[^,]+") do
                    table.insert(parts, part)
                end
                if #parts >= 5 then
                    e.best_ip = parts[1]
                    e.best_latency = parts[3]
                    e.best_speed = parts[5]
                end
            end
            file:close()
        end
    end
    
    http.prepare_content("application/json")
    http.write_json(e)
end

-- 开始测速
function api_run()
    sys.call("/usr/bin/cfspeedtest > /tmp/cfspeedtest.log 2>&1 &")
    http.prepare_content("application/json")
    http.write_json({status = "started"})
end

-- 停止测速
function api_stop()
    sys.call("killall -9 CloudflareST 2>/dev/null")
    http.prepare_content("application/json")
    http.write_json({status = "stopped"})
end

-- 获取日志
function api_log()
    local log = ""
    local log_file = "/tmp/cfspeedtest.log"
    if fs.access(log_file) then
        log = fs.readfile(log_file) or ""
    end
    http.prepare_content("application/json")
    http.write_json({log = log})
end

-- 获取结果
function api_result()
    local result = {}
    local result_file = "/tmp/cfspeedtest_result.csv"
    if fs.access(result_file) then
        local file = io.open(result_file, "r")
        if file then
            local header = file:read("*line")
            for line in file:lines() do
                local parts = {}
                for part in line:gmatch("[^,]+") do
                    table.insert(parts, part)
                end
                if #parts >= 5 then
                    table.insert(result, {
                        ip = parts[1],
                        port = parts[2],
                        latency = parts[3],
                        loss = parts[4],
                        speed = parts[5],
                        location = parts[6] or ""
                    })
                end
            end
            file:close()
        end
    end
    http.prepare_content("application/json")
    http.write_json(result)
end

-- 获取历史记录
function api_history()
    local history = {}
    local history_file = "/etc/cfspeedtest/history.json"
    if fs.access(history_file) then
        local content = fs.readfile(history_file)
        if content then
            history = json.parse(content) or {}
        end
    end
    http.prepare_content("application/json")
    http.write_json(history)
end

-- 清空历史
function api_clear_history()
    fs.remove("/etc/cfspeedtest/history.json")
    http.prepare_content("application/json")
    http.write_json({status = "cleared"})
end

-- 清除LuCI缓存
function api_clear_cache()
    sys.call("rm -rf /tmp/luci-*")
    sys.call("/etc/init.d/rpcd restart 2>/dev/null")
    http.prepare_content("application/json")
    http.write_json({status = "cleared", message = "LuCI缓存已清除"})
end

-- 更新IP库
function api_update_ip()
    sys.call("/usr/bin/cfspeedtest_update_ip > /tmp/cfspeedtest_update.log 2>&1 &")
    http.prepare_content("application/json")
    http.write_json({status = "updating"})
end

-- 更新CloudflareST
function api_update_cfst()
    sys.call("/usr/bin/cfspeedtest_update_cfst > /tmp/cfspeedtest_update.log 2>&1 &")
    http.prepare_content("application/json")
    http.write_json({status = "updating"})
end

-- 获取CloudflareST版本
function api_cfst_version()
    local version = "未安装"
    if fs.access("/usr/bin/CloudflareST") then
        local result = sys.exec("/usr/bin/CloudflareST -v 2>&1 | head -1")
        if result then
            version = result:match("v[%d%.]+") or result:gsub("%s+", " ")
        end
    end
    
    -- 获取最新版本
    local latest = "未知"
    local latest_result = sys.exec("wget -qO- 'https://api.github.com/repos/XIU2/CloudflareSpeedTest/releases/latest' 2>/dev/null | grep -o '\"tag_name\":\"[^\"]*' | cut -d'\"' -f4")
    if latest_result and latest_result ~= "" then
        latest = latest_result:gsub("%s+", "")
    end
    
    http.prepare_content("application/json")
    http.write_json({current = version, latest = latest})
end

-- 应用最优IP
function api_apply_best()
    local target = http.formvalue("target") or "hosts"
    local result_file = "/tmp/cfspeedtest_result.csv"
    local best_ip = nil
    
    if fs.access(result_file) then
        local file = io.open(result_file, "r")
        if file then
            file:read("*line")
            local line = file:read("*line")
            if line then
                best_ip = line:match("^([^,]+)")
            end
            file:close()
        end
    end
    
    if not best_ip then
        http.prepare_content("application/json")
        http.write_json({status = "error", message = "没有找到测速结果"})
        return
    end
    
    local success = false
    local message = ""
    
    if target == "hosts" then
        -- 应用到 hosts
        local domains = luci.model.uci.cursor():get("cfspeedtest", "config", "apply_domains") or "cf.example.com"
        for domain in domains:gmatch("[^%s,]+") do
            sys.call(string.format("sed -i '/%s/d' /etc/hosts", domain))
            sys.call(string.format("echo '%s %s' >> /etc/hosts", best_ip, domain))
        end
        sys.call("/etc/init.d/dnsmasq restart")
        success = true
        message = "已应用到 hosts: " .. best_ip
        
    elseif target == "passwall" then
        -- 应用到 Passwall
        local node = luci.model.uci.cursor():get("cfspeedtest", "config", "passwall_node")
        if node and node ~= "" then
            sys.call(string.format("uci set passwall.%s.address='%s'", node, best_ip))
            sys.call("uci commit passwall")
            sys.call("/etc/init.d/passwall restart")
            success = true
            message = "已应用到 Passwall 节点: " .. best_ip
        else
            message = "请先配置 Passwall 节点"
        end
        
    elseif target == "ssrplus" then
        -- 应用到 SSR Plus
        local node = luci.model.uci.cursor():get("cfspeedtest", "config", "ssrplus_node")
        if node and node ~= "" then
            sys.call(string.format("uci set shadowsocksr.%s.server='%s'", node, best_ip))
            sys.call("uci commit shadowsocksr")
            sys.call("/etc/init.d/shadowsocksr restart")
            success = true
            message = "已应用到 SSR Plus 节点: " .. best_ip
        else
            message = "请先配置 SSR Plus 节点"
        end
        
    elseif target == "openclash" then
        -- 应用到 OpenClash
        sys.call(string.format("echo '%s' > /etc/openclash/custom/openclash_custom_hosts.list", best_ip))
        sys.call("/etc/init.d/openclash restart")
        success = true
        message = "已应用到 OpenClash: " .. best_ip
    end
    
    http.prepare_content("application/json")
    http.write_json({status = success and "success" or "error", message = message, ip = best_ip})
end

-- 导出结果
function api_export()
    local format = http.formvalue("format") or "csv"
    local result_file = "/tmp/cfspeedtest_result.csv"
    
    if not fs.access(result_file) then
        http.prepare_content("application/json")
        http.write_json({status = "error", message = "没有测速结果"})
        return
    end
    
    if format == "csv" then
        http.header("Content-Disposition", "attachment; filename=cfspeedtest_result.csv")
        http.prepare_content("text/csv")
        http.write(fs.readfile(result_file))
    elseif format == "json" then
        local result = {}
        local file = io.open(result_file, "r")
        if file then
            local header = file:read("*line")
            for line in file:lines() do
                local parts = {}
                for part in line:gmatch("[^,]+") do
                    table.insert(parts, part)
                end
                if #parts >= 5 then
                    table.insert(result, {
                        ip = parts[1],
                        port = parts[2],
                        latency = parts[3],
                        loss = parts[4],
                        speed = parts[5]
                    })
                end
            end
            file:close()
        end
        http.header("Content-Disposition", "attachment; filename=cfspeedtest_result.json")
        http.prepare_content("application/json")
        http.write_json(result)
    end
end
