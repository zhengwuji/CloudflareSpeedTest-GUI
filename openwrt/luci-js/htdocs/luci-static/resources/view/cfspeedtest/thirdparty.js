'use strict';
'require view';
'require form';
'require fs';
'require uci';

return view.extend({
    load: function () {
        return uci.load('cfspeedtest');
    },

    render: function () {
        var m, s, o;

        m = new form.Map('cfspeedtest', _('第三方应用设置'),
            _('将优选IP自动应用到第三方代理软件'));

        // 标签页容器
        s = m.section(form.NamedSection, 'config', 'cfspeedtest');
        s.tab('ssrplus', _('Shadowsocksr Plus+'));
        s.tab('passwall2', _('passwall2'));
        s.tab('bypass', _('绕过'));
        s.tab('dns', _('路由设置'));
        s.tab('host', _('HOST'));
        s.tab('mosdns', _('MosDNS'));

        // ========== ShadowsocksR Plus+ ==========
        o = s.taboption('ssrplus', form.ListValue, 'ssrplus_enabled', _('启用ShadowSocksR Plus+'));
        o.value('1', _('启用'));
        o.value('0', _('禁用'));
        o.default = '0';
        o.rmempty = false;

        o = s.taboption('ssrplus', form.Value, 'ssrplus_server', _('服务器节点'));
        o.placeholder = '节点名称或ID';
        o.depends('ssrplus_enabled', '1');

        o = s.taboption('ssrplus', form.ListValue, 'ssrplus_field', _('替换字段'));
        o.value('server', _('服务器地址'));
        o.value('ip', _('IP地址'));
        o.default = 'server';
        o.depends('ssrplus_enabled', '1');

        o = s.taboption('ssrplus', form.ListValue, 'ssrplus_restart', _('应用后重启服务'));
        o.value('1', _('是'));
        o.value('0', _('否'));
        o.default = '1';
        o.rmempty = false;
        o.depends('ssrplus_enabled', '1');

        // ========== PassWall2 ==========
        o = s.taboption('passwall2', form.ListValue, 'passwall2_enabled', _('启用PassWall2'));
        o.value('1', _('启用'));
        o.value('0', _('禁用'));
        o.default = '0';
        o.rmempty = false;

        o = s.taboption('passwall2', form.Value, 'passwall2_node', _('节点ID'));
        o.placeholder = '在PassWall2节点列表中查看';
        o.depends('passwall2_enabled', '1');

        o = s.taboption('passwall2', form.ListValue, 'passwall2_field', _('替换字段'));
        o.value('address', _('服务器地址'));
        o.value('server', _('服务器'));
        o.default = 'address';
        o.depends('passwall2_enabled', '1');

        o = s.taboption('passwall2', form.ListValue, 'passwall2_restart', _('应用后重启服务'));
        o.value('1', _('是'));
        o.value('0', _('否'));
        o.default = '1';
        o.rmempty = false;
        o.depends('passwall2_enabled', '1');

        // ========== 绕过 (Bypass) ==========
        o = s.taboption('bypass', form.ListValue, 'bypass_enabled', _('启用Bypass'));
        o.value('1', _('启用'));
        o.value('0', _('禁用'));
        o.default = '0';
        o.rmempty = false;

        o = s.taboption('bypass', form.Value, 'bypass_server', _('服务器节点'));
        o.placeholder = '节点名称';
        o.depends('bypass_enabled', '1');

        o = s.taboption('bypass', form.ListValue, 'bypass_restart', _('应用后重启服务'));
        o.value('1', _('是'));
        o.value('0', _('否'));
        o.default = '1';
        o.rmempty = false;
        o.depends('bypass_enabled', '1');

        // ========== 路由设置 (DNS) ==========
        o = s.taboption('dns', form.ListValue, 'dns_enabled', _('启用DNS'));
        o.value('1', _('启用'));
        o.value('0', _('禁用'));
        o.default = '0';
        o.rmempty = false;

        o = s.taboption('dns', form.Value, 'dns_domain', _('域名'));
        o.placeholder = 'cloudflare.com';
        o.description = _('将优选IP解析到此域名');
        o.depends('dns_enabled', '1');

        o = s.taboption('dns', form.ListValue, 'dns_restart', _('应用后重启dnsmasq'));
        o.value('1', _('是'));
        o.value('0', _('否'));
        o.default = '1';
        o.rmempty = false;
        o.depends('dns_enabled', '1');

        // ========== HOST ==========
        o = s.taboption('host', form.ListValue, 'host_enabled', _('启用HOST'));
        o.value('1', _('启用'));
        o.value('0', _('禁用'));
        o.default = '0';
        o.rmempty = false;

        o = s.taboption('host', form.DynamicList, 'host_domains', _('域名列表'));
        o.placeholder = 'example.com';
        o.description = _('将优选IP添加到/etc/hosts中对应这些域名');
        o.depends('host_enabled', '1');

        o = s.taboption('host', form.ListValue, 'host_restart', _('应用后重启dnsmasq'));
        o.value('1', _('是'));
        o.value('0', _('否'));
        o.default = '1';
        o.rmempty = false;
        o.depends('host_enabled', '1');

        // ========== MosDNS ==========
        o = s.taboption('mosdns', form.ListValue, 'mosdns_enabled', _('启用MosDNS'));
        o.value('1', _('启用'));
        o.value('0', _('禁用'));
        o.default = '0';
        o.rmempty = false;

        o = s.taboption('mosdns', form.Value, 'mosdns_file', _('IP文件路径'));
        o.default = '/etc/mosdns/rule/cloudflare.txt';
        o.description = _('将优选IP写入此文件供MosDNS使用');
        o.depends('mosdns_enabled', '1');

        o = s.taboption('mosdns', form.ListValue, 'mosdns_restart', _('应用后重启MosDNS'));
        o.value('1', _('是'));
        o.value('0', _('否'));
        o.default = '1';
        o.rmempty = false;
        o.depends('mosdns_enabled', '1');

        return m.render();
    }
});
