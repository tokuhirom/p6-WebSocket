use v6;

unit class WebSocket::URL;

has Bool $.secure = False;
has Str $.host;
has Int $.port;
has Str $.resource-name;

grammar URLGrammar {
    token TOP { <scheme> "://" <host> [ ":" <port> ]? <resource-name> }
    token resource-name { .* }
    token host { <-[ \: / ]>+ }
    token port { <[ 0..9 ]>+ }
    token scheme { "ws" "s"? }
}

method parse(WebSocket::URL:D: Str $string) {
    my $m = URLGrammar.parse($string);
    if $m {
        $!secure = $m<scheme> eq 'wss';
        $!host = ~$m<host>;
        $!port = $m<port> ?? $m<port>.Str.Int !! ($!secure ?? 443 !! 80);
        $!resource-name = $m<resource-name> ?? $m<resource-name>.Str !! '/';
        if $!resource-name eq '' {
            $!resource-name = '/';
        }
        return True;
    } else {
        return False;
    }
}

method Str() {
    join("",
        $!secure ?? "wss" !! "ws",
        "://",
        $!host,
        $!port.defined ?? ":" ~ $!port !! "",
        $!resource-name || '/'
    );
}

=begin pod

=head1 NAME

WebSocket::URL - WebSocket URL

=head1 SYNOPSIS

=begin code

    # Construct
    my $url = WebSocket::URL.new;
    $url.host('example.com');
    $url.port('3000');
    $url.secure(1);
    $url.Str; # wss://example.com:3000

    # Parse
    my $url = WebSocket::URL.new.parse('wss://example.com:3000');
    $url.host;   # example.com
    $url.port;   # 3000
    $url.secure; # 1

=end code

=head1 DESCRIPTION

Construct or parse a WebSocket URL.

=head1 ATTRIBUTES

=head2 C<host>

=head2 C<port>

=head2 C<resource_name>

=head2 C<secure>

=head1 METHODS

=head2 C<new>

Create a new L<WebSocket::URL> instance.

=head2 C<parse>

Parse a WebSocket URL.

=head2 C<to_string>

Construct a WebSocket URL.

=end pod
