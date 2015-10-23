use v6;
use Test;
use WebSocket::Frame::Grammar;

subtest {
    my $got = WebSocket::Frame::Grammar.subparse("\xfA\x[01]a".encode('latin1').decode('latin1')).made;
    is-deeply $got.fin, True;
}, 'true';

subtest {
    my $src = "\x[0A]\x[01]a".encode('latin1').decode('latin1');
    my $got = WebSocket::Frame::Grammar.subparse($src).made;
    is-deeply $got.fin, False;
    is-deeply $got.payload.chars, 1;
}, 'falsy';

subtest {
    my $got = WebSocket::Frame::Grammar.subparse("\x0A\x7e\x04\x05" ~ ('x' x 1029)).made;
    is $got.payload.chars, 1029;
}, 'payload 126';

subtest {
    my $got = WebSocket::Frame::Grammar.subparse("\x0A\x7f\x00\x00\x00\x00\x00\x00\x04\x05" ~ ('x' x 1029)).made;
    is $got.payload.chars, 1029;
}, 'payload 127';

# 5.7. examples
subtest {
    my $a = parse("\x81\x05\x48\x65\x6c\x6c\x6f");
    is $a.payload, 'Hello';
}, 'hello';

subtest {
    my $a = parse("\x81\x85\x37\xfa\x21\x3d\x7f\x9f\x4d\x51\x58");
    is $a.payload, 'Hello';
}, 'masked hello';

subtest {
    my $a = parse("\x01\x03\x48\x65\x6c");
    is $a.payload, 'Hel';
    my $b = parse("\x80\x02\x6c\x6f");
    is $b.payload, 'lo';
}, 'A fragmented unmasked text message';

subtest {
    my $b = parse("\x89\x05\x48\x65\x6c\x6c\x6f");
    is $b.payload, 'Hello';
    ok $b.is-ping;

    my $c = parse("\x8a\x85\x37\xfa\x21\x3d\x7f\x9f\x4d\x51\x58");
    is $c.payload, 'Hello';
    ok $c.is-pong;
}, 'Unmasked Ping request and masked Ping response';

subtest {
    my $b = parse("\x82\x7E\x01\x00" ~ ('x' x 256));
    is $b.payload, 'x' x 256;
    ok $b.is-binary;
}, '256 bytes binary message in a single unmasked frame';

subtest {
    my $s = "\x82\x7F\x00\x00\x00\x00\x00\x01\x00\x00" ~ ('x' x 65536);
    my $b = parse($s);
    is $b.payload, 'x' x 65536;
    ok $b.is-binary;
}, '64KiB binary message in a single unmasked frame';

sub parse($s) {
    WebSocket::Frame::Grammar.subparse($s).made;
}

done-testing;

