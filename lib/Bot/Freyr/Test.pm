package Bot::Freyr::Test;
our $VERSION = '0.001';
# ABSTRACT: Test functions for Bot::Freyr

use Bot::Freyr::Base 'Test';
use List::Util qw( pairs );
use Sub::Exporter -setup => {
    exports => [qw( test_irc_msg )],
};

=sub test_irc_msg( $irc, $send, @tests )

Send an IRC message over the $irc object and test the routing of the message.

$send is a message to send over IRC using Mojo::IRC's offline testing method.
You must include the full IRC message, like:

    :nick!user@host PRIVMSG #defocus Hello!

@tests is a list of pairs of tests ($test) and values to test against ($recv)

$test must be either C<like> or C<unlike>, and L<Test::More>'s
L<Test::More/like|like> or L<Test::More/unlike> will be used.

$recv must be a string or regexp to test.

Returns a subref suitable to be passed to Test::More's subtest().

Also checks to make sure that common route callback problems do not occur.

=cut

sub test_irc_msg( $irc, $send, @tests ) {
    return sub {
        $irc->{to_irc_server} = '';
        $irc->from_irc_server( $send . "\r\n" );

        for my $t ( pairs @tests ) {
            my ( $test, $recv ) = @$t;
            if ( $test eq 'like' ) {
                like $irc->{to_irc_server}, qr{$recv\r\n};
            }
            elsif ( $test eq 'unlike' ) {
                unlike $irc->{to_irc_server}, qr{$recv\r\n};
            }
        }

        unlike $irc->{to_irc_server}, qr{\Q$irc\E\r\n},
            'returned IRC object is not spoken';
        $irc->{to_irc_server} = '';
    }
}

1;

=head1 SYNOPSIS

    use Bot::Freyr::Base 'Test';
    subtest 'test a message' => test_irc_msg(
        $irc, ':preaction!user@host PRIVMSG freyr Hello!',
        like => qr{PRIVMSG preaction Hello, preaction!},
    );

=head1 DESCRIPTION

A collection of helpful test subroutines.

