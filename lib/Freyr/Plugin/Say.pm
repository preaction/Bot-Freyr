package Freyr::Plugin::Say;
# ABSTRACT: Make the bot talk

use Freyr::Base 'Plugin';
use Getopt::Long qw( GetOptionsFromString );

sub register( $self, $bot ) {
    $bot->route( 'say' => $self->curry::weak::speak );
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
