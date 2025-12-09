local m, s, o

m = Map("cfspeedtest", translate("Cloudflare 优选IP测速"),
    translate("通过测速找出延迟最低、速度最快的 Cloudflare IP"))

s = m:section(TypedSection, "cfspeedtest", translate("基本设置"))
s.anonymous = true
s.addremove = false

o = s:option(Flag, "enabled", translate("启用"))
o.rmempty = false

o = s:option(Value, "thread", translate("延迟线程数"))
o.datatype = "range(1,1000)"
o.default = "200"
o.rmempty = false

o = s:option(Value, "count", translate("延迟测试次数"))
o.datatype = "uinteger"
o.default = "4"
o.rmempty = false

o = s:option(Value, "download_num", translate("下载测速数量"))
o.datatype = "uinteger"
o.default = "10"
o.rmempty = false

o = s:option(Value, "download_time", translate("下载测速时间(秒)"))
o.datatype = "uinteger"
o.default = "10"
o.rmempty = false

o = s:option(Value, "port", translate("测速端口"))
o.datatype = "port"
o.default = "443"
o.rmempty = false

o = s:option(Value, "url", translate("测速地址"))
o.default = "https://cf.xiu2.xyz/url"
o.rmempty = false

o = s:option(Flag, "httping", translate("HTTPing 模式"))
o.rmempty = false

o = s:option(Value, "cfcolo", translate("数据中心地区码"))
o.default = "HKG,KHH,NRT,LAX"
o.rmempty = true
o.description = translate("HTTPing 模式下可用，多个用逗号分隔")

o = s:option(Value, "tl", translate("平均延迟上限(ms)"))
o.datatype = "uinteger"
o.default = "9999"
o.rmempty = false

o = s:option(Value, "tll", translate("平均延迟下限(ms)"))
o.datatype = "uinteger"
o.default = "0"
o.rmempty = false

o = s:option(Value, "tlr", translate("丢包率上限"))
o.default = "1.00"
o.rmempty = false

o = s:option(Value, "sl", translate("下载速度下限(MB/s)"))
o.datatype = "uinteger"
o.default = "0"
o.rmempty = false

o = s:option(Value, "result_num", translate("显示结果数量"))
o.datatype = "uinteger"
o.default = "10"
o.rmempty = false

o = s:option(Flag, "disable_download", translate("禁用下载测速"))
o.rmempty = false

o = s:option(Flag, "test_all", translate("测速全部IP"))
o.rmempty = false

-- 操作按钮
s = m:section(TypedSection, "cfspeedtest", translate("操作"))
s.anonymous = true
s.addremove = false

o = s:option(Button, "run", translate("开始测速"))
o.inputtitle = translate("运行测速")
o.inputstyle = "apply"
o.write = function()
    luci.sys.call("/etc/init.d/cfspeedtest start &")
end

o = s:option(Button, "stop", translate("停止测速"))
o.inputtitle = translate("停止")
o.inputstyle = "reset"
o.write = function()
    luci.sys.call("/etc/init.d/cfspeedtest stop")
end

-- 结果显示
s = m:section(TypedSection, "cfspeedtest", translate("测速结果"))
s.anonymous = true
s.addremove = false

o = s:option(TextValue, "result", translate("最新结果"))
o.rows = 15
o.readonly = true
o.cfgvalue = function()
    local file = io.open("/tmp/cfspeedtest_result.csv", "r")
    if file then
        local content = file:read("*all")
        file:close()
        return content
    end
    return translate("暂无测速结果，请先运行测速")
end

return m
