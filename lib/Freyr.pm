package Freyr;
# ABSTRACT: IRC bot with multi-network and web API

use strict;
use warnings;
use parent 'Import::Base';

sub modules {
    my ( $class, $bundles, $args ) = @_;

    # Modules that are always imported
    my @modules = (
        'strict',
        'warnings',
        'feature' => [qw( :5.20 )],
        'experimental' => [qw( signatures postderef )],
    );

    # Optional bundles
    my %bundles = (
        Test => [qw( Test::More Test::Deep Test::Differences )],
    );

    if ( grep { $_ eq 'Test' } @$bundles ) {
        # Do not connect to live servers during testing
        $ENV{ MOJO_IRC_OFFLINE } = 1;
    }

    # Return an array of imports/unimports
    return $class->SUPER::modules( $bundles, $args ),
        @modules,
        map { @{ $bundles{ $_ } } } grep { exists $bundles{ $_ } } @$bundles;
}

1;
__END__

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

Freyr is an IRC bot designed for multiple networks and a web interface.
