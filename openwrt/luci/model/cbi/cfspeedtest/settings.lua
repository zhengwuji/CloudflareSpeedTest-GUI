local m, s, o
local sys = require "luci.sys"
local fs = require "nixio.fs"

m = Map("cfspeedtest", translate("Cloudflare 优选IP测速"),
    translate("通过测速找出延迟最低、速度最快的 Cloudflare IP"))

m:append(Template("cfspeedtest/status"))

-- 基本设置
s = m:section(TypedSection, "cfspeedtest", translate("基本设置"))
s.anonymous = true
s.addremove = false

o = s:option(ListValue, "enabled", translate("启用"))
o:value("1", translate("是"))
o:value("0", translate("否"))
o.default = "0"
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

o = s:option(ListValue, "url", translate("测速地址"))
o:value("https://cf.xiu2.xyz/url", "cf.xiu2.xyz (推荐)")
o:value("https://speed.cloudflare.com/__down?bytes=200000000", "Cloudflare 官方")
o:value("https://cf.ghproxy.cc/url", "ghproxy.cc")
o.default = "https://cf.xiu2.xyz/url"
o.rmempty = false

o = s:option(ListValue, "httping", translate("HTTPing 模式"))
o:value("1", translate("启用"))
o:value("0", translate("禁用"))
o.default = "0"
o.rmempty = false

o = s:option(Value, "cfcolo", translate("数据中心地区码"))
o.default = "HKG,KHH,NRT,LAX"
o.rmempty = true
o.description = translate("HTTPing 模式下可用，多个用逗号分隔")
o:depends("httping", "1")

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
o.datatype = "ufloat"
o.default = "0"
o.rmempty = false

o = s:option(Value, "result_num", translate("显示结果数量"))
o.datatype = "uinteger"
o.default = "10"
o.rmempty = false

o = s:option(ListValue, "disable_download", translate("禁用下载测速"))
o:value("1", translate("是"))
o:value("0", translate("否"))
o.default = "0"
o.rmempty = false

o = s:option(ListValue, "test_all", translate("测速全部IP"))
o:value("1", translate("是"))
o:value("0", translate("否"))
o.default = "0"
o.rmempty = false

-- 自动应用设置
s = m:section(TypedSection, "cfspeedtest", translate("自动应用最优IP"))
s.anonymous = true
s.addremove = false

o = s:option(ListValue, "auto_apply", translate("测速完成后自动应用"))
o:value("1", translate("是"))
o:value("0", translate("否"))
o.default = "0"
o.rmempty = false

o = s:option(ListValue, "apply_target", translate("应用目标"))
o:value("hosts", "Hosts 文件")
o:value("passwall", "Passwall")
o:value("ssrplus", "SSR Plus")
o:value("openclash", "OpenClash")
o.default = "hosts"
o:depends("auto_apply", "1")

o = s:option(Value, "apply_domains", translate("应用域名"))
o.default = "cf.example.com"
o.description = translate("多个域名用空格或逗号分隔")
o:depends("apply_target", "hosts")

o = s:option(Value, "passwall_node", translate("Passwall 节点ID"))
o.description = translate("在 Passwall 节点列表中查看节点 ID")
o:depends("apply_target", "passwall")

o = s:option(Value, "ssrplus_node", translate("SSR Plus 节点ID"))
o.description = translate("在 SSR Plus 服务器列表中查看节点 ID")
o:depends("apply_target", "ssrplus")

return m
