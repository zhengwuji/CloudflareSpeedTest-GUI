local m, s, o
local fs = require "nixio.fs"

m = Map("cfspeedtest", translate("实时日志"),
    translate("查看测速进度和输出"))

m:append(Template("cfspeedtest/log"))

return m
