'use strict';
'require view';
'require fs';

return view.extend({
    load: function () {
        return fs.read('/tmp/cfspeedtest_result.csv').catch(function () {
            return '';
        });
    },

    parseCSV: function (content) {
        if (!content) return [];
        var lines = content.trim().split('\n');
        var result = [];
        for (var i = 1; i < lines.length; i++) {
            var parts = lines[i].split(',');
            if (parts.length >= 5) {
                result.push({
                    ip: parts[0],
                    port: parts[1],
                    latency: parts[2],
                    loss: parts[3],
                    speed: parts[4],
                    location: parts[5] || ''
                });
            }
        }
        return result;
    },

    render: function (csvContent) {
        var data = this.parseCSV(csvContent);

        var rows = data.map(function (item, index) {
            return E('tr', {}, [
                E('td', {}, String(index + 1)),
                E('td', { 'style': 'font-weight:bold;' }, item.ip),
                E('td', {}, item.port),
                E('td', {}, item.latency + ' ms'),
                E('td', {}, item.loss),
                E('td', {}, item.speed + ' MB/s'),
                E('td', {}, [
                    E('button', {
                        'class': 'btn cbi-button cbi-button-action',
                        'style': 'padding: 2px 8px; font-size: 12px;',
                        'click': function () {
                            navigator.clipboard.writeText(item.ip);
                            alert(_('已复制: ') + item.ip);
                        }
                    }, _('复制'))
                ])
            ]);
        });

        if (rows.length === 0) {
            rows = [E('tr', {}, [E('td', { 'colspan': '7', 'style': 'text-align:center;' }, _('暂无测速结果'))])];
        }

        // 生成速度图表
        var maxSpeed = Math.max.apply(null, data.map(function (d) { return parseFloat(d.speed) || 0; })) || 1;
        var chartBars = data.slice(0, 10).map(function (item) {
            var width = ((parseFloat(item.speed) || 0) / maxSpeed * 200);
            return E('div', { 'style': 'margin: 5px 0;' }, [
                E('span', { 'style': 'display:inline-block; width:120px;' }, item.ip),
                E('span', {
                    'style': 'display:inline-block; height:20px; width:' + width + 'px; background:linear-gradient(90deg, #4ade80, #22c55e); border-radius:3px; margin-right:10px;'
                }),
                E('span', {}, item.speed + ' MB/s')
            ]);
        });

        var container = E('div', { 'class': 'cbi-section' }, [
            E('h3', {}, _('测速结果')),
            E('div', { 'style': 'margin-bottom: 15px;' }, [
                E('button', {
                    'class': 'btn cbi-button',
                    'click': function () { window.location.reload(); }
                }, _('刷新结果')),
                ' ',
                E('button', {
                    'class': 'btn cbi-button cbi-button-positive',
                    'click': function () {
                        if (data.length > 0) {
                            navigator.clipboard.writeText(data[0].ip);
                            alert(_('最优IP已复制: ') + data[0].ip);
                        }
                    }
                }, _('复制最优IP')),
                ' ',
                E('a', {
                    'class': 'btn cbi-button',
                    'href': '/cgi-bin/luci/admin/services/cfspeedtest/export?format=csv',
                    'target': '_blank'
                }, _('导出CSV'))
            ]),
            E('table', { 'class': 'table', 'style': 'width:100%;' }, [
                E('thead', {}, [
                    E('tr', {}, [
                        E('th', {}, _('排名')),
                        E('th', {}, _('IP地址')),
                        E('th', {}, _('端口')),
                        E('th', {}, _('延迟')),
                        E('th', {}, _('丢包率')),
                        E('th', {}, _('速度')),
                        E('th', {}, _('操作'))
                    ])
                ]),
                E('tbody', {}, rows)
            ]),
            E('div', { 'style': 'margin-top:20px; padding:20px; background:#fff; border-radius:8px; box-shadow:0 2px 10px rgba(0,0,0,0.1);' }, [
                E('h4', {}, _('速度分布图')),
                E('div', {}, chartBars)
            ])
        ]);

        return container;
    },

    handleSaveApply: null,
    handleSave: null,
    handleReset: null
});
