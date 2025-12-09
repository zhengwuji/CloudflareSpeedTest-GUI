local m, s, o

m = Map("clearcache", translate("LuCI 缓存管理"),
    translate("管理 LuCI Web 界面缓存，解决安装应用后页面显示异常的问题"))

s = m:section(TypedSection, "clearcache", translate("缓存控制"))
s.anonymous = true
s.addremove = false

-- 手动清除按钮
o = s:option(DummyValue, "_clear", translate("手动清除"))
o.rawhtml = true
o.cfgvalue = function()
    return [[
        <button class="btn cbi-button cbi-button-apply" style="margin-right:10px;" onclick="
            if(confirm('确定要清除LuCI缓存吗？页面将自动刷新。')){
                var btn=this;
                btn.disabled=true;
                btn.value='清除中...';
                (new XHR()).get('/cgi-bin/luci/admin/system/clearcache/api/clear', null, function(r){
                    alert('缓存已清除！页面即将刷新。');
                    location.reload();
                });
            }
        ">]] .. translate("立即清除缓存") .. [[</button>
        <span style="color:#666;font-size:12px;">点击后会清除 /tmp/luci-* 并重启 rpcd 服务</span>
    ]]
end

-- 自动清除开关
o = s:option(ListValue, "auto_clear", translate("安装/卸载IPK时自动清除"))
o:value("1", translate("开启"))
o:value("0", translate("关闭"))
o.default = "1"
o.rmempty = false
o.description = translate("开启后，安装或卸载任何支持此功能的IPK时会自动清除LuCI缓存")

-- 说明信息
o = s:option(DummyValue, "_info", translate("缓存说明"))
o.rawhtml = true
o.cfgvalue = function()
    return [[
        <div style="background:#f5f5f5;padding:15px;border-radius:5px;line-height:1.8;">
        <b>什么是 LuCI 缓存？</b><br>
        LuCI 会缓存 JavaScript、CSS 和模板文件以加快加载速度。<br>
        当安装新应用或更新应用后，旧缓存可能导致页面显示异常。<br><br>
        <b>何时需要清除？</b><br>
        • 安装新的 LuCI 应用后页面报错<br>
        • 更新应用后界面没有变化<br>
        • 出现 JavaScript 错误 (如 Cannot read properties of undefined)
        </div>
    ]]
end

return m
