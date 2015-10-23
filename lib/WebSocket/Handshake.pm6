use v6;

unit module WebSocket::Handshake;

use MIME::Base64;
use Digest::SHA;

sub make-sec-websocket-accept($ws-key) is export {
    MIME::Base64.encode(sha1($ws-key ~ "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"));
}
