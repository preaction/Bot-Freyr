package Freyr::Plugin::Ignore;
# ABSTRACT: Make the bot ignore people

use Freyr::Base 'Plugin';
use Freyr::Util qw( mask_match );
use DBM::Deep;

=attr database

A path to a file to be used as a database for ignore strings.

=cut

has database => (
    is => 'ro',
    isa => Path,
    default => sub { path( 'ignore.db' ) },
);

=attr _db

The database of masks to ignore.

=cut

has _db => (
    is => 'ro',
    isa => InstanceOf['DBM::Deep'],
    lazy => 1,
    default => sub ( $self ) {
        return DBM::Deep->new( $self->database->stringify );
    },
);

sub register( $self, $route ) {
    $route->root->on( before_dispatch => $self->curry::weak::check_ignore );
    $route->msg( $self->curry::weak::ignore );
}

sub check_ignore( $self, $event ) {
    for my $match ( $self->_db->{masks}->@* ) {
        $event->stop if mask_match( $event->message->hostmask, $match );
    }
}

sub ignore( $self, $msg ) {
    push $self->_db->{masks}->@*, $msg->text;
    return "Ignoring " . $msg->text;
}

1;

=head1 SYNOPSIS

    use Freyr;
    use Freyr::Plugin::Ignore;

    my $plugin = Freyr::Plugin::Ignore->new;

    # Create a bot with our plugin
    my $bot = Freyr->new(
        nick => 'freyr',
        prefix => '!',
        host => 'irc.freenode.net',
        channels => [ '#freyr' ],
        plugins => {
            ignore => $plugin,
        },
    );
    $bot->start;

=head1 DESCRIPTION

This plugin allows ignoring people who are annoying the bot

=head1 COMMANDS

=head2 ignore <match>

    ignore nick!*
    ignore *@host
    ignore nick!user@host

Ignore the given hostmask. C<*> may be used as a wildcard character.
