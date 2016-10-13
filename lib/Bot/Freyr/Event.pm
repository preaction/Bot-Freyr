package Bot::Freyr::Event;
our $VERSION = '0.001';
# ABSTRACT: Events for the Bot::Freyr bot

package Bot::Freyr::Event::Message {
    use Bot::Freyr::Base 'Class';
    extends 'Beam::Event';

    has message => (
        is => 'ro',
        isa => InstanceOf['Bot::Freyr::Message'],
        required => 1,
    );
}

1;
__END__

=head1 SYNOPSIS

=head1 DESCRIPTION

This package contains various event classes for controlling Bot::Freyr behavior.

