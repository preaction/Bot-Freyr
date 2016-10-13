package Bot::Freyr::Util;
our $VERSION = '0.001';
# ABSTRACT: Useful utilities for Bot::Freyr

use Bot::Freyr::Base;
use Sub::Exporter -setup => {
    exports => [qw( mask_match )],
};

=sub mask_match( $mask, $match )

Returns true if the given hostmask matches the given match string.

$mask must be a complete C<nick!user@host> string. $match may contain C<*> as a
wildcard character.

=cut

sub mask_match( $mask, $match ) {
    # Split on *, allowing * at the end
    my $re = join ".*", map { quotemeta $_ } split /\*/, $match, -1;
    #; say "Mask: $mask";
    #; say "Match: $match";
    #; say "RE: $re";
    return $mask =~ /^$re$/;
}

1;
__END__

=head1 SYNOPSIS

    my $mask = 'nick!user@host';
    die "Unauthorized" unless mask_match( $mask, 'nick!user@*' );
