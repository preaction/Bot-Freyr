
# Do not connect to live servers during testing
BEGIN { $ENV{ MOJO_IRC_OFFLINE } = 1 };
use Freyr::Base 'Test';
use Freyr::Route;
use Freyr::Message;

my $bot = Freyr->new(
    nick => 'freyr',
    host => 'irc.freenode.net',
    channels => [ '#defocus' ],
);

my @msg_args = (
    bot => $bot,
    network => $bot->network,
    channel => $bot->network->channel( '#defocus' ),
    to => '#defocus',
    nick => 'preaction',
);

subtest 'basic routes' => sub {

    subtest 'prefixed/addressed message' => sub {
        my $r = Freyr::Route->new(
            prefix => [ '!', qr{freyr[:,]} ],
        );
        $r->msg( greet => sub { return "Hello!" } );
        my ( $msg );

        subtest 'string prefix' => sub {
            $msg = Freyr::Message->new(
                @msg_args,
                text => '!greet',
            );
            is $r->dispatch( $msg ), 'Hello!';
        };

        subtest 'regex prefix' => sub {
            $msg = Freyr::Message->new(
                @msg_args,
                text => 'freyr: greet',
            );
            is $r->dispatch( $msg ), 'Hello!';
        };

        subtest 'no prefix -> no response' => sub {
            $msg = Freyr::Message->new(
                @msg_args,
                text => 'greet',
            );
            ok !$r->dispatch( $msg );
        };
    };

    subtest 'unprefixed message' => sub {
        my $r = Freyr::Route->new(
            prefix => [ '!', qr{freyr[:,]} ],
        );
        $r->privmsg( greet => sub { return "Hello!" } );
        my ( $msg );

        subtest 'without prefix' => sub {
            $msg = Freyr::Message->new(
                @msg_args,
                text => 'greet',
            );
            is $r->dispatch( $msg ), 'Hello!';
        };

        subtest 'with prefix -> no response' => sub {
            $msg = Freyr::Message->new(
                @msg_args,
                text => '!greet',
            );
            ok !$r->dispatch( $msg );
        };
    };
};

subtest 'under routes' => sub {

    subtest 'prefixed messages' => sub {
        my $r = Freyr::Route->new(
            prefix => [ '!', qr{freyr[:,]} ],
        );
        my $seen = 0;
        $r->under( '' => sub { $seen++; return; } );

        subtest 'string prefix' => sub {
            my $msg = Freyr::Message->new(
                @msg_args,
                text => '!greet',
            );
            ok !$r->dispatch( $msg );
            is $seen, 1;
        };

        subtest 'regex prefix' => sub {
            my $msg = Freyr::Message->new(
                @msg_args,
                text => 'freyr: greet',
            );
            ok !$r->dispatch( $msg );
            is $seen, 2;
        };

        subtest 'no prefix -> no destination' => sub {
            my $msg = Freyr::Message->new(
                @msg_args,
                text => 'greet',
            );
            ok !$r->dispatch( $msg );
            is $seen, 2;
        };
    };

    subtest 'unprefixed messages' => sub {
        my $r = Freyr::Route->new(
            prefix => [ '!', qr{freyr[:,]} ],
        );
        my $seen = 0;
        $r->under( '/' => sub { $seen++; return; } );

        subtest 'no prefix' => sub {
            my $msg = Freyr::Message->new(
                @msg_args,
                text => 'greet',
            );
            ok !$r->dispatch( $msg );
            is $seen, 1;
        };

        subtest 'prefix still matches' => sub {
            my $msg = Freyr::Message->new(
                @msg_args,
                text => '!greet',
            );
            ok !$r->dispatch( $msg );
            is $seen, 2;
        };
    };
};

subtest 'child router' => sub {

    subtest 'prefixed message' => sub {
        my $root = Freyr::Route->new(
            prefix => [ '!', qr{freyr[:,]} ],
        );
        $root->msg( greet => sub { return "Hello!" } );
        my $r = $root->child( 'fr' );
        $r->msg( greet => sub { return "Bonjour!" } );
        my ( $msg );

        subtest 'string prefix' => sub {
            $msg = Freyr::Message->new(
                @msg_args,
                text => '!fr greet',
            );
            is $root->dispatch( $msg ), 'Bonjour!';
        };

        subtest 'regex prefix' => sub {
            $msg = Freyr::Message->new(
                @msg_args,
                text => 'freyr: fr greet',
            );
            is $root->dispatch( $msg ), 'Bonjour!';
        };

        subtest 'no prefix -> no response' => sub {
            $msg = Freyr::Message->new(
                @msg_args,
                text => 'fr greet',
            );
            ok !$root->dispatch( $msg );
        };
    };


    subtest 'unprefixed message' => sub {
        my $root = Freyr::Route->new(
            prefix => [ '!', qr{freyr[:,]} ],
        );
        $root->msg( greet => sub { return "Hello!" } );
        my $r = $root->child( '/fr' );
        $r->privmsg( greet => sub { return "Bonjour!" } );
        my ( $msg );

        subtest 'without prefix' => sub {
            $msg = Freyr::Message->new(
                @msg_args,
                text => 'fr greet',
            );
            is $root->dispatch( $msg ), 'Bonjour!';
        };

        subtest 'with prefix -> no response' => sub {
            $msg = Freyr::Message->new(
                @msg_args,
                text => '!fr greet',
            );
            ok !$root->dispatch( $msg );
        };
    };

};

done_testing;
