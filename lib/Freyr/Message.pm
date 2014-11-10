package Freyr::Message;
# ABSTRACT: An incoming message

use Freyr::Base 'Class';

=attr bot

The L<bot|Freyr> that received this message.

=cut

has bot => (
    is => 'ro',
    isa => InstanceOf['Freyr'],
    required => 1,
);

=attr network

The L<network|Freyr::Network> this message was received via.

=cut

has network => (
    is => 'ro',
    isa => InstanceOf['Freyr::Network'],
    required => 1,
);


=attr channel

The L<channel|Freyr::Channel> this message was received on, if any.

=cut

has channel => (
    is => 'ro',
    isa => InstanceOf['Freyr::Channel'],
);

=attr nick

The nick of the user who sent the message.

=cut

has nick => (
    is => 'ro',
    isa => Str,
    required => 1,
);

=attr hostmask

The hostmask of the sender of this message.

=cut

has hostmask => (
    is => 'ro',
    isa => Str,
);

=attr to

Who the message was sent to. This will be either the nickname of the bot or the name of
a channel.

=cut

has to => (
    is => 'ro',
    isa => Str,
);

=attr text

The text of the message, after being normalized:

    - If the bot is being addressed, remove the bot's name
    - If the prefix was being used, remove it

As this passes through the router, it will be changed to reflect the current router
state.

=cut

has text => (
    is => 'ro',
    isa => Str,
    required => 1,
);

=attr raw

The raw IRC message, passed through all the routes without modification.

=cut

has raw => (
    is => 'ro',
    isa => Str,
    lazy => 1,
    default => sub ( $self ) { $self->text },
);

=method clone( ARGS )

Clone this message, overriding with the given ARGS.

=cut

sub clone( $self, %args ) {
    return __PACKAGE__->new(
        %$self,
        %args,
    );
}

1;
