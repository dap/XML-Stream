BEGIN {print "1..5\n";}
END {print "not ok 1\n" unless $loaded;}
use XML::Stream qw( Hash );
$loaded = 1;
print "ok 1\n";

my @tests;
$tests[4] = 1;

my $stream = new XML::Stream(#debug=>"stdout",debuglevel=>99,
style=>"hash");

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
  my ($packet) = @_;

  return unless exists($packet->{"1-att-test"});

  if ($packet->{"1-att-test"} eq "2") {
    $tests[2] = 1;
  }
  if ($packet->{"1-att-test"} eq "3") {
    if (defined($packet->{"2-tag"}) && ($packet->{"2-tag"} eq "bar")) {
      $tests[3] = 1;
    }
  }
  if ($packet->{"1-att-test"} eq "4") {
    $tests[4] = 0;
  }
  if ($packet->{"1-att-test"} eq "5") {
    if (defined($packet->{"4-data"}) && ($packet->{"4-data"} eq "This is a test.")) {
      $tests[5] = 1;
    }
  }
}
