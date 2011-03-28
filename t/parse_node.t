BEGIN {print "1..7\n";}
END {print "not ok 1\n" unless $loaded;}
use XML::Stream qw( Node );
$loaded = 1;
print "ok 1\n";

my @tests;
$tests[4] = 1;

my $stream = XML::Stream->new( #debug=>"stdout",debuglevel=>99,
style=>"node");

$stream->SetCallBacks(node=>sub{ &onPacket(@_) });

my $sid = $stream->OpenFile("t/test.xml");
my %status;
while( %status = $stream->Process()) {
  last if ($status{$sid} == -1);
}

foreach (2..6) {
  print "not " unless $tests[$_];
  print "ok $_\n";
}

sub onPacket {
  my $sid = shift;
  my ($packet) = @_;

  return unless $packet->get_attrib("test");

  if ($packet->get_attrib("test") eq "2") {
    $tests[2] = 1;
  }

  if ($packet->get_attrib("test") eq "3") {
    if (($packet->children())[1]->get_tag() eq "bar") {
      $tests[3] = 1;
    }
  }
  if ($packet->get_attrib("test") eq "4") {
    $tests[4] = 0;
  }
  if ($packet->get_attrib("test") eq "5") {
    if (((($packet->children())[1]->children())[1]->children())[1]->get_cdata() eq "This is a test.") {
      $tests[5] = 1;
    }
  }
  if ($packet->get_attrib("test") eq "6") {
    if ($packet->get_cdata() eq "This is cdata with <tags/> embedded <in>it</in>.") {
      $tests[6] = 1;
    }
  }
}

my $node = XML::Stream::Node->new("test","<foo/>");

print "not " unless ($node->GetXML() eq "<test>&lt;foo/&gt;</test>");
print "ok 7\n";

