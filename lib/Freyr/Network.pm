package Freyr::Network;
# ABSTRACT: A single IRC network connection

use Freyr::Base 'Class';
use Mojo::IRC;
use Freyr::Channel;

=attr nick

The nick to use for this connection. Required.

=cut

has nick => (
    is => 'ro',
    isa => Str,
    required => 1,
);

=attr host

The hostname to connect to. Required.

=cut

has host => (
    is => 'ro',
    isa => Str,
    required => 1,
);

=attr port

The port to connect to. Defaults to 6667.

=cut

has port => (
    is => 'ro',
    isa => Int,
    default => sub { 6667 },
);

=attr log

The L<Mojo::Log> object for this network. This allows per-network logging.

=cut

has log => (
    is => 'ro',
    isa => InstanceOf['Mojo::Log'],
    default => sub { Mojo::Log->new },
);

=attr irc

The L<Mojo::IRC> object for this network connection

=cut

has irc => (
    is => 'ro',
    isa => InstanceOf['Mojo::IRC'],
    lazy => 1,
    default => sub ( $self ) {
        my $irc = Mojo::IRC->new(
            nick => $self->nick,
            user => 'freyr',
            server => join( ':', $self->host, $self->port ),
        );
        $irc->on( close => sub { warn "CLOSED: " . join " ", @_ } );
        $irc->on( error => sub { warn "IRC ERROR: " . join " ", @_ } );
        $irc->on( irc_error => sub { warn "IRC ERROR: " . join " ", @_ } );
        $irc->connect( sub ( $irc, $err ) {
            warn "CONNECT ERROR: $err" if $err;
            $self->_connected( 1 );
            # Connect to all the channels we want
            # We must wait until we're connected before we can join channels
            for my $channel ( values %{ $self->_channels } ) {
                $irc->write( JOIN => $channel->name );
            }
        } );
        return $irc;
    },
);

=attr _channels

A hashref of the currently-joined channels

=cut

has _channels => (
    is => 'ro',
    isa => HashRef[ InstanceOf['Freyr::Channel'] ],
    default => sub { {} },
);

=attr _connected

If true, we're connected. We must wait until we're connected to be able to do anything.

=cut

has _connected => (
    is => 'rw',
    isa => Bool,
    default => sub { 0 },
);

=method channel( NAME )

Get the L<channel|Freyr::Channel> with the given name, joining it if necessary.

=cut

sub channel( $self, $name ) {
    my $channel = $self->_channels->{ $name };
    if ( !$channel ) {
        $channel = $self->_channels->{ $name }
            = Freyr::Channel->new( name => $name, network => $self );
        my $irc = $self->irc; # connect to IRC
        if ( $self->_connected ) {
            $irc->write( JOIN => $name );
        }
    }
    return $channel;
}

1;
__END__

=head1 DESCRIPTION

This class encapsulates a single IRC connection.

