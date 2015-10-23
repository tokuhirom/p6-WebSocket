use v6;
use Test;
use WebSocket::Frame::Grammar;

subtest {
    my $got = WebSocket::Frame::Grammar.subparse("\xfA\x[01]a".encode('latin1').decode('latin1')).made;
    is-deeply $got.fin, True;
    is-deeply $got.rsv1, 1;
    is-deeply $got.rsv2, 1;
    is-deeply $got.rsv3, 1;
}, 'true';

subtest {
    my $src = "\x[0A]\x[01]a".encode('latin1').decode('latin1');
    my $got = WebSocket::Frame::Grammar.subparse($src).made;
    is-deeply $got.fin, False;
    is-deeply $got.rsv1, 0;
    is-deeply $got.rsv2, 0;
    is-deeply $got.rsv3, 0;
    is-deeply $got.payload-len, 1;
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

sub parse($s) {
    WebSocket::Frame::Grammar.subparse($s).made;
}

done-testing;

