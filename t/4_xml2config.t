BEGIN {print "1..13\n";}
END {print "not ok 1\n" unless $loaded;}
use XML::Stream qw( Tree Hash Node );
$loaded = 1;
print "ok 1\n";

my @tests;
$tests[4] = 1;
$tests[8] = 1;
$tests[12] = 1;

my $parser_tree = new XML::Stream::Parser(style=>"tree");
my $tree = $parser_tree->parsefile("t/test.xml");

%config = %{&XML::Stream::XML2Config($tree)};

if (exists($config{blah})) {
  my @keys = keys(%{$config{blah}});
  if ($#keys == -1) {
    $tests[2] = 1;
  }
}

if (exists($config{foo}->{bar})) {
  my @keys = keys(%{$config{foo}->{bar}});
  if ($#keys == -1) {
    $tests[3] = 1;
  }
}

if (exists($config{comment_test})) {
  $tests[4] = 0;
}


if (exists($config{last}->{test1}->{test2}->{test3})) {
  if ($config{last}->{test1}->{test2}->{test3} eq "This is a test.") {
    $tests[5] = 1;
  }
}


my $parser_hash = new XML::Stream::Parser(style=>"hash");
my $hash = $parser_hash->parsefile("t/test.xml");

%config = %{&XML::Stream::XML2Config($hash)};

if (exists($config{blah})) {
  my @keys = keys(%{$config{blah}});
  if ($#keys == -1) {
    $tests[6] = 1;
  }
}

if (exists($config{foo}->{bar})) {
  my @keys = keys(%{$config{foo}->{bar}});
  if ($#keys == -1) {
    $tests[7] = 1;
  }
}

if (exists($config{comment_test})) {
  $tests[8] = 0;
}

if (exists($config{last}->{test1}->{test2}->{test3})) {
  if ($config{last}->{test1}->{test2}->{test3} eq "This is a test.") {
    $tests[9] = 1;
  }
}


my $parser_node = new XML::Stream::Parser(style=>"node");
my $node = $parser_node->parsefile("t/test.xml");

%config = %{&XML::Stream::XML2Config($node)};

if (exists($config{blah})) {
  my @keys = keys(%{$config{blah}});
  if ($#keys == -1) {
    $tests[10] = 1;
  }
}

if (exists($config{foo}->{bar})) {
  my @keys = keys(%{$config{foo}->{bar}});
  if ($#keys == -1) {
    $tests[11] = 1;
  }
}

if (exists($config{comment_test})) {
  $tests[12] = 0;
}

if (exists($config{last}->{test1}->{test2}->{test3})) {
  if ($config{last}->{test1}->{test2}->{test3} eq "This is a test.") {
    $tests[13] = 1;
  }
}


foreach (2..13) {
  print "not " unless $tests[$_];
  print "ok $_\n";
}

