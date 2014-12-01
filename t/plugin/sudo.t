
# Do not connect to live servers during testing
BEGIN { $ENV{ MOJO_IRC_OFFLINE } = 1 };
use Bot::Freyr::Base 'Test';
use Bot::Freyr::Plugin::Sudo;
use Bot::Freyr::Plugin::Say;

my $say = Bot::Freyr::Plugin::Say->new;
my $sudo = Bot::Freyr::Plugin::Sudo->new(
    users => {
        preaction => [
            'preaction!doug@*',
            '*!doug@*example.com',
            'preaction!*@*.me',
        ],
    },
    plugins => {
        say => $say,
        quit => sub( $msg ) {
            $msg->bot->stop;
            return;
        },
    },
);
my $bot = Bot::Freyr->new(
    nick => 'freyr',
    prefix => '!',
    host => 'irc.freenode.net',
    channels => [ '#defocus' ],
    plugins => {
        sudo => $sudo,
    },
);
my $irc = $bot->network->irc;

subtest 'auth by nick!user@host' => sub {
    subtest 'nick!user@*' => sub {
        subtest 'auth success' => test_irc_msg(
            $irc, ':preaction!doug@example.net PRIVMSG #defocus !sudo say Hello',
            like => qr{PRIVMSG \#defocus Hello},
            unlike => qr{PRIVMSG preaction ERROR: You are not authorized to perform this command},
        );

        subtest 'auth failure' => test_irc_msg(
            $irc, ':preaction!joel@example.net PRIVMSG #defocus !sudo say Hello',
            unlike => qr{PRIVMSG \#defocus Hello},
            like => qr{PRIVMSG preaction ERROR: You are not authorized to perform this command},
        );
    };

    subtest '*!user@host' => sub {
        subtest 'auth success' => test_irc_msg(
            $irc, ':unknown!doug@example.com PRIVMSG #defocus !sudo say Hello',
            like => qr{PRIVMSG \#defocus Hello},
            unlike => qr{PRIVMSG unknown ERROR: You are not authorized to perform this command},
        );

        subtest 'auth failure' => test_irc_msg(
            $irc, ':unknown!joel@example.com PRIVMSG #defocus !sudo say Hello',
            unlike => qr{PRIVMSG \#defocus Hello},
            like => qr{PRIVMSG unknown ERROR: You are not authorized to perform this command},
        );
    };

    subtest '*!user@*host' => sub {
        subtest 'auth success' => test_irc_msg(
            $irc, ':unknown!doug@irc.example.com PRIVMSG #defocus !sudo say Hello',
            like => qr{PRIVMSG \#defocus Hello},
            unlike => qr{PRIVMSG unknown ERROR: You are not authorized to perform this command},
        );

        subtest 'auth failure' => test_irc_msg(
            $irc, ':unknown!joel@irc.example.com PRIVMSG #defocus !sudo say Hello',
            unlike => qr{PRIVMSG \#defocus Hello},
            like => qr{PRIVMSG unknown ERROR: You are not authorized to perform this command},
        );
    };

    subtest 'nick!*@*.host' => sub {
        subtest 'auth success' => test_irc_msg(
            $irc, ':preaction!root@preaction.me PRIVMSG #defocus !sudo say Hello',
            like => qr{PRIVMSG \#defocus Hello},
            unlike => qr{PRIVMSG preaction ERROR: You are not authorized to perform this command},
        );

        subtest 'auth failure' => test_irc_msg(
            $irc, ':unknown!root@preaction.me PRIVMSG #defocus !sudo say Hello',
            unlike => qr{PRIVMSG \#defocus Hello},
            like => qr{PRIVMSG unknown ERROR: You are not authorized to perform this command},
        );
    };

};

done_testing;
