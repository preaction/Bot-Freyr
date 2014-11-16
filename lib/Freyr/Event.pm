package Freyr::Event;
# ABSTRACT: Events for the Freyr bot

package Freyr::Event::Message {
    use Freyr::Base 'Class';
    extends 'Beam::Event';

    has message => (
        is => 'ro',
        isa => InstanceOf['Freyr::Message'],
        required => 1,
    );
}

1;
__END__

=head1 SYNOPSIS

=head1 DESCRIPTION

This package contains various event classes for controlling Freyr behavior.

