use v6;
use Test;

use lib 't/lib';

use HTTP::Server::Tiny;
use WebSocket::P6SGI;
use WebSocket::Client;

use Test::TCP;

plan 5;

my $port = 15555;

# server thread
Thread.start({
    note 'starting server';
    my $s = HTTP::Server::Tiny.new(port => $port);
    $s.run(-> %env {
        ws-psgi(%env,
            on-ready => -> $ws {
                ok 1, 's: ready';
            },
            on-text => -> $ws, $txt {
                is $txt, 'STEP1', 's: got text';
                $ws.send-text('STEP2');
            },
            on-binary => -> $ws, $binary {
                $ws.send-binary($binary);
            },
            on-close => -> $ws {
                ok 1, 's: close';
            },
        );
    });
}, :app_lifetime);

wait_port($port);

note 'ready connect';

WebSocket::Client.connect(
    "ws://127.0.0.1:$port/",
    on-text => -> $h, $txt {
        is $txt, 'STEP2', 'c:text';
        $h.send-close;
    },
    on-binary => -> $h, $txt {
        note 'got binary data'
    },
    on-close => -> $h {
        note 'on close';
        ok 1, 'c: close';
    },
    on-ready => -> $h {
        ok 1, 'c: ready';
        $h.send-text("STEP1");
    },
);

