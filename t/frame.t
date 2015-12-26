use v6;
use Test;

use WebSocket::Frame;

subtest {
    my $f = WebSocket::Frame.new(
        opcode => WebSocket::Frame::DOCLOSE
    );
    is-deeply $f.Buf, Buf.new(0x08, 0x00);
}, 'close';

subtest {
    my $f = WebSocket::Frame.new(
        opcode => WebSocket::Frame::TEXT,
        payload => '布団がふっとんだ'
    );
    is-deeply $f.Buf, Buf.new(1, 24, 229, 184, 131, 229, 155, 163, 227, 129, 140, 227, 129, 181, 227, 129, 163, 227, 129, 168, 227, 130, 147, 227, 129, 160);
}, 'text';

subtest {
    my $f = WebSocket::Frame.new(
        opcode => WebSocket::Frame::BINARY,
        payload => "\xff\x32".encode('latin1')
    );
    is-deeply $f.Buf, Buf.new(2, 2, 255, 50);
}, 'text';

done-testing;

