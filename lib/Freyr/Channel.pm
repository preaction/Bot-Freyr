package Freyr::Channel;
# ABSTRACT: A single connected IRC channel

use Freyr::Base 'Class';

=attr name

The name of the channel.

=cut

has name => (
    is => 'ro',
    isa => Str,
    required => 1,
);

=attr network

The L<network|Freyr::Network> this channel is on.

=cut

has network => (
    is => 'ro',
    isa => InstanceOf['Freyr::Network'],
    required => 1,
);

1;
__END__

=head1 DESCRIPTION

This module encapsulates a single channel's information.
