local m, s, o
local fs = require "nixio.fs"
local sys = require "luci.sys"

m = Map("cfspeedtest", translate("高级设置"),
    translate("CloudflareST 版本管理和高级配置"))

m:append(Template("cfspeedtest/advanced"))

-- CloudflareST 管理
s = m:section(TypedSection, "cfspeedtest", translate("CloudflareST 程序"))
s.anonymous = true
s.addremove = false

o = s:option(DummyValue, "cfst_status", translate("程序状态"))
o.rawhtml = true
o.cfgvalue = function()
    if fs.access("/usr/bin/CloudflareST") then
        local version = sys.exec("/usr/bin/CloudflareST -v 2>&1 | head -1"):gsub("%s+", " ")
        return string.format(
            '<span class="label label-success">已安装</span> %s',
            version
        )
    else
        return '<span class="label label-danger">未安装</span>'
    end
end

o = s:option(DummyValue, "cfst_arch", translate("系统架构"))
o.cfgvalue = function()
    return sys.exec("uname -m"):gsub("%s+", "")
end

-- 代理设置
s = m:section(TypedSection, "cfspeedtest", translate("代理设置"))
s.anonymous = true
s.addremove = false

o = s:option(Flag, "use_proxy", translate("使用代理下载"))
o.rmempty = false
o.description = translate("更新 IP 库和 CloudflareST 时使用代理")

o = s:option(ListValue, "proxy_source", translate("代理源"))
o:value("ghproxy", "ghproxy.com")
o:value("mirror", "mirror.ghproxy.com")
o:value("fastgit", "fastgit.org")
o:value("custom", translate("自定义"))
o.default = "mirror"
o:depends("use_proxy", "1")

o = s:option(Value, "custom_proxy", translate("自定义代理地址"))
o.placeholder = "https://your-proxy.com/"
o:depends("proxy_source", "custom")

-- 数据管理
s = m:section(TypedSection, "cfspeedtest", translate("数据管理"))
s.anonymous = true
s.addremove = false

o = s:option(Button, "clear_cache", translate("清除缓存"))
o.inputtitle = translate("清除")
o.inputstyle = "reset"
o.write = function()
    fs.remove("/tmp/cfspeedtest.log")
    fs.remove("/tmp/cfspeedtest_result.csv")
end

o = s:option(Button, "clear_all", translate("重置所有数据"))
o.inputtitle = translate("重置")
o.inputstyle = "remove"
o.write = function()
    fs.remove("/tmp/cfspeedtest.log")
    fs.remove("/tmp/cfspeedtest_result.csv")
    fs.remove("/etc/cfspeedtest/history.json")
    fs.remove("/etc/cfspeedtest/custom_ip.txt")
end

return m
