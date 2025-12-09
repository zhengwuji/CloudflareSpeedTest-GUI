module("luci.controller.clearcache", package.seeall)

local fs = require "nixio.fs"
local sys = require "luci.sys"
local http = require "luci.http"

function index()
    entry({"admin", "system", "clearcache"}, firstchild(), _("LuCI缓存管理"), 99).dependent = true
    entry({"admin", "system", "clearcache", "settings"}, cbi("clearcache"), _("设置"), 1).leaf = true
    entry({"admin", "system", "clearcache", "api", "clear"}, call("api_clear")).leaf = true
end

function api_clear()
    sys.call("rm -rf /tmp/luci-*")
    sys.call("/etc/init.d/rpcd restart 2>/dev/null")
    http.prepare_content("application/json")
    http.write_json({status = "success", message = "LuCI缓存已清除"})
end
