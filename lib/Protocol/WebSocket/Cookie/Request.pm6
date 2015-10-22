use v6;
use Protocol::WebSocket::Cookie;

unit class Protocol::WebSocket::Cookie::Request is Protocol::WebSocket::Cookie;

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
        if $pair.key ~~ /^ <-[ \\ \$ ]> / {
            push @cookies, $cookie if $cookie.defined;
            $cookie = self!build-cookie(
                name  => $pair.key,
                value => $pair.value,
                version => $version,
            );
        } elsif $pair.key eq '$Path' {
            $cookie.path = $pair.value;
        } elsif $pair.key eq '$Domain' {
            $cookie.domain = $pair.value;
        }
    }
    push @cookies, $cookie if defined $cookie;
    return @cookies;
}

method !build-cookie(*%args) {
    Protocol::WebSocket::Cookie::Request.new(|%args)
}

