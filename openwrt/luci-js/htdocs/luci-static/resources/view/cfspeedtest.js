'use strict';
'require baseclass';
'require rpc';
'require uci';

return baseclass.extend({
    title: _('CF优选IP'),

    // RPC 调用声明
    callStatus: rpc.declare({
        object: 'file',
        method: 'exec',
        params: ['command', 'params']
    }),

    load: function () {
        return Promise.resolve();
    },

    render: function () {
        return E('div', { 'class': 'cbi-map' }, [
            E('h2', {}, _('Cloudflare 优选IP测速')),
            E('div', { 'class': 'cbi-section' }, [
                E('p', {}, _('通过测速找出延迟最低、速度最快的 Cloudflare IP'))
            ])
        ]);
    }
});
