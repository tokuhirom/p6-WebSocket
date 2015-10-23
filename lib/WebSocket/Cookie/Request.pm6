use v6;
use WebSocket::Cookie;

unit class WebSocket::Cookie::Request is WebSocket::Cookie;

has $.name is rw;
has $.value is rw;
has $.version is rw;
has $.path is rw;
has $.domain is rw;

method parse(Str $str) {
    callsame;

    my @cookies;
    my $version = 1;
    if @.pairs[0] eq '$Version' {
        my $pair = @.pairs.shift;
        $version = $pair.value;
    }

    my $cookie;
    for @.pairs -> $pair {
        next unless defined $pair.value;

        given $pair.key {
            when /^ <-[ \\ \$ ]> / {
                push @cookies, $cookie if $cookie.defined;
                $cookie = self!build-cookie(
                    name  => $pair.key,
                    value => $pair.value,
                    version => $version,
                );
            }
            when $pair.key eq '$Path' {
                $cookie.path = $pair.value;
            }
            when '$Domain' {
                $cookie.domain = $pair.value;
            }
        }
    }
    push @cookies, $cookie if defined $cookie;
    return @cookies;
}

method !build-cookie(*%args) {
    WebSocket::Cookie::Request.new(|%args)
}

