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

    # Return an array of imports/unimports
    return $class->SUPER::modules( $bundles, $args ),
        @modules,
        map { @{ $bundles{ $_ } } } grep { exists $bundles{ $_ } } @$bundles;
}

1;
__END__

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ARGUMENTS

=head1 OPTIONS

=head1 ATTRIBUTES

=head1 METHODS
