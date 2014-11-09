package Freyr::Plugin;
# ABSTRACT: Base class for Freyr plugins

use Freyr::Base 'Class';

=method register( ROUTE )

Register this plugin with the given L<Freyr::Route|route>. This method should
set up routes and unders.

=cut

sub register( $self, $route ) { ... }

1;

=head1 SYNOPSIS

    package My::Plugin;
    use Freyr 'Class';
    extends 'Freyr::Plugin';
    sub register( $self, $route ) {
        $route->msg( ... );
        $route->under( ... );
    }

    package main;
    my $bot = Freyr->new(
        plugins => {
            my_plugin => My::Plugin->new,
        },
    );

=head1 DESCRIPTION

A plugin is a set of reusable, configurable behaviors.
