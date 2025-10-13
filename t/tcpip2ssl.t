use strict;
use warnings;

use Test::More tests=>5;

SKIP:
{
    eval("use IO::Socket::SSL 0.81;");
    skip "IO::Socket::SSL not installed", 4 if $@;
    skip "No network communication allowed", 4 if ($ENV{NO_NETWORK});

    BEGIN{ use_ok( "XML::Stream","Tree", "Node" ); }

    my $stream = XML::Stream->new(
        style=>'node',
        debug=>'stdout',
        debuglevel=>0,
    );
    ok( defined($stream), "new()" );

    SKIP:
    {

        my $status = $stream->Connect(hostname=>"jabber.org",
                                      port=>5223,
                                      namespace=>"jabber:client",
                                      connectiontype=>"tcpip",
                                      ssl=>1,
                                      ssl_verify=>0x00,
                                      timeout=>10);
        is( $stream->{SIDS}->{newconnection}->{ssl_params}->{SSL_verifycn_name},
            'jabber.org', 'SSL_verifycn_name set' );

        skip "Cannot create initial socket", 2 unless $stream;
        
        ok( $stream, "converted" );

        $stream->Connect(hostname=>"jabber.org",
                         to=>'example.com',
                         port=>5223,
                         namespace=>"jabber:client",
                         connectiontype=>"tcpip",
                         ssl=>1,
                         ssl_verify=>0x00,
                         timeout=>10);
        is( $stream->{SIDS}->{newconnection}->{ssl_params}->{SSL_verifycn_name},
            'example.com', 'SSL_verifycn_name set to "to" value' );
    }
}
