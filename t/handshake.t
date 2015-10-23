use v6;

use Test;

use WebSocket::Handshake;

is make-sec-websocket-accept('dGhlIHNhbXBsZSBub25jZQ=='), 's3pPLMBiTxaQ9kYGzzhZRbK+xOo=';

done-testing;
