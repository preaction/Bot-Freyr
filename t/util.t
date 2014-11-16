
use Freyr::Base 'Test';
use Freyr::Util qw( mask_match );

subtest mask_match => sub {
    my $mask = 'preaction!doug@example.com';

    subtest 'exact match' => sub {
        ok mask_match( $mask, $mask ), 'nick!user@host';
        ok !mask_match( 'preaction_!doug@example.com', $mask );
        ok !mask_match( 'preaction!joel@example.com', $mask );
        ok !mask_match( 'preaction!doug@example.net', $mask );
    };

    subtest 'nick!user@*' => sub {
        ok mask_match( $mask, 'preaction!doug@*' );
        ok !mask_match( $mask, 'preaction!joel@*' );
        ok !mask_match( $mask, 'jberger!doug@*' );
    };

    subtest 'nick!*@host' => sub {
        ok mask_match( $mask, 'preaction!*@example.com' );
        ok !mask_match( $mask, 'preaction!*@example.net' );
        ok !mask_match( $mask, 'jberger!*@example.com' );
    };

    subtest '*!user@host' => sub {
        ok mask_match( $mask, '*!doug@example.com' );
        ok !mask_match( $mask, '*!doug@example.net' );
        ok !mask_match( $mask, '*!joel@example.com' );
    };

    subtest '*@host' => sub {
        ok mask_match( $mask, '*@example.com' );
        ok !mask_match( $mask, '*@example.net' );
    };

    subtest 'nick!*' => sub {
        ok mask_match( $mask, 'preaction!*' );
        ok !mask_match( $mask, 'jberger!*' );
    };

};

done_testing;
