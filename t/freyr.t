
# Do not connect to live servers during testing
BEGIN { $ENV{ MOJO_IRC_OFFLINE } = 1 };
use Freyr::Base 'Test';
use Mojo::IOLoop;
use Freyr::Error;

subtest 'connect to networks' => sub {
    subtest 'single network' => sub {
        my $bot = Freyr->new(
            nick => 'freyr',
            host => 'irc.freenode.net',
        );
        my $net = $bot->network;
        isa_ok $bot->network, 'Freyr::Network';
        is $net->host, 'irc.freenode.net';
    };

    subtest 'network object created' => sub {
        my $bot = Freyr->new(
            network => Freyr::Network->new(
                nick => 'freyr',
                host => 'irc.freenode.net',
            ),
        );
        my $net = $bot->network;
        isa_ok $bot->network, 'Freyr::Network';
        is $net->host, 'irc.freenode.net';
    };

    TODO: {
        local $TODO = "Multinetwork support is upcoming";
        return;
        subtest 'simple connect' => sub {
            my $bot = Freyr->new(
                nick => 'freyr',
            );
            my $net = $bot->network( freenode => 'irc.freenode.net' );
            isa_ok $net, 'Freyr::Network';
            is $net->nick, $bot->nick;
        };

        subtest 'connect options' => sub {
            my $bot = Freyr->new(
                nick => 'freyr',
            );
            my $net = $bot->network( freenode => {
                host => 'irc.freenode.net',
                port => '6667',
                nick => 'freyr_',
            } );
            isa_ok $net, 'Freyr::Network';
            is $net->nick, 'freyr_';
        };

        subtest 'default networks' => sub {
            my $bot = Freyr->new(
                nick => 'freyr',
                networks => {
                    freenode => 'irc.freenode.net',
                    perl => {
                        host => 'irc.perl.org',
                        port => '6667',
                    },
                },
            );

            subtest 'simple connect' => sub {
                my $net = $bot->network( 'freenode' );
                isa_ok $net, 'Freyr::Network';
                is $net->host, 'irc.freenode.net';
            };

            subtest 'connect options' => sub {
                my $net = $bot->network( 'perl' );
                isa_ok $net, 'Freyr::Network';
                is $net->host, 'irc.perl.org';
                is $net->port, '6667';
            };
        };
    };

};

subtest 'join channels' => sub {
    subtest 'single network' => sub {
        subtest 'simple connect' => sub {
            my $bot = Freyr->new(
                nick => 'freyr',
                host => 'irc.freenode.net',
            );
            my $irc = $bot->network->irc;
            like $irc->{to_irc_server}, qr{NICK freyr\r\n};
            like $irc->{to_irc_server}, qr{USER freyr[^\r]+\r\n};

            my $chan = $bot->channel( '#defocus' );
            like $irc->{to_irc_server}, qr{JOIN \#defocus\r\n};
            isa_ok $chan, 'Freyr::Channel';
            is $chan->name, '#defocus';
            isa_ok $chan->network, 'Freyr::Network';
            is $chan->network->host, 'irc.freenode.net';
        };

        subtest 'default channels' => sub {
            my $bot = Freyr->new(
                nick => 'freyr',
                host => 'irc.freenode.net',
                channels => [ '#defocus' ],
            );
            my $irc = $bot->network->irc;
            like $irc->{to_irc_server}, qr{NICK freyr\r\n};
            like $irc->{to_irc_server}, qr{USER freyr[^\r]+\r\n};
            like $irc->{to_irc_server}, qr{JOIN \#defocus\r\n};

            my $chan = $bot->channel( '#defocus' );
            isa_ok $chan, 'Freyr::Channel';
            is $chan->name, '#defocus';
            isa_ok $chan->network, 'Freyr::Network';
            is $chan->network->host, 'irc.freenode.net';
        };
    };

    TODO: {
        local $TODO = "Multinetwork support is upcoming";
        return;
        subtest 'multiple networks' => sub {
            my $bot = Freyr->new(
                nick => 'freyr',
            );
            my $net = $bot->network( 'irc.freenode.net' );
            my $chan = $net->channel( '#defocus' );
            isa_ok $chan, 'Freyr::Channel';
            is $chan->network->host, $net->host;
        };
    };
};

subtest 'message routing' => sub {
    subtest 'bot routes' => sub {
        my $bot;
        my $test_cb_args = sub {
            my ( $msg, %params ) = @_;
            return sub {
                isa_ok $msg, 'Freyr::Message';
                is $msg->bot, $bot;
                if ( $msg->channel ) {
                    is $msg->channel, $bot->channel( '#defocus' );
                }
                is $msg->network, $bot->network;
                is $msg->nick, 'preaction';
                is $msg->hostmask, 'preaction!doug@example.com';
            }
        };

        subtest 'bot routing' => sub {
            subtest 'default prefixes' => sub {
                $bot = Freyr->new(
                    nick => 'freyr',
                    host => 'irc.freenode.net',
                    prefix => '!',
                    channels => [qw( #defocus )],
                );
                my $irc = $bot->network->irc;

                $bot->route( 'greet' => sub {
                    subtest 'cb args' => $test_cb_args->( @_ );
                    my ( $msg, %params ) = @_;
                    return sprintf 'Hello, %s!', $msg->nick;
                } );

                subtest 'prefix character (!)' => test_irc_msg(
                    $irc, ':preaction!doug@example.com PRIVMSG #defocus !greet',
                    like => qr{PRIVMSG \#defocus preaction: Hello, preaction!},
                );

                subtest 'bot nick is a valid prefix' => sub {
                    subtest 'nick: command' => test_irc_msg(
                        $irc, ':preaction!doug@example.com PRIVMSG #defocus freyr: greet',
                        like => qr{PRIVMSG \#defocus preaction: Hello, preaction!},
                    );
                    subtest 'nick, command' => test_irc_msg(
                        $irc, ':preaction!doug@example.com PRIVMSG #defocus freyr, greet',
                        like => qr{PRIVMSG \#defocus preaction: Hello, preaction!},
                    );
                    subtest 'nick command' => test_irc_msg(
                        $irc, ':preaction!doug@example.com PRIVMSG #defocus freyr greet',
                        like => qr{PRIVMSG \#defocus preaction: Hello, preaction!},
                    );
                };

                subtest 'private message is valid prefix' => test_irc_msg(
                    $irc, ':preaction!doug@example.com PRIVMSG freyr greet',
                    like => qr{PRIVMSG preaction Hello, preaction!},
                );

                subtest 'unprefixed message is not responded to' => test_irc_msg(
                    $irc, ':preaction!doug@example.com PRIVMSG #defocus greet',
                    unlike => qr{PRIVMSG \#defocus preaction: Hello, preaction!},
                );

            };

            subtest 'route return values' => sub {
                subtest 'route sends to irc directly' => sub {
                    $bot = Freyr->new(
                        nick => 'freyr',
                        host => 'irc.freenode.net',
                        prefix => '!',
                        channels => [ '#defocus' ],
                    );
                    my $irc = $bot->network->irc;

                    $bot->route->msg( 'say' => sub( $msg, % ) {
                        # write() returns the Mojo::IRC object
                        $msg->network->irc->write(
                            PRIVMSG => $msg->channel->name, $msg->text,
                        );
                    } );

                    subtest 'Mojo::IRC object is not displayed' => test_irc_msg(
                        $irc, ':preaction!doug@example.com PRIVMSG #defocus !say Hello',
                        like => qr{PRIVMSG \#defocus Hello},
                        unlike => qr{Mojo::IRC},
                    );
                };

                subtest 'under errors' => sub {
                    $bot = Freyr->new(
                        nick => 'freyr',
                        host => 'irc.freenode.net',
                        prefix => '!',
                        channels => [ '#defocus' ],
                    );
                    my $irc = $bot->network->irc;

                    $bot->route->under( 'error' => sub {
                        subtest 'cb args' => $test_cb_args->( @_ );
                        die Freyr::Error->new(
                            error => 'My error',
                        );
                    } );

                    subtest 'error message is displayed' => test_irc_msg(
                        $irc, ':preaction!doug@example.com PRIVMSG #defocus !error',
                        like => qr{PRIVMSG preaction ERROR: My error},
                    );
                };

            };
        };
    };
};

subtest 'start/stop' => sub {
    my $bot = Freyr->new(
        nick => 'freyr',
        host => 'irc.freenode.net',
        prefix => '!',
        channels => [ '#defocus' ],
    );
    my $irc = $bot->network->irc;
    $bot->route( quit => sub ( $msg ) {
        pass 'Got quit message';
        $msg->bot->stop;
        return;
    } );
    my $timeout = Mojo::IOLoop->timer( 5, sub { fail "Timeout reached"; shift->stop } );
    Mojo::IOLoop->timer( 0, sub {
        $irc->from_irc_server( ':preaction!doug@example.com PRIVMSG #defocus !quit' . "\r\n" );
    } );
    $irc->{to_irc_server} = '';
    $bot->start;
    Mojo::IOLoop->remove( $timeout );
    ok !$irc->{to_irc_server}, 'nothing returned' or diag $irc->{to_irc_server};
};

done_testing;
