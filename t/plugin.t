
# Do not connect to live servers during testing
BEGIN { $ENV{ MOJO_IRC_OFFLINE } = 1 };
use Freyr::Base 'Test';

{
    package Test::Freyr::Plugin;
    use Freyr::Base 'Class';
    extends 'Freyr::Plugin';

    sub register {
        my ( $self, $bot ) = @_;
        $bot->route( 'greet' => sub {
            my ( $msg, %params ) = @_;
            return sprintf 'Hello, %s!', $msg->nick;
        } );
    }
}

subtest 'basic plugin' => sub {
    my ( $bot, $plugin );

    my $test_cb_args = sub {
        my ( $self, $msg, %params ) = @_;
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

    $plugin = Test::Freyr::Plugin->new;
    $bot = Freyr->new(
        nick => 'freyr',
        prefix => '!',
        host => 'irc.freenode.net',
        channels => [ '#defocus' ],
        plugins => {
            greet => $plugin,
        },
    );
    my $irc = $bot->network->irc;

    subtest 'prefixed message is responded to' => $test_msg->(
        $irc, ':preaction!doug@example.com PRIVMSG #defocus !greet',
        like => qr{PRIVMSG \#defocus preaction: Hello, preaction!},
    );
    subtest 'private message is valid prefix' => $test_msg->(
        $irc, ':preaction!doug@example.com PRIVMSG freyr greet',
        like => qr{PRIVMSG preaction Hello, preaction!},
    );
    subtest 'unprefixed message is not responded to' => $test_msg->(
        $irc, ':preaction!doug@example.com PRIVMSG #defocus greet',
        unlike => qr{PRIVMSG \#defocus preaction: Hello, preaction!},
    );
};

done_testing;
