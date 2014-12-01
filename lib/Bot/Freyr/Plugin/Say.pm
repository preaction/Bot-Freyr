package Bot::Freyr::Plugin::Say;
# ABSTRACT: Make the bot talk

use Bot::Freyr::Base 'Plugin';
use Getopt::Long qw( GetOptionsFromString );

sub register( $self, $route ) {
    $route->msg( $self->curry::weak::speak );
}

sub speak( $self, $msg ) {
    my %opt = (
        to => $msg->channel ? $msg->channel->name : $msg->nick,
    );
    my ( $ret, $words ) = GetOptionsFromString( $msg->text, \%opt,
        'to|t=s',
    );
    $msg->network->irc->write( PRIVMSG => $opt{to}, @$words );
}

1;

=head1 SYNOPSIS

    use Bot::Freyr;
    use Bot::Freyr::Plugin::Say;

    my $plugin = Bot::Freyr::Plugin::Say->new;

    # Create a bot with our plugin
    my $bot = Bot::Freyr->new(
        nick => 'freyr',
        prefix => '!',
        host => 'irc.freenode.net',
        channels => [ '#freyr' ],
        plugins => {
            say => $plugin,
        },
    );
    Mojo::IOLoop->start;

=head1 DESCRIPTION

This plugin simply parrots anything said to it

=head1 COMMANDS

=head2 say [-t|--to <user|channel>] text

    say Hello
    say -t #freyr Hello
    say -t preaction Hello

Say the given C<text> to the given C<user> or C<channel>. By default, will send the text
back to the same place the command was given (to the channel, or to the user in private
message).

