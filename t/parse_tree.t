BEGIN {print "1..5\n";}
END {print "not ok 1\n" unless $loaded;}
use XML::Stream qw( Tree );
$loaded = 1;
print "ok 1\n";

my @tests;
$tests[4] = 1;

my $stream = new XML::Stream(style=>"tree");

$stream->SetCallBacks(node=>sub{ &onPacket(@_) });

my $sid = $stream->OpenFile("t/test.xml");
my %status;
while( %status = $stream->Process()) {
  last if ($status{$sid} == -1);
}

foreach (2..5) {
  print "not " unless $tests[$_];
  print "ok $_\n";
}

sub onPacket {
  my $sid = shift;
  my (@packet) = @_;

  return unless exists($packet[1]->[0]->{test});

  if ($packet[1]->[0]->{test} eq "2") {
    $tests[2] = 1;
  }
  if ($packet[1]->[0]->{test} eq "3") {
    if (defined($packet[1]->[3]) && ($packet[1]->[3] eq "bar")) {
      $tests[3] = 1;
    }
  }
  if ($packet[1]->[0]->{test} eq "4") {
    $tests[4] = 0;
  }
  if ($packet[1]->[0]->{test} eq "5") {
    if (defined($packet[1]->[4]->[4]->[4]->[2]) && ($packet[1]->[4]->[4]->[4]->[2] eq "This is a test.")) {
      $tests[5] = 1;
    }
  }

}
