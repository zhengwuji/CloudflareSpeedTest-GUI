'use strict';
'require view';
'require fs';

return view.extend({
    load: function () {
        return fs.read('/etc/cfspeedtest/history.json').catch(function () {
            return '[]';
        });
    },

    render: function (historyJson) {
        var history = [];
        try {
            history = JSON.parse(historyJson || '[]');
        } catch (e) {
            history = [];
        }

        var rows = history.map(function (item) {
            return E('tr', {}, [
                E('td', {}, item.time || ''),
                E('td', { 'style': 'font-weight:bold;' }, item.best_ip || ''),
                E('td', {}, (item.best_latency || '-') + ' ms'),
                E('td', {}, (item.best_speed || '-') + ' MB/s'),
                E('td', {}, String(item.total_results || 0))
            ]);
        });

        if (rows.length === 0) {
            rows = [E('tr', {}, [E('td', { 'colspan': '5', 'style': 'text-align:center;' }, _('暂无历史记录'))])];
        }

        var container = E('div', { 'class': 'cbi-section' }, [
            E('h3', {}, _('历史记录')),
            E('div', { 'style': 'margin-bottom: 15px;' }, [
                E('button', {
                    'class': 'btn cbi-button',
                    'click': function () { window.location.reload(); }
                }, _('刷新')),
                ' ',
                E('button', {
                    'class': 'btn cbi-button cbi-button-negative',
                    'click': function () {
                        if (confirm(_('确定要清空所有历史记录吗？'))) {
                            fs.remove('/etc/cfspeedtest/history.json').then(function () {
                                window.location.reload();
                            });
                        }
                    }
                }, _('清空历史'))
            ]),
            E('table', { 'class': 'table', 'style': 'width:100%;' }, [
                E('thead', {}, [
                    E('tr', {}, [
                        E('th', {}, _('时间')),
                        E('th', {}, _('最优IP')),
                        E('th', {}, _('延迟')),
                        E('th', {}, _('速度')),
                        E('th', {}, _('结果数'))
                    ])
                ]),
                E('tbody', {}, rows)
            ])
        ]);

        return container;
    },

    handleSaveApply: null,
    handleSave: null,
    handleReset: null
});
