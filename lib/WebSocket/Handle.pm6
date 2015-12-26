use v6;

unit class WebSocket::Handle;

use WebSocket::Frame;
use WebSocket::SecureRandom;

has $.socket is required;
has $.masking;
has $.random is rw;

constant WS_DEBUG=so %*ENV<WS_DEBUG>;

sub debug($msg) {
    say "[WS_DEBUG] [Handle] $msg" if WS_DEBUG;
}

method send(WebSocket::Frame $frame) {
    if $.masking && !$frame.is-control {
        $.random //= WebSocket::SecureRandom.new;
        $frame.masking-key = $.random.read(4);
    }
    my $buf = $frame.Buf;
    return $.socket.write($buf); # it returns promise
}

method send-text(Str $msg) {
    self.send: WebSocket::Frame.new(
        fin => True,
        opcode => WebSocket::Frame::TEXT,
        payload => $msg,
    );
}

method send-close() {
    self.send: WebSocket::Frame.new(
        fin => True,
        opcode => WebSocket::Frame::DOCLOSE,
    );
}

# https://tools.ietf.org/html/rfc6455#section-5.5.2
method ping() {
    self.send: WebSocket::Frame.new(
        fin => True,
        opcode => WebSocket::Frame::PING
    );
}

# https://tools.ietf.org/html/rfc6455#section-5.5.3
method pong() {
    self.send: WebSocket::Frame.new(
        fin => True,
        opcode => WebSocket::Frame::PONG
    );
}

