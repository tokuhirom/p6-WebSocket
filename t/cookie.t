use v6;

use Test;

use WebSocket::Cookie;
use WebSocket::Cookie::Response;
use WebSocket::Cookie::Request;

my $cookie;
my $cookies;

$cookie = WebSocket::Cookie.new;
$cookie.parse('');
is-deeply $cookie.pairs, [];

$cookie = WebSocket::Cookie.new;
$cookie.parse('');
$cookie.parse('foo=bar; baz = zab; hello= "the;re"; here');
is-deeply($cookie.pairs,
    [foo => 'bar', baz => 'zab', hello => 'the;re', 'here' => Nil]);
is $cookie.Str, 'foo=bar; baz=zab; hello="the;re"; here';


$cookie = WebSocket::Cookie.new;
$cookie.parse('$Foo="bar"');
is-deeply($cookie.pairs, ['$Foo' => 'bar']);


$cookie = WebSocket::Cookie.new;
$cookie.parse('foo=bar=123=xyz');
is-deeply($cookie.pairs, [['foo' => 'bar=123=xyz']]);


$cookie =
  WebSocket::Cookie::Response.new(name => 'foo', value => 'bar');
is $cookie.Str, 'foo=bar; Version=1';
$cookie = WebSocket::Cookie::Response.new(
    name    => 'foo',
    value   => 'bar',
    discard => True,
    max-age => 0
);
is $cookie.Str, 'foo=bar; Discard; Max-Age=0; Version=1';


$cookie = WebSocket::Cookie::Response.new(
    name     => 'foo',
    value    => 'bar',
    portlist => [80]
);
is $cookie.Str, 'foo=bar; Port="80"; Version=1';

$cookie = WebSocket::Cookie::Response.new(
    name     => 'foo',
    value    => 'bar',
    portlist => [80, 443]
);
is $cookie.Str , 'foo=bar; Port="80 443"; Version=1';

$cookie = WebSocket::Cookie::Request.new;
$cookies = $cookie.parse('$Version=1; foo=bar; $Path=/; $Domain=.example.com');
is $cookies[0].name    ,  'foo';
is $cookies[0].value   ,  'bar';
is $cookies[0].version ,  1;
is $cookies[0].path    ,  '/';
is $cookies[0].domain  ,  '.example.com';


$cookie = WebSocket::Cookie::Request.new;
$cookies = $cookie.parse('$Version=1; foo=bar');
is $cookies[0].name    , 'foo';
is $cookies[0].value   , 'bar';
is $cookies[0].version , 1;
ok not defined $cookies[0].path;
ok not defined $cookies[0].domain;

$cookie = WebSocket::Cookie::Request.new;
$cookies = $cookie.parse('$Version=1; foo="hello\"there"');
is $cookies[0].name  , 'foo';
is $cookies[0].value , 'hello"there';

$cookie = WebSocket::Cookie::Request.new;
$cookies = $cookie.parse(
    '$Version=1; foo="bar"; $Path=/; bar=baz; $Domain=.example.com');
is $cookies[0].name   , 'foo';
is $cookies[0].value  , 'bar';
is $cookies[0].path   , '/';
is $cookies[1].name   , 'bar';
is $cookies[1].value  , 'baz';
is $cookies[1].domain , '.example.com';

subtest {
    $cookie = WebSocket::Cookie::Request.new;
    $cookies = $cookie.parse('foo=bar; $Path=/; $Domain=.example.com');
    is $cookies[0].name    , 'foo';
    is $cookies[0].value   , 'bar';
    is $cookies[0].version , 1;
    is $cookies[0].path    , '/';
    is $cookies[0].domain  , '.example.com';
}, 'parse when no version is available';

done-testing;
