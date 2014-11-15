
# Do not connect to live servers during testing
BEGIN { $ENV{ MOJO_IRC_OFFLINE } = 1 };
use Freyr::Base 'Test';
use Freyr::Route;
use Freyr::Message;
use Freyr::Error;

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

subtest 'placeholders' => sub {
    subtest 'required placeholder' => sub {
        my $r = Freyr::Route->new(
            prefix => [ '!', qr{freyr[:,]} ],
        );

        $r->msg( 'greet :who' => sub {
            my ( $msg, %params ) = @_;
            return sprintf 'Hello, %s!', $params{who};
        } );

        subtest 'prefixed message with placeholder content' => sub {
            my $msg = Freyr::Message->new(
                @msg_args,
                text => '!greet Perl',
            );
            my $reply = $r->dispatch( $msg );
            is $reply, 'Hello, Perl!';
        };

        subtest 'missing placeholder is not responded to' => sub {
            my $msg = Freyr::Message->new(
                @msg_args,
                text => '!greet',
            );
            ok !$r->dispatch( $msg );
        };

        subtest 'unprefixed message is not responded to' => sub {
            my $msg = Freyr::Message->new(
                @msg_args,
                text => 'greet Perl',
            );
            ok !$r->dispatch( $msg );
        };

    };
    subtest 'optional placeholder' => sub {
        my $r = Freyr::Route->new(
            prefix => [ '!', qr{freyr[:,]} ],
        );

        $r->msg( 'greet :who?' => sub {
            my ( $msg, %params ) = @_;
            return sprintf 'Hello, %s!', $params{who} // "Stranger";
        } );

        subtest 'prefixed message with placeholder content' => sub {
            my $msg = Freyr::Message->new(
                @msg_args,
                text => '!greet Perl',
            );
            my $reply = $r->dispatch( $msg );
            is $reply, 'Hello, Perl!';
        };

        subtest 'missing placeholder uses default value' => sub {
            my $msg = Freyr::Message->new(
                @msg_args,
                text => '!greet',
            );
            my $reply = $r->dispatch( $msg );
            is $reply, 'Hello, Stranger!';
        };

        subtest 'unprefixed message is not responded to' => sub {
            my $msg = Freyr::Message->new(
                @msg_args,
                text => 'greet Perl',
            );
            ok !$r->dispatch( $msg );
        };

    };
};

subtest 'under router' => sub {

    subtest 'route tree' => sub {
        my $root = Freyr::Route->new;
        subtest 'root' => sub {
            isa_ok $root, 'Freyr::Route';
            ok !$root->parent;
            ok !$root->root;
        };

        my $branch = $root->under( 'parent' );
        subtest 'branch off the root' => sub {
            isa_ok $branch, 'Freyr::Route';
            is $branch->parent, $root;
            is $branch->root, $root;
        };

        my $leaf = $branch->under( 'child' );
        subtest 'leaf off the branch' => sub {
            isa_ok $leaf, 'Freyr::Route';
            is $leaf->parent, $branch;
            is $leaf->root, $root;
        };
    };

    subtest 'prefixed message' => sub {
        my $root = Freyr::Route->new(
            prefix => [ '!', qr{freyr[:,]} ],
        );
        $root->msg( greet => sub { return "Hello!" } );
        my $r = $root->under( 'fr' );
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
        my $r = $root->under( '/fr' );
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

    subtest 'stop routing' => sub {
        my $r = Freyr::Route->new(
            prefix => [ '!', qr{freyr[:,]} ],
        );

        my $deep = $r->under( 'deep' => sub {
            die Freyr::Error->new(
                message => $_[0],
                error => "Deep error!",
            ) if $_[0]->text =~ /error/;
            return $_[0]->text =~ /safe/;
        } );

        my $hello = 0;
        $deep->msg( 'hello' => sub { ++$hello } );

        subtest 'callback returns false' => sub {
            $hello = 0;
            my $msg = Freyr::Message->new(
                @msg_args,
                text => '!deep hello',
            );
            ok !$r->dispatch( $msg );
            is $hello, 0, 'hello was not reached';
        };

        subtest 'callback returns true' => sub {
            $hello = 0;
            my $msg = Freyr::Message->new(
                @msg_args,
                text => '!deep hello safe',
            );
            my $reply = $r->dispatch( $msg );
            is $hello, 1, 'hello was reached';
            is $reply, $hello, 'hello callback result returned';
        };

        subtest 'callback throws exception' => sub {
            $hello = 0;
            my $msg = Freyr::Message->new(
                @msg_args,
                text => '!deep error',
            );
            throws_ok { $r->dispatch( $msg ) } 'Freyr::Error';
            is $@->error, 'Deep error!';
            is $hello, 0, 'hello was not reached';
        };

    };
};

done_testing;
