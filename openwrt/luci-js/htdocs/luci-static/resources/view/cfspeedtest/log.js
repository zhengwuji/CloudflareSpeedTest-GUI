'use strict';
'require view';
'require poll';
'require fs';

return view.extend({
    load: function () {
        return fs.read('/tmp/cfspeedtest.log').catch(function () {
            return '';
        });
    },

    render: function (logContent) {
        var container = E('div', { 'class': 'cbi-section' }, [
            E('h3', {}, _('实时日志')),
            E('div', { 'style': 'margin-bottom: 10px;' }, [
                E('button', {
                    'class': 'btn cbi-button cbi-button-positive',
                    'click': function () {
                        fs.exec('/usr/bin/cfspeedtest');
                    }
                }, _('开始测速')),
                ' ',
                E('button', {
                    'class': 'btn cbi-button cbi-button-negative',
                    'click': function () {
                        fs.exec('killall', ['-9', 'CloudflareST']);
                    }
                }, _('停止测速')),
                ' ',
                E('button', {
                    'class': 'btn cbi-button',
                    'click': function () {
                        window.location.reload();
                    }
                }, _('刷新日志'))
            ]),
            E('textarea', {
                'id': 'log-content',
                'style': 'width:100%; height:500px; background:#1a1a2e; color:#00ff00; font-family:monospace; padding:10px; border-radius:5px;',
                'readonly': true
            }, logContent || _('暂无日志'))
        ]);

        // 自动刷新日志
        poll.add(L.bind(function () {
            return fs.read('/tmp/cfspeedtest.log').then(function (content) {
                var textarea = document.getElementById('log-content');
                if (textarea) {
                    textarea.value = content || '';
                    textarea.scrollTop = textarea.scrollHeight;
                }
            });
        }, this), 2);

        return container;
    },

    handleSaveApply: null,
    handleSave: null,
    handleReset: null
});
