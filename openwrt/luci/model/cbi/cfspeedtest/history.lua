local m, s, o

m = Map("cfspeedtest", translate("历史记录"),
    translate("查看历史测速记录"))

m:append(Template("cfspeedtest/history"))

return m
