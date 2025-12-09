'use strict';
'require view';
'require form';
'require fs';
'require uci';
'require ui';

return view.extend({
    load: function () {
        return uci.load('clearcache');
    },

    render: function () {
        var m, s, o;

        m = new form.Map('clearcache', _('LuCI 缓存管理'),
            _('管理 LuCI Web 界面缓存，解决安装应用后页面显示异常的问题'));

        s = m.section(form.NamedSection, 'config', 'clearcache', _('缓存控制'));

        // 手动清除按钮
        o = s.option(form.DummyValue, '_clear_btn', _('手动清除'));
        o.rawhtml = true;
        o.cfgvalue = function () {
            return '<button class="btn cbi-button cbi-button-apply" style="margin-right:10px;" onclick="' +
                'if(confirm(\'确定要清除LuCI缓存吗？页面将自动刷新。\')){' +
                'var btn=this;btn.disabled=true;btn.innerText=\'清除中...\';' +
                'fetch(\'/cgi-bin/luci/admin/system/clearcache/api/clear\').then(function(r){return r.json()}).then(function(d){' +
                'alert(\'缓存已清除！页面即将刷新。\');location.reload();' +
                '}).catch(function(e){alert(\'清除失败：\'+e);btn.disabled=false;btn.innerText=\'立即清除缓存\';});' +
                '}">' + _('立即清除缓存') + '</button>' +
                '<span style="color:#666;font-size:12px;">点击后会清除 /tmp/luci-* 并重启 rpcd 服务</span>';
        };

        // 自动清除开关
        o = s.option(form.ListValue, 'auto_clear', _('安装/卸载IPK时自动清除'));
        o.value('1', _('开启'));
        o.value('0', _('关闭'));
        o.default = '1';
        o.rmempty = false;
        o.description = _('开启后，安装或卸载任何支持此功能的IPK时会自动清除LuCI缓存');

        // 状态信息
        o = s.option(form.DummyValue, '_info', _('缓存说明'));
        o.rawhtml = true;
        o.cfgvalue = function () {
            return '<div style="background:#f5f5f5;padding:15px;border-radius:5px;line-height:1.8;">' +
                '<b>什么是 LuCI 缓存？</b><br>' +
                'LuCI 会缓存 JavaScript、CSS 和模板文件以加快加载速度。<br>' +
                '当安装新应用或更新应用后，旧缓存可能导致页面显示异常。<br><br>' +
                '<b>何时需要清除？</b><br>' +
                '• 安装新的 LuCI 应用后页面报错<br>' +
                '• 更新应用后界面没有变化<br>' +
                '• 出现 JavaScript 错误 (如 Cannot read properties of undefined)' +
                '</div>';
        };

        return m.render();
    }
});
