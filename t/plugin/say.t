
# Do not connect to live servers during testing
BEGIN { $ENV{ MOJO_IRC_OFFLINE } = 1 };
use Freyr::Base 'Test';
use Freyr::Plugin::Say;

my $say = Freyr::Plugin::Say->new(

);
my $bot = Freyr->new(
    nick => 'freyr',
    prefix => '!',
    host => 'irc.freenode.net',
    channels => [ '#defocus' ],
    plugins => {
        say => $say,
    },
);
my $irc = $bot->network->irc;

subtest 'say command' => test_irc_msg(
    $irc, ':preaction!doug@example.com PRIVMSG #defocus !say Hello World!',
    like => qr{PRIVMSG \#defocus Hello World!},
);

subtest 'say to channel' => test_irc_msg(
    $irc, ':preaction!doug@example.com PRIVMSG freyr say -t #defocus Hello World!',
    like => qr{PRIVMSG \#defocus Hello World!},
);

subtest 'say to user' => test_irc_msg(
    $irc, ':preaction!doug@example.com PRIVMSG #defocus !say --to preaction Hello World!',
    like => qr{PRIVMSG preaction Hello World!},
);

done_testing;
