use v6;

unit grammar WebSocket::Frame::Grammar;

use WebSocket::Frame;

# https://gist.github.com/smls/bc5d0fb42f199574e339

# https://tools.ietf.org/html/rfc6455#section-5.2

#     0                   1                   2                   3
#     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
#    +-+-+-+-+-------+-+-------------+-------------------------------+
#    |F|R|R|R| opcode|M| Payload len |    Extended payload length    |
#    |I|S|S|S|  (4)  |A|     (7)     |             (16/64)           |
#    |N|V|V|V|       |S|             |   (if payload len==126/127)   |
#    | |1|2|3|       |K|             |                               |
#    +-+-+-+-+-------+-+-------------+ - - - - - - - - - - - - - - - +
#    |     Extended payload length continued, if payload len == 127  |
#    + - - - - - - - - - - - - - - - +-------------------------------+
#    |                               |Masking-key, if MASK set to 1  |
#    +-------------------------------+-------------------------------+
#    | Masking-key (continued)       |          Payload Data         |
#    +-------------------------------- - - - - - - - - - - - - - - - +
#    :                     Payload Data continued ...                :
#    + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +
#    |                     Payload Data continued ...                |
#    +---------------------------------------------------------------+

# in Perl6, bitwise shift operator is '+>' and '+<'.
# Numeric bitwise and operator is '+&'

sub mask(Str $payload is copy, Str $mask is copy) {
    $mask = $mask x (($payload.chars / 4).Int + 1);
    $mask = $mask.substr(0, $payload.chars);
    $payload = "$payload" ~^ $mask;
    return $payload;
}

token TOP {
    ^
    :my $*MASK;
    :my $*MASKING-KEY;
    :my $*PAYLOAD-LEN;
    <hdr>
    <mask-payload-len>
    <masking-key>
    <payload>
    {
        $/.make: WebSocket::Frame.new(
            |$/<hdr>.made,
            payload-len => $*PAYLOAD-LEN,
            payload => $*MASK ?? mask(~$/<payload>, $*MASKING-KEY) !! ~$/<payload>
        )
    }
}

token hdr {
    (.)
    {
        my $c = $/[0].Str.ord;
        my %hdr = fin  => so(($c +> 7) +& 0x01),
                 opcode => $c +& 0x0f;
        $/.make: %hdr;
    }
}

# <?{ ... }> is assertion.
token mask-payload-len {
    .
    {
        my $c = $/.Str.ord;
        $*MASK = so(($c +> 7) +& 0x01);
        $*PAYLOAD-LEN = $c +& 0x7F;
    }
    [ <.payload-len126> || <.payload-len127> ]?
}

# If 126, the following 2 bytes interpreted as a
# 16-bit unsigned integer are the payload length.
token payload-len126 {
    (. ** 2)
    <?{ $*PAYLOAD-LEN == 126 }>
    {
        my @c = $/[0].Str.ords;
        $*PAYLOAD-LEN = (@c[0] +< 8) +| @c[1];
    }
}


token payload-len127 {
    (. ** 8)
    <?{ $*PAYLOAD-LEN == 127 }>
    {
        my @c = $/[0].Str.ords;
        $*PAYLOAD-LEN =
            @c[0] +< ( 8*7 )
            + @c[1] +< ( 8*6 )
            + @c[2] +< ( 8*5 )
            + @c[3] +< ( 8*4 )
            + @c[4] +< ( 8*3 )
            + @c[5] +< ( 8*2 )
            + @c[6] +< ( 8   )
            + @c[7]
    }
}

token masking-key {
    [
        . ** 4
        <?{ $*MASK == True }>
        { $*MASKING-KEY = ~$/ }
        ||
        <?{ $*MASK == False }>
    ]
}

token payload {
    . ** {$*PAYLOAD-LEN}
}

