package Freyr;
# ABSTRACT: IRC bot with multi-network and web API

use Freyr::Base 'Class';
use Freyr::Network;
use Freyr::Message;

=attr nick

The default nickname for the bot

=cut

has nick => (
    is => 'ro',
    isa => Str,
);

=attr prefix

The prefix character. A shortcut to address the bot.

=cut

has prefix => (
    is => 'ro',
    isa => Str,
);

=attr host

The default host to connect to in single-network mode.

=cut

has host => (
    is => 'ro',
    isa => Str,
);

=attr port

The default port to connect to in single-network mode.

=cut

has port => (
    is => 'ro',
    isa => Int,
);

=attr network

The L<network|Freyr::Network> the bot is currently connected to.

=cut

has network => (
    is => 'rw',
    isa => InstanceOf['Freyr::Network'],
    lazy => 1,
    default => sub ( $self ) {
        Freyr::Network->new(
            map {; $_ => $self->$_ }
            grep { defined $self->$_ }
            qw( nick host port )
        );
    },
);

=attr channels

The channel names to connect to in single-network mode.

=cut

has channels => (
    is => 'ro',
    isa => ArrayRef[Str],
    default => sub { [] },
);

=attr _routes

The routes for the entire bot.

=cut

has _routes => (
    is => 'ro',
    isa => HashRef,
    default => sub { {} },
);

=attr _unders

The unders for the entire bot.

=cut

has _unders => (
    is => 'ro',
    isa => HashRef[ArrayRef[CodeRef]],
    default => sub { {} },
);

=method BUILD

Initialize the network in single-network mode.

=cut

sub BUILD( $self, @ ) {
    if ( my $network = $self->network ) {
        $network->irc->on( irc_privmsg => $self->curry::weak::_route_message( $network ) );
        $network->channel( $_ ) for $self->channels->@*;
    }
}

=method channel( NAME )

Get a L<channel|Freyr::Channel> object, joining the channel if necessary.

=cut

sub channel {
    my ( $self, $name ) = @_;
    return $self->network->channel( $name );
}

=method route( SPEC => SUB )

Add a route to the entire bot. Routes must be unique. Only one route will be triggered
for every message.

=cut

sub route( $self, $route, $cb ) {
    $self->_routes->{ $route } = $cb;
}

=method under( SPEC => SUB )

Add a callback to the entire bot. Unlike L<route>, unders do not need to be
unique, and multiple unders may be called for a single message.

=cut

sub under {
    my ( $self, $route, $cb ) = @_;
    #; say "Adding under $route";
    push $self->_unders->{ $route }->@*, $cb;
    #; use Data::Dumper;
    #; say Dumper $self->_unders;
    return;
}

=method _route_message( NETWORK, MESSAGE )

=cut

sub _route_message( $self, $network, $irc, $irc_msg ) {
    my ( $to, @words ) = @{ $irc_msg->{params} };
    my $raw_text = join " ", @words;
    my $me = $self->nick;
    my $prefix = $self->prefix;
    my ( $from_nick ) = $irc_msg->{prefix} =~ /^([^!]+)!([^@]+)\@(.+)$/;
    my $channel;

    my ( $to_me );
    if ( $to eq $me ) {
        $to_me = 1;
    }
    elsif ( $to =~ /^\#/ ) {
        $channel = $to;
        if ( $words[0] =~ /^$me[:,]?$/ ) {
            $to_me = 1;
            shift @words;
        }
        elsif ( $words[0] =~ /^$prefix/ ) {
            $to_me = 1;
            $words[0] =~ s/^$prefix//;
        }
    }
    my $text = join " ", @words;

    my sub _route_cb( $route, $cb ) {
        return if !$to_me && $route !~ m{^/}; # Prefixed route (the default)
        my $route_text = $route =~ m{^/} ? $raw_text : $text;
        my ( $route_re, @names ) = _route_re( $route );
        #; say "$route_text =~ $route_re";
        if ( $route_text =~ $route_re ) {
            my %params = %+;
            my $msg = Freyr::Message->new(
                bot => $self,
                network => $network,
                ( $channel ? ( channel => $network->channel( $channel ) ) : () ),
                nick => $from_nick,
                text => $route_text,
            );

            my $reply = $cb->( $msg, %params );
            if ( $reply ) {
                my @to;
                if ( $to =~ /^\#/ ) {
                    @to = ( $to, "$from_nick:" );
                }
                else {
                    @to = ( $from_nick );
                }
                $irc->write( join " ", "PRIVMSG", @to, $reply );
            }

            return 1; # We routed the message
        }
        return;
    }

    for my $route ( sort { length $b <=> length $a } keys $self->_unders->%* ) {
        #; say "Checking under $route";
        my @cbs = $self->_unders->{ $route }->@*;
        my $cb = sub { $_->(@_) for @cbs };
        _route_cb( $route, $cb );
    }
    for my $route ( sort { length $b <=> length $a } keys $self->_routes->%* ) {
        my $cb = $self->_routes->{ $route };
        last if _route_cb( $route, $cb );
    }
}

sub _route_re {
    my ( $route ) = @_;
    $route =~ s{^/}{};
    while ( $route =~ /:/ ) {
        $route =~ s/\s+\:(\w+)([?]?)/( $2 eq '?' ? '\\s*' : '\\s+' ) . "(?<$1>\\S+)$2"/e;
    }
    #; say $route;
    return qr{^$route};
}

1;
__END__

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

Freyr is an IRC bot designed for multiple networks and a web interface.
