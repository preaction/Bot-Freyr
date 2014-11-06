package Freyr::Plugin;
# ABSTRACT: Base class for Freyr plugins

use Freyr::Base 'Class';

=method register( bot )

Register this plugin with the bot. This method should set up routes and unders.

=cut

sub register( $self, $bot ) { ... }

1;

=head1 SYNOPSIS

    package My::Plugin;
    use Freyr 'Class';
    extends 'Freyr::Plugin';

    sub register( $self, $bot ) {
        $bot->route( ... );
        $bot->under( ... );
    }

    package main;
    my $bot = Freyr->new(
        plugins => {
            my_plugin => My::Plugin->new,
        },
    );

=head1 DESCRIPTION

A plugin is a set of reusable, configurable behaviors.
