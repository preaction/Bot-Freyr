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

=attr text

The text of the message, after being normalized:

    - If the bot is being addressed, remove the bot's name
    - If the prefix was being used, remove it

=cut

has text => (
    is => 'ro',
    isa => Str,
    required => 1,
);

1;
