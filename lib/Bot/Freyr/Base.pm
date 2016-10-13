package Bot::Freyr::Base;
our $VERSION = '0.001';
# ABSTRACT: Base bundles for Bot::Freyr IRC bot

use strict;
use warnings;
use parent 'Import::Base';

# Modules that are always imported
our @IMPORT_MODULES = (
    'strict',
    'warnings',
    'feature' => [qw( :5.20 )],
    'curry', 'curry::weak',
    '>experimental' => [qw( signatures postderef lexical_subs )],
    'Bot::Freyr',
    'Path::Tiny' => [qw( path )],
    'Mojo::Log',
);

# Optional bundles
my @class_common = (
    'Types::Standard' => [qw( :all )],
    'Types::Path::Tiny' => [qw( Path )],
);

our %IMPORT_BUNDLES = (
    Test => [
        qw( Test::More Test::Deep Test::Differences Test::Exception ),
        'Test::Mojo::IRC',
        'Bot::Freyr::Test' => [qw( test_irc_msg )],
    ],
    Class => [
        '<Moo',
        @class_common,
    ],
    Role => [
        '<Moo::Role',
        @class_common,
    ],
    Plugin => [
        '<Moo',
        @class_common,
        sub {
            my ( $bundles, $args ) = @_;
            no strict 'refs';
            require Bot::Freyr::Plugin;
            push @{ $args->{package} . "::ISA" }, 'Bot::Freyr::Plugin';
            return;
        },
    ],
);

1;
__END__

=head1 SYNOPSIS

    package MyModule;
    use Bot::Freyr::Base;

    use Bot::Freyr::Base 'Class';
    use Bot::Freyr::Base 'Role';
    use Bot::Freyr::Base 'Test';

=head1 DESCRIPTION

This is the base module that all Bot::Freyr files should use.

This module always imports the following into your namespace:

=over

=item L<Bot::Freyr>

The base module is imported to make sure that L<File::Share> can find the right
share directory.

=item L<strict>

=item L<warnings>

=item L<feature>

Currently the 5.20 feature bundle

=item L<experimental> 'signatures' 'postderef'

We are using the 5.20 experimental signatures and postfix deref syntax.

=back

=head1 BUNDLES

The following bundles are available. You may import one or more of these by name.

=head2 Class

The class bundle makes your package into a class and includes:

=over 4

=item L<Moo>

=item L<Types::Standard> ':all'

=back

=head2 Role

The role bundle makes your package into a role and includes:

=over 4

=item L<Moo::Role>

=item L<Types::Standard> ':all'

=back

=head2 Test

The test bundle includes:

=over 4

=item L<Test::More>

=item L<Test::Deep>

=item L<Test::Differences>

=item L<Test::Exception>

=back

=head1 SEE ALSO

=over

=item L<Import::Base>

=back
