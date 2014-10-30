
# Do not connect to live servers during testing
BEGIN { $ENV{ MOJO_IRC_OFFLINE } = 1 };
use Freyr::Base 'Test';

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
            like $irc->{to_irc_server}, qr{NICK freyr};
            like $irc->{to_irc_server}, qr{USER freyr};
            my $chan = $bot->channel( '#defocus' );
            like $irc->{to_irc_server}, qr{JOIN \#defocus};
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
            like $irc->{to_irc_server}, qr{NICK freyr};
            like $irc->{to_irc_server}, qr{USER freyr};
            like $irc->{to_irc_server}, qr{JOIN \#defocus};
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
            }
        };
        my $test_msg = sub( $irc, $send, $test, $recv ) {
            return sub {
                $irc->{to_irc_server} = '';
                $irc->from_irc_server( $send . "\r\n" );
                if ( $test eq 'like' ) {
                    like $irc->{to_irc_server}, qr{$recv\r\n};
                }
                elsif ( $test eq 'unlike' ) {
                    unlike $irc->{to_irc_server}, qr{$recv\r\n};
                }
                $irc->{to_irc_server} = '';
            }
        };

        subtest 'route matching' => sub {
            subtest 'default is prefixed' => sub {
                $bot = Freyr->new(
                    nick => 'freyr',
                    host => 'irc.freenode.net',
                    prefix => '!',
                );
                my $irc = $bot->network->irc;
                $bot->route( 'greet' => sub {
                    subtest 'cb args' => $test_cb_args->( @_ );
                    my ( $msg, %params ) = @_;
                    return sprintf 'Hello, %s!', $msg->nick;
                } );
                subtest 'prefixed message is responded to' => $test_msg->(
                    $irc, ':preaction!doug@example.com PRIVMSG #defocus !greet',
                    like => qr{PRIVMSG \#defocus preaction: Hello, preaction!},
                );
                subtest 'bot nick is a valid prefix' => sub {
                    subtest 'nick: command' => $test_msg->(
                        $irc, ':preaction!doug@example.com PRIVMSG #defocus freyr: greet',
                        like => qr{PRIVMSG \#defocus preaction: Hello, preaction!},
                    );
                    subtest 'nick, command' => $test_msg->(
                        $irc, ':preaction!doug@example.com PRIVMSG #defocus freyr, greet',
                        like => qr{PRIVMSG \#defocus preaction: Hello, preaction!},
                    );
                    subtest 'nick command' => $test_msg->(
                        $irc, ':preaction!doug@example.com PRIVMSG #defocus freyr greet',
                        like => qr{PRIVMSG \#defocus preaction: Hello, preaction!},
                    );
                };
                subtest 'private message is valid prefix' => $test_msg->(
                    $irc, ':preaction!doug@example.com PRIVMSG freyr greet',
                    like => qr{PRIVMSG preaction Hello, preaction!},
                );
                subtest 'unprefixed message is not responded to' => $test_msg->(
                    $irc, ':preaction!doug@example.com PRIVMSG #defocus greet',
                    unlike => qr{PRIVMSG \#defocus preaction: Hello, preaction!},
                );
            };

            subtest 'unprefixed routes' => sub {
                $bot = Freyr->new(
                    nick => 'freyr',
                    host => 'irc.freenode.net',
                    prefix => '!',
                );
                my $irc = $bot->network->irc;
                $bot->route( '/greet' => sub {
                    subtest 'cb args' => $test_cb_args->( @_ );
                    my ( $msg ) = @_;
                    return sprintf 'Hello, %s!', $msg->nick;
                } );
                subtest 'unprefixed message is responded to' => $test_msg->(
                    $irc, ':preaction!doug@example.com PRIVMSG #defocus greet',
                    like => qr{PRIVMSG \#defocus preaction: Hello, preaction!},
                );
                subtest 'prefixed message is not responded to' => $test_msg->(
                    $irc, ':preaction!doug@example.com PRIVMSG #defocus !greet',
                    unlike => qr{PRIVMSG \#defocus preaction: Hello, preaction!},
                );
                subtest 'private message is not responded to' => $test_msg->(
                    $irc, ':preaction!doug@example.com PRIVMSG freyr greet',
                    unlike => qr{PRIVMSG preaction Hello, preaction!},
                );
                subtest 'unprefixed route that matches our prefix' => sub {
                    $bot->route( '/!bonjour' => sub {
                        subtest 'cb args' => $test_cb_args->( @_ );
                        my ( $msg ) = @_;
                        return sprintf 'Freyr, %s!', $msg->nick;
                    } );
                    subtest 'unprefixed route with our prefix char matches' => $test_msg->(
                        $irc, ':preaction!doug@example.com PRIVMSG #defocus !bonjour',
                        like => qr{PRIVMSG \#defocus preaction: Freyr, preaction!},
                    );
                    $bot->route( '/freyr,' => sub {
                        subtest 'cb args' => $test_cb_args->( @_ );
                        my ( $msg ) = @_;
                        return sprintf 'Freyr, hello %s!', $msg->nick;
                    } );
                    subtest 'unprefixed route with our name matches' => $test_msg->(
                        $irc, ':preaction!doug@example.com PRIVMSG #defocus freyr, hello',
                        like => qr{PRIVMSG \#defocus preaction: Freyr, hello preaction!},
                    );
                };
            };

            subtest 'placeholders' => sub {
                $bot = Freyr->new(
                    nick => 'freyr',
                    host => 'irc.freenode.net',
                    prefix => '!',
                );
                my $irc = $bot->network->irc;
                $bot->route( 'greet :who' => sub {
                    subtest 'cb args' => $test_cb_args->( @_ );
                    my ( $msg, $who ) = @_;
                    $who //= $msg->nick;
                    return sprintf 'Hello, %s!', $who;
                } );
                subtest 'prefixed message with placeholder content' => $test_msg->(
                    $irc, ':preaction!doug@example.com PRIVMSG #defocus !greet Perl',
                    like => qr{PRIVMSG \#defocus preaction: Hello, Perl!},
                );
                subtest 'prefixed message with default content' => $test_msg->(
                    $irc, ':preaction!doug@example.com PRIVMSG #defocus !greet',
                    like => qr{PRIVMSG \#defocus preaction: Hello, preaction!},
                );
                subtest 'unprefixed message is not responded to' => $test_msg->(
                    $irc, ':preaction!doug@example.com PRIVMSG #defocus greet Perl',
                    unlike => qr{PRIVMSG \#defocus preaction: Hello, Perl!},
                );
            };
        };
        subtest 'under() routes' => sub {
            subtest 'prefixed messages' => sub {
                $bot = Freyr->new(
                    nick => 'freyr',
                    host => 'irc.freenode.net',
                    prefix => '!',
                );
                my $irc = $bot->network->irc;
                my $seen = 0;
                $bot->under( '' => sub {
                    subtest 'cb args' => $test_cb_args->( @_ );
                    my ( $msg ) = @_;
                    $seen++;
                    return;
                } );
                $irc->from_irc_server( ':preaction!doug@example.com PRIVMSG #defocus !greet' );
                ok !$irc->{to_irc_server}, 'no response to prefixed message';
                $irc->from_irc_server( ':preaction!doug@example.com PRIVMSG #defocus greet' );
                ok !$irc->{to_irc_server}, 'no response to unprefixed message';
                $irc->from_irc_server( ':preaction!doug@example.com PRIVMSG freyr greet' );
                ok !$irc->{to_irc_server}, 'no response to private message';
                is $seen, 2, 'prefixed messages are seen';
            };
            subtest 'all messages' => sub {
                $bot = Freyr->new(
                    nick => 'freyr',
                    host => 'irc.freenode.net',
                    prefix => '!',
                );
                my $irc = $bot->network->irc;
                my $seen = 0;
                $bot->under( '/' => sub {
                    subtest 'cb args' => $test_cb_args->( @_ );
                    my ( $msg ) = @_;
                    $seen++;
                    return;
                } );
                $irc->from_irc_server( ':preaction!doug@example.com PRIVMSG #defocus !greet' );
                ok !$irc->{to_irc_server}, 'no response to prefixed message';
                $irc->from_irc_server( ':preaction!doug@example.com PRIVMSG #defocus greet' );
                ok !$irc->{to_irc_server}, 'no response to unprefixed message';
                $irc->from_irc_server( ':preaction!doug@example.com PRIVMSG freyr greet' );
                ok !$irc->{to_irc_server}, 'no response to private message';
                is $seen, 3, 'all messages are seen';
            };
        };
    };
};

done_testing;
