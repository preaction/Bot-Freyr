
# Do not connect to live servers during testing
BEGIN { $ENV{ MOJO_IRC_OFFLINE } = 1 };
use Freyr::Base 'Test';
use Freyr::Message;
use Freyr::Network;
use Freyr::Channel;

my $bot = Freyr->new(
    host => 'irc.freenode.net',
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
    my $msg = Freyr::Message->new( %msg_args );

    subtest 'plain clone' => sub {
        cmp_deeply $msg->clone, Freyr::Message->new( %msg_args );
    };

    subtest 'clone with overrides' => sub {
        cmp_deeply $msg->clone( text => 'Changed text' ),
            Freyr::Message->new( %msg_args, text => 'Changed text' );
    };
};

done_testing;
