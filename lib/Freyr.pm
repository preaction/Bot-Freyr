package Freyr;
# ABSTRACT: IRC bot with multi-network and web API

use Freyr::Base 'Class';
use Freyr::Network;

=attr network

The L<network|Freyr::Network> the bot is currently connected to.

=cut

has network => (
    is => 'rw',
    isa => InstanceOf['Freyr::Network'],
);

=method BUILDARGS

Handle giving network information directly to the bot constructor.

=cut

around BUILDARGS => sub {
    my ( $orig, $class, @args ) = @_;
    my $args = $class->$orig( @args );
    if ( $args->{nick} && $args->{host} ) {
        $args->{network} = Freyr::Network->new(
            map {; $_ => delete $args->{$_} }
            grep { exists $args->{$_} }
            qw( nick host port )
        );
    }
    if ( $args->{channels} ) {
        $args->{network}->channel( $_ ) for @{ $args->{channels} };
    }
    return $args;
};

=method channel( NAME )

Get a L<channel|Freyr::Channel> object, joining the channel if necessary.

=cut

sub channel {
    my ( $self, $name ) = @_;
    return $self->network->channel( $name );
}

1;
__END__

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

Freyr is an IRC bot designed for multiple networks and a web interface.
