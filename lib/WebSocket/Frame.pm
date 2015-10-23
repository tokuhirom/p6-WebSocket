use v6;

unit class WebSocket::Frame;

constant CONTINUATION = 0x00;
constant TEXT         = 0x01;
constant BINARY       = 0x02;
constant CLOSE        = 0x08;
constant PING         = 0x09;
constant PONG         = 0x0A;

has Bool $.fin;
has Int $.opcode;
has $.payload = Buf.new();

method is-text()   { $.opcode == TEXT   }
method is-binary() { $.opcode == BINARY }
method is-close()  { $.opcode == CLOSE  }
method is-ping()   { $.opcode == PING   }
method is-pong()   { $.opcode == PONG   }

method Buf() {
    my Buf $s = pack('C', ((($!fin ?? 1 !! 0) +< 7) +| $.opcode));
    my $payload = $.payload ~~ Str ?? $.payload.encode('utf-8') !! $.payload;
    given $payload.bytes {
        when $_ < 126 {
            $s ~= pack 'C', $_;
        }
        when $_ <= 0xffff {
            $s ~= pack 'C', 126;
            $s ~= pack 'n', $_;
        }
        default {
            $s ~= pack 'C', 127;
            $s ~= pack 'N', $_ +> 32;
            $s ~= pack 'N', $_ +& 0xffffffff;
        }
    }
    $s ~= $payload;
    return $s;
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

