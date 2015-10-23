use v6;

unit class WebSocket::Stateful;

enum State is export <STATE_BODY STATE_DONE>;

has State $.state;

method done() {
    $!state = STATE_DONE;
}

method is-state(State $state) {
    $!state  == $state;
}

method is-body() {
    $!state == STATE_BODY;
}

method is-done() {
    $!state == STATE_DONE;
}

