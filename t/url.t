use v6;
use Test;

use WebSocket::URL;

my $url = WebSocket::URL.parse('ws://example.com');
is $url.scheme, 'ws';
is $url.host, 'example.com';
is $url.port, '80';
is $url.resource-name, '/';

$url = WebSocket::URL.parse('ws://example.com/');
is $url.scheme, 'ws';
is $url.host          , 'example.com';
is $url.resource-name , '/';

$url = WebSocket::URL.parse('ws://example.com/demo');
is $url.scheme, 'ws';
is $url.host          , 'example.com';
is $url.resource-name , '/demo';

$url = WebSocket::URL.parse('ws://example.com:3000');
is $url.scheme, 'ws';
is $url.host          , 'example.com';
is $url.port          , '3000';
is $url.resource-name , '/';

$url = WebSocket::URL.parse('ws://example.com/demo?foo=bar');
is $url.scheme, 'ws';
is $url.host          , 'example.com';
is $url.resource-name , '/demo?foo=bar';

$url = WebSocket::URL.parse('wss://example.com');
is $url.scheme, 'wss';
is $url.host          , 'example.com';
is $url.port          , '443';
is $url.resource-name , '/';

$url = WebSocket::URL.parse('wss://example.com:3000');
is $url.scheme, 'wss';
is $url.host          , 'example.com';
is $url.port          , '3000';
is $url.resource-name , '/';

$url = WebSocket::URL.new(host => 'foo.com', scheme => 'wss');
is $url.Str, 'wss://foo.com/';

$url = WebSocket::URL.new(
    host          => 'foo.com',
    resource-name => '/demo'
);
is $url.Str, 'ws://foo.com/demo';

$url = WebSocket::URL.new(
    host => 'foo.com',
    port => 3000
);
is $url.Str, 'ws://foo.com:3000/';

done-testing;
