use v6;
use experimental :pack;

unit class WebSocket::Frame;

constant CONTINUATION = 0x00;
constant TEXT         = 0x01;
constant BINARY       = 0x02;
constant DOCLOSE        = 0x08;
constant PING         = 0x09;
constant PONG         = 0x0A;

has Bool $.fin;
has Int $.opcode;
has $.masking-key is rw;
has $.payload = Buf.new();

method is-text()   { $.opcode == TEXT   }
method is-binary() { $.opcode == BINARY }
method is-close()  { $.opcode == DOCLOSE  }
method is-ping()   { $.opcode == PING   }
method is-pong()   { $.opcode == PONG   }

method is-control() { $.opcode ~~ DOCLOSE | PING | PONG }

method Buf() {
    my Buf $s = pack('C', ((($!fin ?? 1 !! 0) +< 7) +| $.opcode));
    my $payload = $.payload ~~ Str ?? $.payload.encode('utf-8') !! $.payload;
    my $masking-bit = $.masking-key.defined ?? 0x80 !! 0;
    given $payload.bytes {
        when $_ < 126 {
            $s ~= pack 'C', $_ + $masking-bit;
        }
        when $_ <= 0xffff {
            $s ~= pack 'C', 126 + $masking-bit;
            $s ~= pack 'n', $_;
        }
        default {
            $s ~= pack 'C', 127 + $masking-bit;
            $s ~= pack 'N', $_ +> 32;
            $s ~= pack 'N', $_ +& 0xffffffff;
        }
    }
    if $!masking-key.defined {
        $s ~= $!masking-key;
        $s ~= mask($payload, $!masking-key.decode('latin1'));
    } else {
        $s ~= $payload;
    }
    return $s;
}

sub mask(Blob $payload is copy, Str $mask is copy) {
    $mask = $mask x (($payload.bytes / 4).Int + 1);
    $mask = $mask.substr(0, $payload.bytes);
    $payload = $payload ~^ $mask.encode('latin1');
    return $payload;
}

# opcode is:
#  %x0 denotes a continuation frame
#  %x1 denotes a text frame
#  %x2 denotes a binary frame
#  %x3-7 are reserved for further non-control frames
#  %x8 denotes a connection close
#  %x9 denotes a ping
#  %xA denotes a pong
#  %xB-F are reserved for further control frames

