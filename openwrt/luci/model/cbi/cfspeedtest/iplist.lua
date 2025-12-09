local m, s, o
local fs = require "nixio.fs"

m = Map("cfspeedtest", translate("自定义IP段"),
    translate("管理自定义 Cloudflare IP 段"))

s = m:section(TypedSection, "cfspeedtest", translate("IP 段管理"))
s.anonymous = true
s.addremove = false

o = s:option(ListValue, "use_custom_ip", translate("使用自定义IP段"))
o:value("1", translate("是"))
o:value("0", translate("否"))
o.default = "0"
o.rmempty = false
o.description = translate("启用后将使用下方的自定义IP段进行测速")

o = s:option(TextValue, "custom_ip", translate("自定义 IP 段"))
o.rows = 15
o.wrap = "off"
o.cfgvalue = function()
    local file = "/etc/cfspeedtest/custom_ip.txt"
    if fs.access(file) then
        return fs.readfile(file) or ""
    end
    return "# 每行一个 IP 或 CIDR 段\n# 例如:\n# 173.245.48.0/20\n# 103.21.244.0/22\n# 1.1.1.1\n"
end
o.write = function(self, section, value)
    local file = "/etc/cfspeedtest/custom_ip.txt"
    fs.mkdirr("/etc/cfspeedtest")
    fs.writefile(file, value or "")
end

-- 官方IP段
s = m:section(TypedSection, "cfspeedtest", translate("官方 Cloudflare IP 段"))
s.anonymous = true
s.addremove = false

o = s:option(Button, "update_official", translate("更新官方IP段"))
o.inputtitle = translate("一键更新")
o.inputstyle = "apply"

o = s:option(DummyValue, "official_ip_info", translate("当前IP段信息"))
o.rawhtml = true
o.cfgvalue = function()
    local file = "/tmp/ip.txt"
    if fs.access(file) then
        local stat = fs.stat(file)
        local lines = 0
        for _ in io.lines(file) do lines = lines + 1 end
        return string.format(
            "<span style='color:green;font-weight:bold;'>已加载</span> %d 行 | 更新时间: %s",
            lines,
            os.date("%Y-%m-%d %H:%M", stat.mtime)
        )
    else
        return "<span style='color:orange;font-weight:bold;'>未加载</span>"
    end
end

return m
