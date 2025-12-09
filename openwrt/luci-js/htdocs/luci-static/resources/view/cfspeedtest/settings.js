'use strict';
'require view';
'require form';
'require fs';
'require uci';

return view.extend({
    load: function () {
        return Promise.all([
            uci.load('cfspeedtest')
        ]);
    },

    render: function () {
        var m, s, o;

        m = new form.Map('cfspeedtest', _('Cloudflare 优选IP测速'),
            _('通过测速找出延迟最低、速度最快的 Cloudflare IP'));

        // 状态显示
        s = m.section(form.NamedSection, 'config', 'cfspeedtest', _('运行状态'));

        o = s.option(form.DummyValue, '_status', _('当前状态'));
        o.rawhtml = true;
        o.cfgvalue = function () {
            return '<div id="cfst-status" style="padding:10px;background:#f0f0f0;border-radius:5px;">' +
                '<button class="btn cbi-button cbi-button-apply" onclick="fetch(\'/cgi-bin/luci/admin/services/cfspeedtest/api/run\').then(()=>location.reload())">' + _('开始测速') + '</button> ' +
                '<button class="btn cbi-button cbi-button-action" onclick="if(confirm(\'确定要清除LuCI缓存吗？页面将刷新。\')){fetch(\'/cgi-bin/luci/admin/services/cfspeedtest/api/clear_cache\').then(()=>location.reload())}">' + _('清除LuCI缓存') + '</button>' +
                '</div>';
        };

        // 基本设置
        s = m.section(form.NamedSection, 'config', 'cfspeedtest', _('基本设置'));
        s.anonymous = true;

        o = s.option(form.ListValue, 'enabled', _('启用'));
        o.value('1', _('是'));
        o.value('0', _('否'));
        o.default = '0';
        o.rmempty = false;

        o = s.option(form.Value, 'thread', _('延迟线程数'));
        o.datatype = 'range(1,1000)';
        o.default = '200';
        o.rmempty = false;

        o = s.option(form.Value, 'count', _('延迟测试次数'));
        o.datatype = 'uinteger';
        o.default = '4';
        o.rmempty = false;

        o = s.option(form.Value, 'download_num', _('下载测速数量'));
        o.datatype = 'uinteger';
        o.default = '10';
        o.rmempty = false;

        o = s.option(form.Value, 'download_time', _('下载测速时间(秒)'));
        o.datatype = 'uinteger';
        o.default = '10';
        o.rmempty = false;

        o = s.option(form.Value, 'port', _('测速端口'));
        o.datatype = 'port';
        o.default = '443';
        o.rmempty = false;

        o = s.option(form.ListValue, 'url', _('测速地址'));
        o.value('https://cf.xiu2.xyz/url', 'cf.xiu2.xyz (推荐)');
        o.value('https://speed.cloudflare.com/__down?bytes=200000000', 'Cloudflare 官方');
        o.value('https://cf.ghproxy.cc/url', 'ghproxy.cc');
        o.default = 'https://cf.xiu2.xyz/url';

        o = s.option(form.ListValue, 'httping', _('HTTPing 模式'));
        o.value('1', _('启用'));
        o.value('0', _('禁用'));
        o.default = '0';
        o.rmempty = false;

        o = s.option(form.Value, 'cfcolo', _('数据中心地区码'));
        o.default = 'HKG,KHH,NRT,LAX';
        o.rmempty = true;
        o.description = _('HTTPing 模式下可用，多个用逗号分隔');
        o.depends('httping', '1');

        o = s.option(form.Value, 'tl', _('平均延迟上限(ms)'));
        o.datatype = 'uinteger';
        o.default = '9999';

        o = s.option(form.Value, 'tll', _('平均延迟下限(ms)'));
        o.datatype = 'uinteger';
        o.default = '0';

        o = s.option(form.Value, 'tlr', _('丢包率上限'));
        o.default = '1.00';

        o = s.option(form.Value, 'sl', _('下载速度下限(MB/s)'));
        o.datatype = 'ufloat';
        o.default = '0';

        o = s.option(form.Value, 'result_num', _('显示结果数量'));
        o.datatype = 'uinteger';
        o.default = '10';

        o = s.option(form.ListValue, 'disable_download', _('禁用下载测速'));
        o.value('1', _('是'));
        o.value('0', _('否'));
        o.default = '0';
        o.rmempty = false;

        o = s.option(form.ListValue, 'test_all', _('测速全部IP'));
        o.value('1', _('是'));
        o.value('0', _('否'));
        o.default = '0';
        o.rmempty = false;

        // 自动应用设置
        s = m.section(form.NamedSection, 'config', 'cfspeedtest', _('自动应用最优IP'));

        o = s.option(form.ListValue, 'auto_apply', _('测速完成后自动应用'));
        o.value('1', _('是'));
        o.value('0', _('否'));
        o.default = '0';
        o.rmempty = false;

        o = s.option(form.ListValue, 'apply_target', _('应用目标'));
        o.value('hosts', 'Hosts 文件');
        o.value('passwall', 'Passwall');
        o.value('ssrplus', 'SSR Plus');
        o.value('openclash', 'OpenClash');
        o.default = 'hosts';
        o.depends('auto_apply', '1');

        o = s.option(form.Value, 'apply_domains', _('应用域名'));
        o.default = 'cf.example.com';
        o.description = _('多个域名用空格或逗号分隔');
        o.depends('apply_target', 'hosts');

        o = s.option(form.Value, 'passwall_node', _('Passwall 节点ID'));
        o.description = _('在 Passwall 节点列表中查看节点 ID');
        o.depends('apply_target', 'passwall');

        o = s.option(form.Value, 'ssrplus_node', _('SSR Plus 节点ID'));
        o.description = _('在 SSR Plus 服务器列表中查看节点 ID');
        o.depends('apply_target', 'ssrplus');

        return m.render();
    }
});
