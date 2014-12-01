package Bot::Freyr::Plugin;
# ABSTRACT: Base class for Bot::Freyr plugins

use Bot::Freyr::Base 'Class';

=method register( ROUTE )

Register this plugin with the given L<Bot::Freyr::Route|route>. This method should
set up routes and unders.

=cut

sub register( $self, $route ) { ... }

1;

=head1 SYNOPSIS

    package My::Plugin;
    use Bot::Freyr 'Class';
    extends 'Bot::Freyr::Plugin';
    sub register( $self, $route ) {
        $route->msg( ... );
        $route->under( ... );
    }

    package main;
    my $bot = Bot::Freyr->new(
        plugins => {
            my_plugin => My::Plugin->new,
        },
    );

=head1 DESCRIPTION

A plugin is a set of reusable, configurable behaviors.
