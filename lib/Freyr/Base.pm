package Freyr::Base;
# ABSTRACT: Base bundles for Freyr IRC bot

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
        'Freyr',
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

    package MyModule;
    use Freyr::Base;

    # Classes
    use Freyr::Base 'Class';

    # Tests
    use Freyr::Base 'Test';

=head1 DESCRIPTION

This is the base module that all Freyr files should use.

This module always imports the following into your namespace:

=over

=item L<Freyr>

The base module is imported to make sure that L<File::Share> can find the right
share directory.

=item L<strict>

=item L<warnings>

=item L<feature>

Currently the 5.20 feature bundle

=item L<experimental> 'signatures' 'postderef'

We are using the 5.20 experimental signatures and postfix deref syntax.

=back

=head1 SEE ALSO

=over

=item L<Import::Base>

=back
