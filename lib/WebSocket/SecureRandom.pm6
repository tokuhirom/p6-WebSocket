use v6;

unit class WebSocket::SecureRandom;

# TODO: mattnize
has $.fh;

method new() {
    my $fh = open '/dev/urandom', :r, :bin;
    self.bless(fh => $fh);
}

method read(Int $bytes) {
    $!fh.read($bytes);
}

