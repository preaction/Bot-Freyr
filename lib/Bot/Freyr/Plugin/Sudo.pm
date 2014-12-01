package Bot::Freyr::Plugin::Sudo;
# ABSTRACT: A plugin for authenticating and authorizing other plugins

use Bot::Freyr::Base 'Plugin';
use Scalar::Util qw( blessed );
use Bot::Freyr::Util qw( mask_match );
use Bot::Freyr::Error;

=attr users

A hash of 'user' => MASKS. If an incoming message matches one of the MASKS,
they are authenticated.

=cut

has users => (
    is => 'ro',
    isa => HashRef[ArrayRef[Str]],
    default => sub { {} },
);

=attr plugins

The plugins to authorize. Anyone authenticated by this plugin is authorized to
use these plugins.

=cut

has plugins => (
    is => 'ro',
    isa => HashRef[CodeRef|InstanceOf['Bot::Freyr::Plugin']],
    default => sub { {} },
);

=method register

Register this plugin and all its plugins with the bot.

=cut

sub register( $self, $route ) {
    for my $plugin_route ( keys $self->plugins->%* ) {
        my $plugin = $self->plugins->{ $plugin_route };
        if ( ref $plugin eq 'CODE' ) {
            $route->msg( $plugin_route => $plugin );
        }
        elsif ( blessed $plugin && $plugin->isa( 'Bot::Freyr::Plugin' ) ) {
            my $r = $route->under( $plugin_route, $self->curry::weak::authorize );
            $plugin->register( $r );
        }
    }
}

=method authorize( MESSAGE )

Authorize the given message.

=cut

sub authorize( $self, $msg ) {
    for my $user ( keys $self->users->%* ) {
        for my $match ( $self->users->{ $user }->@* ) {
            return 1 if mask_match( $msg->hostmask, $match );
        }
    }

    die Bot::Freyr::Error->new(
        error => 'You are not authorized to perform this command',
        message => $msg,
    );
}

1;

=head1 SYNOPSIS

    use Bot::Freyr;
    use Bot::Freyr::Plugin::Say;
    use Bot::Freyr::Plugin::Sudo;

    my $sudo = Bot::Freyr::Plugin::Sudo->new(
        users => {
            preaction => [
                'preaction!doug@example.com',
            ],
        },
        plugins => {
            say => Bot::Freyr::Plugin::Say->new,
        },
    );

    my $bot = Bot::Freyr->new(
        host => 'irc.freenode.net',
        prefix => '!',
        channels => [ '#freyr' ],
        plugins => {
            sudo => $sudo,
        },
    );
    $bot->start;

=head1 DESCRIPTION

This plugin allows other plugins to be restricted to authenticated users.

Currently, only simple nick!user@host masks are supported.

