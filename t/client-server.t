use v6;
use Test;

use lib 't/lib';

use HTTP::Server::Tiny;
use WebSocket::P6W;
use WebSocket::Client;

use Test::TCP;

plan 5;

# `Test.is` and `Test.ok` are not thread safe@20170605
my $l = Lock.new;

sub _is($a, $b, $msg) {
    LEAVE { $l.unlock }
    $l.lock;
    is $a, $b, $msg;
}

sub _ok($status, $msg) {
    LEAVE { $l.unlock }
    $l.lock;
    ok $status, $msg;
}

my $port = 15555;

# server thread
Promise.start: {
    note 'starting server';
    my $s = HTTP::Server::Tiny.new(port => $port);
    $s.run(-> %env {
        ws-psgi(%env,
            on-ready => -> $ws {
                _ok True, 's: ready';
            },
            on-text => -> $ws, $txt {
                _is $txt, 'STEP1', 's: got text';
                $ws.send-text('STEP2');
            },
            on-binary => -> $ws, $binary {
                $ws.send-binary($binary);
            },
            on-close => -> $ws {
                _ok True, 's: close';
            },
        );
    })
}

wait_port($port);

note 'ready connect';

await Promise.anyof(
  Promise.start({
    WebSocket::Client.connect(
        "ws://127.0.0.1:$port/",
        on-text => -> $h, $txt {
            _is $txt, 'STEP2', 'c:text';
            $h.send-close;
        },
        on-binary => -> $h, $txt {
            note 'got binary data'
        },
        on-close => -> $h {
            _ok True, 'c: close';
        },
        on-ready => -> $h {
            _ok True, 'c: ready';
            # Wait before sending the message to ensure the server handle setup is complete
            # This behaviour seems to be related to HTTP::Server::Tiny
            sleep 0.1;
            $h.send-text("STEP1");
        },
    )
  }),
  Promise.in(5).then( { fail "Test timed out!" } ),
);
