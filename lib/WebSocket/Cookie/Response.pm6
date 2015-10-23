use v6;

use WebSocket::Cookie;

unit class WebSocket::Cookie::Response is WebSocket::Cookie;

has $.name;
has $.value;
has $.comment;
has $.comment-url;
has $.discard;
has $.max-age;
has $.path;
has Array $.portlist;
has $.secure;

method Str() {
    my @pairs;

    push @pairs, $.name => $.value;

    push @pairs, 'Comment' => $.comment if defined $.comment;

    push @pairs, 'CommentURL' => $.comment-url
      if defined $.comment-url;

    push @pairs, (Discard => Nil) if $.discard;

    push @pairs, 'Max-Age' => $.max-age if defined $.max-age;

    push @pairs, 'Path'    => $.path    if defined $.path;

    if (defined $.portlist) {
        my $list = join ' ', $.portlist;
        push @pairs, 'Port' => "\"$list\"";
    }

    push @pairs, (Secure => Nil) if $.secure;

    push @pairs, 'Version' => '1';

    self.pairs = @pairs;

    return callsame;
}

=begin pod

=head1 NAME

WebSocket::Cookie::Response - WebSocket Cookie Response

=head1 SYNOPSIS

    # Constructor
    my $cookie = WebSocket::Cookie::Response.new(
        name    => 'foo',
        value   => 'bar',
        discard => 1,
        max-age => 0
    );
    $cookie.to_string; # foo=bar; Discard; Max-Age=0; Version=1

    # Parser
    my $cookie = WebSocket::Cookie::Response.new;
    $cookie.parse('foo=bar; Discard; Max-Age=0; Version=1');

=head1 DESCRIPTION

Construct or parse a WebSocket response cookie.

=head1 METHODS

=head2 C<parse>

Parse a WebSocket response cookie.

=head2 C<to_string>

Construct a WebSocket response cookie.

=end pod

