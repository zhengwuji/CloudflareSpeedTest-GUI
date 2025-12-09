local m, s, o

m = Map("cfspeedtest", translate("定时任务"),
    translate("设置自动定时测速"))

s = m:section(TypedSection, "cfspeedtest", translate("定时测速设置"))
s.anonymous = true
s.addremove = false

o = s:option(Flag, "schedule_enabled", translate("启用定时测速"))
o.rmempty = false

o = s:option(ListValue, "schedule_type", translate("执行频率"))
o:value("hourly", translate("每小时"))
o:value("daily", translate("每天"))
o:value("weekly", translate("每周"))
o:value("custom", translate("自定义"))
o.default = "daily"
o:depends("schedule_enabled", "1")

o = s:option(Value, "schedule_hour", translate("执行时间(小时)"))
o.datatype = "range(0,23)"
o.default = "4"
o:depends("schedule_type", "daily")
o:depends("schedule_type", "weekly")

o = s:option(Value, "schedule_minute", translate("执行时间(分钟)"))
o.datatype = "range(0,59)"
o.default = "0"
o:depends("schedule_enabled", "1")

o = s:option(ListValue, "schedule_weekday", translate("执行日期"))
o:value("0", translate("周日"))
o:value("1", translate("周一"))
o:value("2", translate("周二"))
o:value("3", translate("周三"))
o:value("4", translate("周四"))
o:value("5", translate("周五"))
o:value("6", translate("周六"))
o.default = "1"
o:depends("schedule_type", "weekly")

o = s:option(Value, "schedule_cron", translate("Cron 表达式"))
o.default = "0 4 * * *"
o.description = translate("格式: 分 时 日 月 周")
o:depends("schedule_type", "custom")

-- 显示当前 cron 任务
s = m:section(TypedSection, "cfspeedtest", translate("当前定时任务"))
s.anonymous = true
s.addremove = false

o = s:option(DummyValue, "current_cron", translate("Cron 配置"))
o.rawhtml = true
o.cfgvalue = function()
    local cron = luci.sys.exec("grep cfspeedtest /etc/crontabs/root 2>/dev/null")
    if cron and cron ~= "" then
        return "<pre>" .. cron .. "</pre>"
    else
        return "<em>" .. translate("未配置定时任务") .. "</em>"
    end
end

return m
