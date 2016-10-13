package Bot::Freyr::Network;
our $VERSION = '0.001';
# ABSTRACT: A single IRC network connection

use Bot::Freyr::Base 'Class';
use Mojo::IRC;
use Bot::Freyr::Channel;

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
        $irc->on( close => sub { $self->log->warn( "CLOSED:", @_ ) } );
        $irc->on( error => sub { $self->log->warn( "IRC ERROR:", @_ ) } );
        $irc->on( irc_error => sub { $self->log->warn( "IRC ERROR:", @_ ) } );
        $irc->connect( sub ( $irc, $err ) {
            if ( $err ) {
                $self->log->error( "CONNECT ERROR:", $err );
                return;
            }

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
    isa => HashRef[ InstanceOf['Bot::Freyr::Channel'] ],
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

Get the L<channel|Bot::Freyr::Channel> with the given name, joining it if necessary.

=cut

sub channel( $self, $name ) {
    my $channel = $self->_channels->{ $name };
    if ( !$channel ) {
        $channel = $self->_channels->{ $name }
            = Bot::Freyr::Channel->new( name => $name, network => $self );
        my $irc = $self->irc; # connect to IRC
        if ( $self->_connected ) {
            $irc->write( JOIN => $name );
        }
    }
    return $channel;
}

1;
__END__

=head1 SYNOPSIS

    my $net = Bot::Freyr::Network->new(
        nick => 'freyr',
        host => 'irc.freenode.net',
        port => 6667,
    );

    my $chan = $net->channel( '#defocus' );

=head1 DESCRIPTION

This class encapsulates a single IRC connection.

