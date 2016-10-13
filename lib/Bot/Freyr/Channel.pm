package Bot::Freyr::Channel;
our $VERSION = '0.001';
# ABSTRACT: A single connected IRC channel

use Bot::Freyr::Base 'Class';

=attr name

The name of the channel.

=cut

has name => (
    is => 'ro',
    isa => Str,
    required => 1,
);

=attr network

The L<network|Bot::Freyr::Network> this channel is on.

=cut

has network => (
    is => 'ro',
    isa => InstanceOf['Bot::Freyr::Network'],
    required => 1,
);

1;
__END__

=head1 SYNOPSIS

    my $net = Bot::Freyr::Network->new(
        nick => 'freyr',
        host => 'irc.freenode.net',
    );

    my $chan = Bot::Freyr::Channel->new(
        name => '#defocus',
        network => $net,
    );

    my $chan = $net->channel( '#defocus' );

=head1 DESCRIPTION

This module encapsulates a single channel's information.
