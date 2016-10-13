
# Do not connect to live servers during testing
BEGIN { $ENV{ MOJO_IRC_OFFLINE } = 1 };
use Bot::Freyr::Base 'Test';
use Bot::Freyr::Message;
use Bot::Freyr::Network;
use Bot::Freyr::Channel;

my $bot = Bot::Freyr->new(
    server => 'irc.freenode.net:6667',
    nick => 'freyr',
);

my %msg_args = (
    bot => $bot,
    network => $bot->network,
    channel => $bot->network->channel( '#defocus' ),
    to => 'freyr',
    nick => 'preaction',
    hostmask => 'preaction!doug@example.com',
    text => 'This was the text',
    raw => 'This was the raw text',
);

subtest 'clone' => sub {
    my $msg = Bot::Freyr::Message->new( %msg_args );

    subtest 'plain clone' => sub {
        cmp_deeply $msg->clone, Bot::Freyr::Message->new( %msg_args );
    };

    subtest 'clone with overrides' => sub {
        cmp_deeply $msg->clone( text => 'Changed text' ),
            Bot::Freyr::Message->new( %msg_args, text => 'Changed text' );
    };
};

done_testing;
