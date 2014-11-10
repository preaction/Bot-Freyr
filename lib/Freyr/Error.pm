package Freyr::Error;
# ABSTRACT: An error response, which stops routing

use Freyr::Base 'Class';

=attr error

The error message to give the user

=cut

has error => (
    is => 'ro',
    isa => Str,
    required => 1,
);

=attr message

The message that caused the error.

=cut

has message => (
    is => 'ro',
    isa => InstanceOf['Freyr::Message'],
);

1;
__END__

=head1 SYNOPSIS

    my $err = Freyr::Error->new(
        error => 'An error occurred',
        message => $msg,
    );

=head1 DESCRIPTION

An error can be returned from a route or an under. If returned from an under,
an error stops the message from being routed.

