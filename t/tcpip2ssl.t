
use lib "t/lib";
use Test::More tests=>3;

SKIP:
{
    eval("use IO::Socket::SSL 0.81;");
    skip "IO::Socket::SSL not installed", 2 if $@;

    BEGIN{ use_ok( "XML::Stream","Tree", "Node" ); }

    my $stream = new XML::Stream(style=>"node");
    ok( defined($stream), "new()" );

    SKIP:
    {

        my $status = $stream->Connect(hostname=>"obelisk.net",
                                      port=>5223,
                                      namespace=>"jabber:client",
                                      connectiontype=>"tcpip",
                                      ssl=>1,
                                      timeout=>10);

        skip "Cannot create initial socket", 1 unless $stream;
        
        ok( $stream, "converted" );
    }
}
