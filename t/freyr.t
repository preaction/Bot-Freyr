
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

subtest 'join channels' => sub {
    subtest 'single network' => sub {
        subtest 'simple connect' => sub {
            my $bot = Freyr->new(
                nick => 'freyr',
                host => 'irc.freenode.net',
            );
            my $chan = $bot->channel( '#defocus' );
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
            my $chan = $bot->channel( '#defocus' );
            isa_ok $chan, 'Freyr::Channel';
            is $chan->name, '#defocus';
            isa_ok $chan->network, 'Freyr::Network';
            is $chan->network->host, 'irc.freenode.net';
        };
    };
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

subtest 'message routing' => sub {
    subtest 'bot routes' => sub {
        my $bot = Freyr->new(
            nick => 'freyr',
            host => 'irc.freenode.net',
            prefix => '!',
        );
        my $test_cb_args = sub {
            return sub {
                my ( $msg ) = @_;
                isa_ok $msg, 'Freyr::Message';
                is $msg->bot, $bot;
                is $msg->channel, $bot->channel( '#defocus' );
                is $msg->network, $bot->network;
                is $msg->nick, 'preaction';
            }
        };
        my $irc = $bot->network->irc;
        subtest 'route matching' => sub {
            subtest 'default is prefixed' => sub {
                $bot->route( 'greet' => sub {
                    subtest 'cb args' => $test_cb_args->( @_ );
                    my ( $msg ) = @_;
                    return sprintf 'Hello, %s!', $msg->nick;
                } );
                subtest 'prefixed message is responded to' => sub {
                    $irc->from_irc_server( ':preaction PRIVMSG #defocus !greet' );
                    like $irc->{to_irc_server}, qr{PRIVMSG \#defocus Hello, preaction!};
                };
                subtest 'bot nick is a valid prefix' => sub {
                    subtest 'nick: command' => sub {
                        $irc->from_irc_server( ':preaction PRIVMSG #defocus freyr: greet' );
                        like $irc->{to_irc_server}, qr{PRIVMSG \#defocus Hello, preaction!};
                    };
                    subtest 'nick, command' => sub {
                        $irc->from_irc_server( ':preaction PRIVMSG #defocus freyr, greet' );
                        like $irc->{to_irc_server}, qr{PRIVMSG \#defocus Hello, preaction!};
                    };
                    subtest 'nick command' => sub {
                        $irc->from_irc_server( ':preaction PRIVMSG #defocus freyr greet' );
                        like $irc->{to_irc_server}, qr{PRIVMSG \#defocus Hello, preaction!};
                    };
                };
                subtest 'private message is valid prefix' => sub {
                    $irc->from_irc_server( ':preaction PRIVMSG freyr greet' );
                    like $irc->{to_irc_server}, qr{PRIVMSG preaction Hello, preaction!};
                };
                subtest 'unprefixed message is not responded to' => sub {
                    $irc->from_irc_server( ':preaction PRIVMSG #defocus greet' );
                    unlike $irc->{to_irc_server}, qr{PRIVMSG \#defocus Hello, preaction!};
                };
            };

            subtest 'unprefixed routes' => sub {
                $bot->route( '/greet' => sub {
                    subtest 'cb args' => $test_cb_args->( @_ );
                    my ( $msg ) = @_;
                    return sprintf 'Hello, %s!', $msg->nick;
                } );
                subtest 'unprefixed message is responded to' => sub {
                    $irc->from_irc_server( ':preaction PRIVMSG #defocus greet' );
                    like $irc->{to_irc_server}, qr{PRIVMSG \#defocus Hello, preaction!};
                };
                subtest 'prefixed message is not responded to' => sub {
                    $irc->from_irc_server( ':preaction PRIVMSG #defocus !greet' );
                    unlike $irc->{to_irc_server}, qr{PRIVMSG \#defocus Hello, preaction!};
                };
                subtest 'private message is not responded to' => sub {
                    $irc->from_irc_server( ':preaction PRIVMSG freyr greet' );
                    unlike $irc->{to_irc_server}, qr{PRIVMSG preaction Hello, preaction!};
                };
            };

            subtest 'placeholders' => sub {
                $bot->route( 'greet :who' => sub {
                    subtest 'cb args' => $test_cb_args->( @_ );
                    my ( $msg, $who ) = @_;
                    $who //= $msg->nick;
                    return sprintf 'Hello, %s!', $who;
                } );
                subtest 'prefixed message with placeholder content' => sub {
                    $irc->from_irc_server( ':preaction PRIVMSG #defocus !greet Perl' );
                    like $irc->{to_irc_server}, qr{PRIVMSG \#defocus Hello, Perl!};
                };
                subtest 'prefixed message with default content' => sub {
                    $irc->from_irc_server( ':preaction PRIVMSG #defocus !greet' );
                    like $irc->{to_irc_server}, qr{PRIVMSG \#defocus Hello, preaction!};
                };
                subtest 'unprefixed message is not responded to' => sub {
                    $irc->from_irc_server( ':preaction PRIVMSG #defocus greet Perl' );
                    unlike $irc->{to_irc_server}, qr{PRIVMSG \#defocus Hello, Perl!};
                };
            };
        };
        subtest 'under() routes' => sub {
            subtest 'prefixed messages' => sub {
                my $seen = 0;
                $bot->under( '' => sub {
                    subtest 'cb args' => $test_cb_args->( @_ );
                    my ( $msg ) = @_;
                    $seen++;
                    return;
                } );
                $irc->from_irc_server( ':preaction PRIVMSG #defocus !greet' );
                ok !$irc->{to_irc_server}, 'no response to prefixed message';
                $irc->from_irc_server( ':preaction PRIVMSG #defocus greet' );
                ok !$irc->{to_irc_server}, 'no response to unprefixed message';
                $irc->from_irc_server( ':preaction PRIVMSG freyr greet' );
                ok !$irc->{to_irc_server}, 'no response to private message';
                is $seen, 2, 'prefixed messages are seen';
            };
            subtest 'all messages' => sub {
                my $seen = 0;
                $bot->under( '/' => sub {
                    subtest 'cb args' => $test_cb_args->( @_ );
                    my ( $msg ) = @_;
                    $seen++;
                    return;
                } );
                $irc->from_irc_server( ':preaction PRIVMSG #defocus !greet' );
                ok !$irc->{to_irc_server}, 'no response to prefixed message';
                $irc->from_irc_server( ':preaction PRIVMSG #defocus greet' );
                ok !$irc->{to_irc_server}, 'no response to unprefixed message';
                $irc->from_irc_server( ':preaction PRIVMSG freyr greet' );
                ok !$irc->{to_irc_server}, 'no response to private message';
                is $seen, 3, 'all messages are seen';
            };
        };
    };
};

done_testing;
