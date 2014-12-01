
# Do not connect to live servers during testing
BEGIN { $ENV{ MOJO_IRC_OFFLINE } = 1 };
use Bot::Freyr::Base 'Test';
use Bot::Freyr::Route;
use Bot::Freyr::Message;
use Bot::Freyr::Error;

my $bot = Bot::Freyr->new(
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
        my $r = Bot::Freyr::Route->new(
            prefix => [ '!', qr{freyr[:,]} ],
        );
        $r->msg( greet => sub { return "Hello!" } );
        my ( $msg );

        subtest 'string prefix' => sub {
            $msg = Bot::Freyr::Message->new(
                @msg_args,
                text => '!greet',
            );
            is $r->dispatch( $msg ), 'Hello!';
        };

        subtest 'regex prefix' => sub {
            $msg = Bot::Freyr::Message->new(
                @msg_args,
                text => 'freyr: greet',
            );
            is $r->dispatch( $msg ), 'Hello!';
        };

        subtest 'no prefix -> no response' => sub {
            $msg = Bot::Freyr::Message->new(
                @msg_args,
                text => 'greet',
            );
            ok !$r->dispatch( $msg );
        };
    };

    subtest 'unprefixed message' => sub {
        my $r = Bot::Freyr::Route->new(
            prefix => [ '!', qr{freyr[:,]} ],
        );
        $r->privmsg( greet => sub { return "Hello!" } );
        my ( $msg );

        subtest 'without prefix' => sub {
            $msg = Bot::Freyr::Message->new(
                @msg_args,
                text => 'greet',
            );
            is $r->dispatch( $msg ), 'Hello!';
        };

        subtest 'with prefix -> no response' => sub {
            $msg = Bot::Freyr::Message->new(
                @msg_args,
                text => '!greet',
            );
            ok !$r->dispatch( $msg );
        };
    };

    subtest 'default routes' => sub {
        subtest 'prefix' => sub {
            my $r = Bot::Freyr::Route->new(
                prefix => [ '!' ],
            );
            $r->msg( sub { return "Hello!" } );
            $r->msg( bye => sub { return 'Goodbye!' } );

            my $msg = Bot::Freyr::Message->new(
                @msg_args,
                text => '!bye',
            );
            is $r->dispatch( $msg ), 'Goodbye!';

            $msg = Bot::Freyr::Message->new(
                @msg_args,
                text => '!hello',
            );
            is $r->dispatch( $msg ), 'Hello!';

        };

        subtest 'unprefix' => sub {
            my $r = Bot::Freyr::Route->new(
                prefix => [ '!' ],
            );
            $r->privmsg( sub { return "Hello!" } );
            $r->privmsg( bye => sub { return 'Goodbye!' } );

            my $msg = Bot::Freyr::Message->new(
                @msg_args,
                text => 'bye',
            );
            is $r->dispatch( $msg ), 'Goodbye!';

            $msg = Bot::Freyr::Message->new(
                @msg_args,
                text => 'hello',
            );
            is $r->dispatch( $msg ), 'Hello!';

        };
    };
};

subtest 'placeholders' => sub {
    subtest 'required placeholder' => sub {
        my $r = Bot::Freyr::Route->new(
            prefix => [ '!', qr{freyr[:,]} ],
        );

        $r->msg( 'greet :who' => sub {
            my ( $msg, %params ) = @_;
            return sprintf 'Hello, %s!', $params{who};
        } );

        subtest 'prefixed message with placeholder content' => sub {
            my $msg = Bot::Freyr::Message->new(
                @msg_args,
                text => '!greet Perl',
            );
            my $reply = $r->dispatch( $msg );
            is $reply, 'Hello, Perl!';
        };

        subtest 'missing placeholder is not responded to' => sub {
            my $msg = Bot::Freyr::Message->new(
                @msg_args,
                text => '!greet',
            );
            ok !$r->dispatch( $msg );
        };

        subtest 'unprefixed message is not responded to' => sub {
            my $msg = Bot::Freyr::Message->new(
                @msg_args,
                text => 'greet Perl',
            );
            ok !$r->dispatch( $msg );
        };

    };
    subtest 'optional placeholder' => sub {
        my $r = Bot::Freyr::Route->new(
            prefix => [ '!', qr{freyr[:,]} ],
        );

        $r->msg( 'greet :who?' => sub {
            my ( $msg, %params ) = @_;
            return sprintf 'Hello, %s!', $params{who} // "Stranger";
        } );

        subtest 'prefixed message with placeholder content' => sub {
            my $msg = Bot::Freyr::Message->new(
                @msg_args,
                text => '!greet Perl',
            );
            my $reply = $r->dispatch( $msg );
            is $reply, 'Hello, Perl!';
        };

        subtest 'missing placeholder uses default value' => sub {
            my $msg = Bot::Freyr::Message->new(
                @msg_args,
                text => '!greet',
            );
            my $reply = $r->dispatch( $msg );
            is $reply, 'Hello, Stranger!';
        };

        subtest 'unprefixed message is not responded to' => sub {
            my $msg = Bot::Freyr::Message->new(
                @msg_args,
                text => 'greet Perl',
            );
            ok !$r->dispatch( $msg );
        };

    };
};

subtest 'under router' => sub {

    subtest 'route tree' => sub {
        my $root = Bot::Freyr::Route->new;
        subtest 'root' => sub {
            isa_ok $root, 'Bot::Freyr::Route';
            ok !$root->parent;
            ok !$root->root;
        };

        my $branch = $root->under( 'parent' );
        subtest 'branch off the root' => sub {
            isa_ok $branch, 'Bot::Freyr::Route';
            is $branch->parent, $root;
            is $branch->root, $root;
        };

        my $leaf = $branch->under( 'child' );
        subtest 'leaf off the branch' => sub {
            isa_ok $leaf, 'Bot::Freyr::Route';
            is $leaf->parent, $branch;
            is $leaf->root, $root;
        };
    };

    subtest 'prefixed message' => sub {
        my $root = Bot::Freyr::Route->new(
            prefix => [ '!', qr{freyr[:,]} ],
        );
        $root->msg( greet => sub { return "Hello!" } );
        my $r = $root->under( 'fr' );
        $r->msg( greet => sub { return "Bonjour!" } );
        my ( $msg );

        subtest 'string prefix' => sub {
            $msg = Bot::Freyr::Message->new(
                @msg_args,
                text => '!fr greet',
            );
            is $root->dispatch( $msg ), 'Bonjour!';
        };

        subtest 'regex prefix' => sub {
            $msg = Bot::Freyr::Message->new(
                @msg_args,
                text => 'freyr: fr greet',
            );
            is $root->dispatch( $msg ), 'Bonjour!';
        };

        subtest 'no prefix -> no response' => sub {
            $msg = Bot::Freyr::Message->new(
                @msg_args,
                text => 'fr greet',
            );
            ok !$root->dispatch( $msg );
        };
    };


    subtest 'unprefixed message' => sub {
        my $root = Bot::Freyr::Route->new(
            prefix => [ '!', qr{freyr[:,]} ],
        );
        $root->msg( greet => sub { return "Hello!" } );
        my $r = $root->under( '/fr' );
        $r->privmsg( greet => sub { return "Bonjour!" } );
        my ( $msg );

        subtest 'without prefix' => sub {
            $msg = Bot::Freyr::Message->new(
                @msg_args,
                text => 'fr greet',
            );
            is $root->dispatch( $msg ), 'Bonjour!';
        };

        subtest 'with prefix -> no response' => sub {
            $msg = Bot::Freyr::Message->new(
                @msg_args,
                text => '!fr greet',
            );
            ok !$root->dispatch( $msg );
        };
    };

    subtest 'stop routing' => sub {
        my $r = Bot::Freyr::Route->new(
            prefix => [ '!', qr{freyr[:,]} ],
        );

        my $deep = $r->under( 'deep' => sub {
            die Bot::Freyr::Error->new(
                message => $_[0],
                error => "Deep error!",
            ) if $_[0]->text =~ /error/;
            return $_[0]->text =~ /safe/;
        } );

        my $hello = 0;
        $deep->msg( 'hello' => sub { ++$hello } );

        subtest 'callback returns false' => sub {
            $hello = 0;
            my $msg = Bot::Freyr::Message->new(
                @msg_args,
                text => '!deep hello',
            );
            ok !$r->dispatch( $msg );
            is $hello, 0, 'hello was not reached';
        };

        subtest 'callback returns true' => sub {
            $hello = 0;
            my $msg = Bot::Freyr::Message->new(
                @msg_args,
                text => '!deep hello safe',
            );
            my $reply = $r->dispatch( $msg );
            is $hello, 1, 'hello was reached';
            is $reply, $hello, 'hello callback result returned';
        };

        subtest 'callback throws exception' => sub {
            $hello = 0;
            my $msg = Bot::Freyr::Message->new(
                @msg_args,
                text => '!deep error',
            );
            throws_ok { $r->dispatch( $msg ) } 'Bot::Freyr::Error';
            is $@->error, 'Deep error!';
            is $hello, 0, 'hello was not reached';
        };

    };
};

subtest 'routing events' => sub {
    subtest 'before_dispatch' => sub {

        subtest 'allows continuing' => sub {
            my $r = Bot::Freyr::Route->new(
                prefix => [ '!' ],
            );

            $r->msg( event => sub { return "EVENT" } );

            my $msg = Bot::Freyr::Message->new(
                @msg_args,
                text => '!event',
            );

            my $seen = 0;
            $r->on( before_dispatch => sub ( $event ) {
                $seen++;
                isa_ok $event, 'Bot::Freyr::Event::Message';
                is $event->message, $msg;
            } );

            my $reply = $r->dispatch( $msg );
            is $reply, 'EVENT';
            is $seen, 1;
        };

        subtest 'prevents further dispatch' => sub {
            my $r = Bot::Freyr::Route->new(
                prefix => [ '!' ],
            );

            $r->msg( event => sub { return "EVENT" } );

            my $msg = Bot::Freyr::Message->new(
                @msg_args,
                text => '!event',
            );

            my $seen = 0;
            $r->on( before_dispatch => sub ( $event ) {
                $seen++;
                isa_ok $event, 'Bot::Freyr::Event::Message';
                is $event->message, $msg;
                $event->stop_default;
            } );

            ok !$r->dispatch( $msg );
            is $seen, 1;
        };
    };

    subtest 'after_dispatch' => sub {

        subtest 'does not interrupt processing' => sub {
            my $r = Bot::Freyr::Route->new(
                prefix => [ '!' ],
            );

            $r->msg( event => sub { return "EVENT" } );

            my $msg = Bot::Freyr::Message->new(
                @msg_args,
                text => '!event',
            );

            my $seen = 0;
            $r->on( after_dispatch => sub ( $event ) {
                $seen++;
                isa_ok $event, 'Bot::Freyr::Event::Message';
                is $event->message, $msg;
                $event->stop_default;
            } );

            is $r->dispatch( $msg ), "EVENT";
            is $seen, 1;
        };
    };

    subtest 'child route with events' => sub {
        my @seen = ();
        my $root = Bot::Freyr::Route->new( prefix => [ '!' ] );
        $root->on( before_dispatch => sub { push @seen, [ before_dispatch => 'root' ] } );
        $root->on( after_dispatch => sub { push @seen, [ after_dispatch => 'root' ] } );

        my $branch = $root->under( 'parent' );
        $branch->on( before_dispatch => sub { push @seen, [ before_dispatch => 'branch' ] } );
        $branch->on( after_dispatch => sub { push @seen, [ after_dispatch => 'branch' ] } );

        my $leaf = $branch->under( 'child' );
        $leaf->on( before_dispatch => sub { push @seen, [ before_dispatch => 'leaf' ] } );
        $leaf->on( after_dispatch => sub { push @seen, [ after_dispatch => 'leaf' ] } );
        $leaf->msg( 'leaf' => sub { return "LEAF"; } );

        my $msg = Bot::Freyr::Message->new(
            @msg_args,
            text => '!parent child leaf',
        );

        is $root->dispatch( $msg ), 'LEAF';
        cmp_deeply \@seen, [
            [ before_dispatch => 'root' ],
            [ before_dispatch => 'branch' ],
            [ before_dispatch => 'leaf' ],
            [ after_dispatch => 'leaf' ],
            [ after_dispatch => 'branch' ],
            [ after_dispatch => 'root' ],
        ] or diag explain \@seen;

    };
};

done_testing;
