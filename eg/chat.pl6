use v6;

use HTTP::Server::Tiny;
use WebSocket::P6W;

sub MAIN(Int :$port=80) {
    my $html = $=finish;
    $html ~~ s:g/'<<<PORT>>>'/$port/;

    my $supplier = Supplier.new;
    my $supply = $supplier.Supply;

    my $s = HTTP::Server::Tiny.new(port => $port);
    $s.run(-> %env {
        say "request: %env<PATH_INFO>";
        given %env<PATH_INFO> {
            when '/' {
                200, [], [$html]
            }
            when '/echo2' {
                my $s;

                ws-psgi(%env,
                    on-ready => -> $ws {
                        $s = $supply.tap(-> $got {
                            $ws.send-text("GOT: $got");
                        });
                        say 'ready';
                    },
                    on-text => -> $ws, $txt {
                        $supplier.emit($txt);

                        say 'sent.';
                        if $txt eq 'quit' {
                            say 'close it!';
                            $ws.send-close();
                        }
                    },
                    on-binary => -> $ws, $binary {
                        $ws.send-binary($binary);
                    },
                    on-close => -> $ws {
                        say "closing socket";
                        $s.close if $s;
                    },
                );
            }
            default {
                404, [], ['not found']
            }
        }
    });
}

=finish
<!doctype html>
<html>
<head>
    <meta charset="utf-8">
    <title>WS</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script type="text/javascript" src="https://code.jquery.com/jquery-2.1.4.min.js"></script>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css">
</head>
<body>
    <div class="container">
        <header><h1>WS</h1></header>
        <section class="row">
            <form id="form">
                <input type="text" name="message" id="message">
                <input type="submit">
            </form>
            <pre id="log"></pre>
        </section>
        <footer>Powered by <a href="http://perl6.org/">Perl6</a></footer>
    </div>
    <script type="text/javascript">
        function log(msg) {
            $('#log').text($('#log').text() + msg + "\n");
        }

        $(function () {
            var ws = new WebSocket('ws://localhost:<<<PORT>>>/echo2');
            ws.onopen = function () {
                log('connected');
            };
            ws.onclose = function (ev) {
                log('closed');
            };
            ws.onmessage = function (ev) {
                log('received: ' + ev.data);
                $('#message').val('');
            };
            ws.onerror = function (ev) {
                console.log(ev);
                log('error: ' + ev.data);
            };
            $('#form').submit(function () {
                ws.send($('#message').val());
                return false;
            });
        });
    </script>
</body>
</html>
