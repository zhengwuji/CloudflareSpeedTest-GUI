local m, s, o

m = Map("cfspeedtest", translate("测速结果"),
    translate("查看测速结果和可视化图表"))

m:append(Template("cfspeedtest/result"))

return m
