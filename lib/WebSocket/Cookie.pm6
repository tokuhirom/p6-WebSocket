use v6;
unit class WebSocket::Cookie;

has @.pairs is rw;

grammar CookieGrammar {
    token TOP {:s
        <pair> [ ';' <pair> ]* || \s*
    }
    token pair {:s <name> \s* [ '=' \s* <value> ]? }
    token token { <-[ \; \, \s \" ]>+ }
    token name { <-[ \; \, \s \" \= ]>+ }
    token quoted-string { '"' [ '\\' ( '"' ) | ( <-[ " ]> )  ]+ '"' }
    token value { [ <token> || <quoted-string> ] }
}

my class CookieActions {
    method TOP($/) {
        $/.make: $/<pair>».made;
    }
    method quoted-string($/) {
        $/.make: $/.caps».value.join("");
    }
    method name($/) { $/.make: ~$/ }
    method token($/) { $/.make: ~$/ }
    method pair($/) { $/.make: $/<name>.made => $/<value> ?? $/<value>.made !! Nil }
    method value($/) { $/.make: $<token> ?? $<token>.made !! $<quoted-string>.made }
}

method parse(Str $cookie) {
    my $actions = CookieActions.new;
    my $m = CookieGrammar.parse($cookie, :$actions);
    if $m {
        @!pairs = $m.made;
        self;
    } else {
        die "invalid cookie: '$cookie'";
        Nil
    }
}

method Str() {
    @!pairs.map(-> $pair {
        my ($k,$v) = ($pair.key, $pair.value);
        my $s = $k;
        if $v.defined {
            my regex token  { <-[ \; \, \s \" ]>+ }
            my regex quoted-string { '"' [ '\\' ( '"' ) | ( <-[ " ]> )  ]+ '"' }
            my regex value { [ <token> || <quoted-string> ] }
            $s ~= "=" ~ ( $v ~~ /^ <value> $/ ?? $v !! qq!"$v"! )
        }
        $s;
    }).join("; ");
}

=begin pod

=head1 NAME

WebSocket::Cookie - Base class for WebSocket cookies

=head1 DESCRIPTION

A base class for L<WebSocket::Cookie::Request> and
L<WebSocket::Cookie::Response>.

=head1 ATTRIBUTES

=head2 C<pairs>

=head1 METHODS

=head2 C<new>

Create a new L<WebSocket::Cookie> instance.

=head2 C<parse>

=head2 C<Str>

=end pod
