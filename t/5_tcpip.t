BEGIN {print "1..3\n";}
END {print "not ok 1\n" unless $loaded;}
use XML::Stream qw( Tree Hash );
$loaded = 1;
print "ok 1\n";

my @tests;
$tests[4] = 1;
$tests[8] = 1;

my $stream = new XML::Stream(style=>"hash");

if ($stream) {
  $tests[2] = 1;

  my $status = $stream->Connect(hostname=>"obelisk.net",
				port=>5222,
				namespace=>"jabber:client",
				connectiontype=>"tcpip",
				timeout=>10);

  if ($status) {
    $tests[3] = 1;
  }
}

foreach (2..3) {
  print "not " unless $tests[$_];
  print "ok $_\n";
}

