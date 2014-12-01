
# Do not connect to live servers during testing
BEGIN { $ENV{ MOJO_IRC_OFFLINE } = 1 };
use Bot::Freyr::Base 'Test';
use Path::Tiny qw( tempfile );
use Bot::Freyr::Plugin::Ignore;

sub test_ignore {
    my ( $mask, $match ) = @_;
    my ( $nick ) = $mask =~ /^([^!]+)!/;

    return sub {

        my $ignore = Bot::Freyr::Plugin::Ignore->new(
            database => tempfile(),
        );

        my $bot = Bot::Freyr->new(
            nick => 'freyr',
            prefix => '!',
            host => 'irc.freenode.net',
            channels => [ '#defocus' ],
            plugins => {
                ignore => $ignore,
            },
        );
        $bot->route->msg( say => sub { "Hey!" } );

        my $irc = $bot->network->irc;

        subtest 'add ignore mask' => test_irc_msg(
            $irc, ':preaction!doug@example.com PRIVMSG #defocus !ignore ' . $match,
            like => qr{PRIVMSG \#defocus preaction: Ignoring \Q$match},
        );

        subtest 'say to channel' => test_irc_msg(
            $irc, ':preaction!doug@example.com PRIVMSG #defocus !say',
            like => qr{PRIVMSG \#defocus preaction: Hey!},
        );

        subtest 'user is ignored' => test_irc_msg(
            $irc, ':' . $mask . ' PRIVMSG #defocus !say',
            unlike => qr{PRIVMSG \#defocus $nick: Hey!},
        );

    };
}

subtest 'ignore: nick!*@*' => test_ignore( 'nick!user@host.com' => 'nick!*@*' );
subtest 'ignore: *!user@*' => test_ignore( 'nick!user@host.com' => '*!user@*' );
subtest 'ignore: *@host.com' => test_ignore( 'nick!user@host.com' => '*@host.com' );

done_testing;
