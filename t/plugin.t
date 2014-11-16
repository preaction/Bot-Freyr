
# Do not connect to live servers during testing
BEGIN { $ENV{ MOJO_IRC_OFFLINE } = 1 };
use Freyr::Base 'Test';

{
    package Test::Freyr::Plugin;
    use Freyr::Base 'Plugin';

    sub register( $self, $r ) {
        $r->msg( sub {
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

    subtest 'prefixed message is responded to' => test_irc_msg(
        $irc, ':preaction!doug@example.com PRIVMSG #defocus !greet',
        like => qr{PRIVMSG \#defocus preaction: Hello, preaction!},
    );
    subtest 'private message is valid prefix' => test_irc_msg(
        $irc, ':preaction!doug@example.com PRIVMSG freyr greet',
        like => qr{PRIVMSG preaction Hello, preaction!},
    );
    subtest 'unprefixed message is not responded to' => test_irc_msg(
        $irc, ':preaction!doug@example.com PRIVMSG #defocus greet',
        unlike => qr{PRIVMSG \#defocus preaction: Hello, preaction!},
    );
};

done_testing;
