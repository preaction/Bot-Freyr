package Freyr::Route;
# ABSTRACT: A destination for a message

use Freyr::Base 'Class';
use Freyr::Event;
use Scalar::Util qw( blessed );
with 'Beam::Emitter';

=attr prefix

The prefixes to identify when the bot is being addressed.

=cut

has prefix => (
    is => 'ro',
    isa => ArrayRef[Str|RegexpRef],
    default => sub { [] },
);

=attr parent

The parent route, if any. This is set automatically by under().

=attr root

The highest-level parent, if any. This is set automatically by under().

=cut

has [qw( parent root )] => (
    is => 'ro',
    isa => Maybe[InstanceOf['Freyr::Route']],
);

=attr _routes

The routes attached to this object.

=cut

has _routes => (
    is => 'ro',
    isa => HashRef[CodeRef|InstanceOf['Freyr::Route']],
    default => sub { {} },
);

=attr _unders

The unders attached to this object.

=cut

has _unders => (
    is => 'ro',
    isa => HashRef[ArrayRef[CodeRef]],
    default => sub { {} },
);

=method msg( ROUTE => DESTINATION )

Register a route for a prefixed message. A prefixed message is where the bot is
being directly addressed, determined by the L</prefix> attribute.

This is the most common kind of route.

=cut

sub msg( $self, $route, $dest ) {
    $self->_routes->{ $route } = $dest;
}

=method privmsg( ROUTE => DESTINATION )

Register a route for all C<PRIVMSG> IRC messages.

=cut

sub privmsg( $self, $route, $dest ) {
    $self->_routes->{ "/$route" } = $dest;
}

=method under( ROUTE, [CALLBACK] )

Create a child router at the given ROUTE. Returns a new L<Freyr::Route> object.

If C<CALLBACK> is defined, the callback is called before routing. If the callback
does not return a true value, routing is stopped. If the callback throws an exception,
an error message is printed to the user.

=cut

sub under( $self, $route, $cb=sub { 1 } ) {
    my $router = Freyr::Route->new(
        ( map {; $_ => $self->$_ } qw( prefix ) ),
        root => $self->root || $self,
        parent => $self,
    );
    $self->_routes->{ $route } = $router;
    $self->_unders->{ $route } = $cb;
    return $router;
}

=method dispatch( MESSAGE )

Dispatch a method to this router. Returns the result of the route found, if any.

=cut

sub dispatch( $self, $msg ) {
    my $text = $msg->text;

    my $to_me = 0;
    my $prefix_text = '';
    if ( $msg->to eq $msg->bot->nick ) {
        $to_me = 1;
    }
    elsif ( $msg->channel ) {
        for my $prefix ( $self->prefix->@* ) {
            #; say "Checking prefix: $text =~ $prefix";
            if ( $text =~ /^($prefix\s*)/ ) {
                $to_me = 1;
                $prefix_text = $1;
                $text =~ s/^$prefix_text//;
                last;
            }
        }
    }
    #; say "To me: $to_me";

    # Decide if the route matches the message, and if so, deliver to the destination
    my $_route_cb = sub ( $route, $in_msg, $dest ) {
        return if !$to_me && $route !~ m{^/}; # Prefixed route (the default)
        my $route_text = $route =~ m{^/} ? $in_msg->text : $text;
        my ( $route_re, @names ) = _route_re( $route );
        #; say "$route_text =~ $route_re";

        if ( $route_text =~ $route_re ) {
            #; say "Destination: $dest";
            my $remain_text = $route_text =~ s/$route_re\s*//r;
            my %params = %+;
            my $reply;

            if ( blessed $dest && $dest->isa( 'Freyr::Route' ) ) {
                #; say "Going down with: ${prefix_text}${remain_text}";
                my $out_msg = $in_msg->clone(
                    # Reattach the prefix for the children
                    text => $prefix_text . $remain_text,
                );

                # Allow under to control access to the route
                my $under = $self->_unders->{ $route };
                #; say "Checking under $route";
                return unless $under->( $out_msg, %params );

                #; say "Under allows dispatching to $route";
                $reply = $dest->dispatch( $out_msg );
            }
            elsif ( ref $dest eq 'CODE' ) {
                my $out_msg = $in_msg->clone(
                    text => $remain_text,
                );
                $reply = $dest->( $out_msg, %params );
            }
            else {
                die "Unknown destination: $dest";
            }

            return $reply if $reply; # We routed the message
        }
        #; say "Denied";
        return;
    };

    my $event = $self->emit( before_dispatch => (
        class => 'Freyr::Event::Message',
        message => $msg,
    ) );
    return if $event->is_default_stopped;

    my $reply;
    for my $route ( sort { length $b <=> length $a } keys $self->_routes->%* ) {
        my $dest = $self->_routes->{ $route };
        #; say "Trying $route -> $dest";
        $reply = $_route_cb->( $route, $msg, $dest );
        last if $reply;
    }

    $self->emit( after_dispatch => (
        class => 'Freyr::Event::Message',
        message => $msg,
    ) );

    return $reply;
}

# Build a regex that matches the given route, capturing the placeholders
sub _route_re( $route ) {
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

=head1 DESCRIPTION

=head1 DESTINATIONS

=head2 Subroutine References

A subref destination will get one argument, the L<Freyr::Message> being routed.

=event before_dispatch

Emitted before dispatch starts. If this event returns a false value, routing is
stopped (much like L</under>).

=event after_dispatch

Emitted after dispatch has finished, whether or not a destination was found. If
there was an exception, this event will not be emitted.

