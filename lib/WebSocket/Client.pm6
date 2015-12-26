use v6;

unit class WebSocket::Client;

use WebSocket::URL;
use WebSocket::Handle;
use WebSocket::Frame;
use WebSocket::SecureRandom;
use WebSocket::Frame::Grammar;
use MIME::Base64;

try require IO::Socket::SSL;

my class X::WebSocket::Client::Handshake is Exception {
    has $.url;
    has $.status;
    has $.reason;

    method message() {
        "Cannot do WebSocket handshake. Status:$!status $!reason, URL: $!url";
    }
}

constant DEBUG = so %*ENV<WS_DEBUG>;

# TEKITO. We should implement this in p6-HTTP-Parser.
my grammar HTTPResponseGrammar {
    token TOP { ^
        'HTTP/1.1 ' <status> ' ' <reason> <.crlf>
        [
            <-[ \r \n \: ]>+ ':' <-[ \r \n ]>+ <.crlf>
        ]*
        <.crlf>
    }

    token crlf { \x0d \x0a }

    token status { \d+ }
    token reason { \N+ }
}

sub debug($msg) {
    say "WS::C [DEBUG] $msg" if DEBUG;
}

method connect(
    Str $url,
    Callable :$on-text,
    Callable :$on-binary,
    Callable :$on-ready,
    Callable :$on-close
) {
    debug("parsing uri");
    my $uri = WebSocket::URL.parse($url);
    my $host = $uri.host;
    my $port = $uri.port;

    debug("connect to $host:$port") if DEBUG;

    my $rand = WebSocket::SecureRandom.new;

    # TODO: SSL support
    my $socket = do {
        if $uri.scheme eq 'wss' {
            die "Please install IO::Socket::SSL in order to connect wss" if ::('IO::Socket::SSL') ~~ Failure;
            ::('IO::Socket::SSL').new(:$host, :$port);
        } else {
            IO::Socket::INET.new(:$host, :$port);
        }
    };
    my $key = MIME::Base64.encode($rand.read(16));
    my $res = [
        "GET {$uri.resource-name} HTTP/1.1",
        "Host: $host",
        "Upgrade: websocket",
        "Connection: Upgrade",
        "Sec-WebSocket-Key: $key",
        "Sec-WebSocket-Protocol: chat",
        "Sec-WebSocket-Version: 13",
        "",
        ''
    ].join("\x0d\x0a");
    debug "writing request" if DEBUG;
    $socket.write($res.encode('latin1'));

    debug "sent request" if DEBUG;
    my Str $buf = '';
    while my $got = $socket.recv(:bin) {
        debug "got chunk" if DEBUG;
        $buf ~= $got.decode('latin1');

        my $m = HTTPResponseGrammar.subparse($buf);
        if $m {
            debug "Got HTTP response" if DEBUG;
            my $status = $m<status>.Str.Int;
            if $status == 101 {
                debug "Finished handshake" if DEBUG;
                $buf = $buf.substr($m.to);
                last;
            } else {
                my $reason = ~$m<reason>;
                X::WebSocket::Client::Handshake.new(:$url, :$status, :$reason).throw;
            }
        } else {
            debug "Partial HTTP response" if DEBUG;
        }
    }

    my $handle = WebSocket::Handle.new(
        socket => $socket,
        masking => True,
    );

    $on-ready($handle) if $on-ready;

    while my $got2 = $socket.recv(:bin) {
        $buf ~= $got2.decode('latin1');

        my $m = WebSocket::Frame::Grammar.subparse($buf);
        if $m {
            $buf = $buf.substr($m.to);
            my $frame = $m.made;
            given $frame.opcode {
                when (WebSocket::Frame::TEXT) {
                    debug "got text frame" if DEBUG;
                    $on-text($handle, $frame.payload.encode('latin1').decode('utf-8')) if $on-text;
                }
                when (WebSocket::Frame::BINARY) {
                    debug "got binary frame" if DEBUG;
                    $on-binary($handle, $frame.payload) if $on-binary;
                }
                when (WebSocket::Frame::DOCLOSE) {
                    debug "got close frame" if DEBUG;
                    $on-close($handle) if $on-close;
                    try $handle.close;
                }
                when (WebSocket::Frame::PING) {
                    debug "got ping frame" if DEBUG;
                    $handle.pong;
                }
                when (WebSocket::Frame::PONG) {
                    debug "got pong frame" if DEBUG;
                    # nop
                }
            }
        }
    }
}

method close() {
    $.socket.close;
}

