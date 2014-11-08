package Freyr::Plugin::Say;
# ABSTRACT: Make the bot talk

use Freyr::Base 'Plugin';
use Getopt::Long qw( GetOptionsFromString );

sub register {
    my ( $self, $bot ) = @_;
    $bot->route( 'say' => $self->curry::weak::speak );
}

sub speak {
    my ( $self, $msg ) = @_;
    my %opt = (
        to => $msg->channel ? $msg->channel->name : $msg->nick,
    );
    my ( $ret, $words ) = GetOptionsFromString( $msg->text, \%opt,
        'to|t=s',
    );
    $msg->network->irc->write( PRIVMSG => $opt{to}, @$words );
    return;
}

1;
