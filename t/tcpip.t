use lib "t/lib";
use Test::More tests=>4;

BEGIN{ use_ok("XML::Stream","Node"); }

my $stream = new XML::Stream(style=>"node");
ok( defined($stream), "new()" );
isa_ok( $stream, "XML::Stream" );

SKIP:
{
    my $sock = IO::Socket::INET->new(PeerAddr=>'jabber.org:5222');
    skip "Cannot open connection (maybe a firewall?)",1 unless defined($sock);
    
    my $status = $stream->Connect(hostname=>"jabber.org",
                                  port=>5222,
                                  namespace=>"jabber:client",
                                  connectiontype=>"tcpip",
                                  timeout=>10);
    ok( defined($status), "Made connection");
}

