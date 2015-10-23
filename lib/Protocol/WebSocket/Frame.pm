use v6;

unit class Protocol::WebSocket::Frame;

has $.fin;
has $.rsv1;
has $.rsv2;
has $.rsv3;
has $.opcode;
has $.payload-len;
has $.payload;

