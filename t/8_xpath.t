BEGIN {print "1..70\n";}
END {print "not ok 1\n" unless $loaded;}
use XML::Stream qw( Node Tree Hash );
$loaded = 1;
foreach (1..10) {
  print "ok $_\n";
}

my @tests;
my @value;

my %parsers;
my $node;

my $count = 11;
foreach my $type ("tree","hash","node") {

  $parsers{$type} = new XML::Stream::Parser(style=>$type);
  $node = $parsers{$type}->parsefile("t/test.xml");

  # tests 11,31,51
  @value = &XML::Stream::XPath($node,'last/@test');
  if ($#value == 0) {
    $tests[$count++] = ($value[0] == 5);
  } else {
    $tests[$count++] = 0;
  }

  # tests 12,32,52
  @value = &XML::Stream::XPath($node,'last/test1/test2/test3/text()');
  if ($#value == 0) {
    $tests[$count++] = ($value[0] eq "This is a test.");
  } else {
    $tests[$count++] = 0;
  }

  # tests 13,33,53
  @value = &XML::Stream::XPath($node,'last/test1/test2/test3');
  if ($#value == 0) {
    if (ref($node) eq "HASH") {
      my $oldRoot = $node->{root};
      $node->{root} = $value[0];
      if (&XML::Stream::GetXMLData("tag",$node) eq "test3") {
	$tests[$count++] =
	  (&XML::Stream::GetXMLData("value",$node) eq "This is a test.");
      } else {
	$tests[$count++] = 0;
      }
      $node->{root} = $oldRoot;
    } else {
      if (&XML::Stream::GetXMLData("tag",$value[0]) eq "test3") {
	$tests[$count++] =
	  (&XML::Stream::GetXMLData("value",$value[0]) eq "This is a test.");
      } else {
	$tests[$count++] = 0;
      }
    }
  } else {
    $tests[$count++] = 0;
  }

  # tests 14,34,54
  my @value = &XML::Stream::XPath($node,'foo/@*');
  if (scalar(keys(%{$value[0]})) == 1) {
    if (exists($value[0]->{test})) {
      $tests[$count++] = ($value[0]->{test} eq "3");
    } else {
      $tests[$count++] = 0;
    }
  } else {
    $tests[$count++] = 0;
  }

  # tests 15,35,55
  @value = &XML::Stream::XPath($node,'last//test3');
  if ($#value == 0) {
    if (ref($node) eq "HASH") {
      my $oldRoot = $node->{root};
      $node->{root} = $value[0];
      if (&XML::Stream::GetXMLData("tag",$node) eq "test3") {
	$tests[$count++] =
	  (&XML::Stream::GetXMLData("value",$node) eq "This is a test.");
      } else {
	$tests[$count++] = 0;
      }
      $node->{root} = $oldRoot;
    } else {
      if (&XML::Stream::GetXMLData("tag",$value[0]) eq "test3") {
	$tests[$count++] =
	  (&XML::Stream::GetXMLData("value",$value[0]) eq "This is a test.");
      } else {
	$tests[$count++] = 0;
      }
    }
  } else {
    $tests[$count++] = 0;
  }

  # tests 16-18,36-38,56-58
  @value = &XML::Stream::XPath($node,'a//e');
  if ($#value == 2) {
    if (ref($node) eq "HASH") {
      my $oldRoot = $node->{root};

      # test 16
      $node->{root} = $value[0];
      if (&XML::Stream::GetXMLData("tag",$node) eq "e") {
	$tests[$count++] =
	  (&XML::Stream::GetXMLData("value",$node,"e") eq "foo1");
      } else {
	$tests[$count++] = 0;
      }

      # test 17
      $node->{root} = $value[1];
      if (&XML::Stream::GetXMLData("tag",$node) eq "e") {
	$tests[$count++] =
	  (&XML::Stream::GetXMLData("value",$node) eq "foo1");
      } else {
	$tests[$count++] = 0;
      }

      # test 18
      $node->{root} = $value[2];
      if (&XML::Stream::GetXMLData("tag",$node) eq "e") {
	$tests[$count++] =
	  (&XML::Stream::GetXMLData("value",$node) eq "foo2");
      } else {
	$tests[$count++] = 0;
      }

      $node->{root} = $oldRoot;
    } else {

      # test 16
      if (&XML::Stream::GetXMLData("tag",$value[0]) eq "e") {
	$tests[$count++] =
	  (&XML::Stream::GetXMLData("value",$value[0],"e") eq "foo1");
      } else {
	$tests[$count++] = 0;
      }

      # test 17
      if (&XML::Stream::GetXMLData("tag",$value[1]) eq "e") {
	$tests[$count++] =
	  (&XML::Stream::GetXMLData("value",$value[1]) eq "foo1");
      } else {
	$tests[$count++] = 0;
      }

      # test 18
      if (&XML::Stream::GetXMLData("tag",$value[2]) eq "e") {
	$tests[$count++] =
	  (&XML::Stream::GetXMLData("value",$value[2]) eq "foo2");
      } else {
	$tests[$count++] = 0;
      }
    }
  } else {
    $tests[$count++] = 0; # test 16
    $tests[$count++] = 0; # test 17
    $tests[$count++] = 0; # test 18
  }

  # tests 19-22,39-42,59-62
  @value = &XML::Stream::XPath($node,'//e');
  if ($#value == 3) {
    if (ref($node) eq "HASH") {
      my $oldRoot = $node->{root};

      # test 19,39,59
      $node->{root} = $value[0];
      if (&XML::Stream::GetXMLData("tag",$node) eq "e") {
	$tests[$count++] =
	  (&XML::Stream::GetXMLData("value",$node,"e") eq "foo1");
      } else {
	$tests[$count++] = 0;
      }

      # test 20,40,60
      $node->{root} = $value[1];
      if (&XML::Stream::GetXMLData("tag",$node) eq "e") {
	$tests[$count++] =
	  (&XML::Stream::GetXMLData("value",$node) eq "foo1");
      } else {
	$tests[$count++] = 0;
      }

      # test 21,41,61
      $node->{root} = $value[2];
      if (&XML::Stream::GetXMLData("tag",$node) eq "e") {
	$tests[$count++] =
	  (&XML::Stream::GetXMLData("value",$node) eq "foo2");
      } else {
	$tests[$count++] = 0;
      }

      # test 22,42,62
      $node->{root} = $value[3];
      if (&XML::Stream::GetXMLData("tag",$node) eq "e") {
	$tests[$count++] =
	  (&XML::Stream::GetXMLData("value",$node) eq "bar");
      } else {
	$tests[$count++] = 0;
      }

      $node->{root} = $oldRoot;
    } else {

      # test 19,39,59
      if (&XML::Stream::GetXMLData("tag",$value[0]) eq "e") {
	$tests[$count++] =
	  (&XML::Stream::GetXMLData("value",$value[0],"e") eq "foo1");
      } else {
	$tests[$count++] = 0;
      }

      # test 20,40,60
      if (&XML::Stream::GetXMLData("tag",$value[1]) eq "e") {
	$tests[$count++] =
	  (&XML::Stream::GetXMLData("value",$value[1]) eq "foo1");
      } else {
	$tests[$count++] = 0;
      }

      # test 21,41,61
      if (&XML::Stream::GetXMLData("tag",$value[2]) eq "e") {
	$tests[$count++] =
	  (&XML::Stream::GetXMLData("value",$value[2]) eq "foo2");
      } else {
	$tests[$count++] = 0;
      }

      # test 22,42,62
      if (&XML::Stream::GetXMLData("tag",$value[3]) eq "e") {
	$tests[$count++] =
	  (&XML::Stream::GetXMLData("value",$value[3]) eq "bar");
      } else {
	$tests[$count++] = 0;
      }
    }
  } else {
    $tests[$count++] = 0; # test 19,39,59
    $tests[$count++] = 0; # test 20,40,60
    $tests[$count++] = 0; # test 21,41,61
    $tests[$count++] = 0; # test 22,42,62
  }

  # tests 23-24,43-44,63-64
  @value = &XML::Stream::XPath($node,'a/b//d/e');
  if ($#value == 1) {
    if (ref($node) eq "HASH") {
      my $oldRoot = $node->{root};

      # test 23,43,63
      $node->{root} = $value[0];
      if (&XML::Stream::GetXMLData("tag",$node) eq "e") {
	$tests[$count++] =
	  (&XML::Stream::GetXMLData("value",$node,"e") eq "foo1");
      } else {
	$tests[$count++] = 0;
      }

      # test 24,44,64
      $node->{root} = $value[1];
      if (&XML::Stream::GetXMLData("tag",$node) eq "e") {
	$tests[$count++] =
	  (&XML::Stream::GetXMLData("value",$node) eq "foo2");
      } else {
	$tests[$count++] = 0;
      }

      $node->{root} = $oldRoot;
    } else {

      # test 23,43,63
      if (&XML::Stream::GetXMLData("tag",$value[0]) eq "e") {
	$tests[$count++] =
	  (&XML::Stream::GetXMLData("value",$value[0],"e") eq "foo1");
      } else {
	$tests[$count++] = 0;
      }

      # test 24,44,64
      if (&XML::Stream::GetXMLData("tag",$value[1]) eq "e") {
	$tests[$count++] =
	  (&XML::Stream::GetXMLData("value",$value[1]) eq "foo2");
      } else {
	$tests[$count++] = 0;
      }

    }
  } else {
    $tests[$count++] = 0; # test 23,43,63
    $tests[$count++] = 0; # test 24,44,64
  }

  # tests 25-26,45-46,65-66
  @value = &XML::Stream::XPath($node,'library//chapter//para/@test');
  if ($#value == 1) {
    $tests[$count++] = ($value[0] eq "b"); # test 25,45,65
    $tests[$count++] = ($value[1] eq "a"); # test 26,46,66
  } else {
    $tests[$count++] = 0; # test 25,45,65
    $tests[$count++] = 0; # test 26,46,66
  }


  # tests 27,47,67
  @value = &XML::Stream::XPath($node,'filter[@id and @mytest="2"]/text()');
  if ($#value == 0) {
    $tests[$count++] = ($value[0] eq "valueA");
  } else {
    $tests[$count++] = 0;
  }


  # tests 28,48,68
  @value = &XML::Stream::XPath($node,'newfilter[@bar and sub="foo1"]');
  if ($#value == 0) {
    if (ref($node) eq "HASH") {
      my $oldRoot = $node->{root};

      $node->{root} = $value[0];
      if (&XML::Stream::GetXMLData("tag",$node) eq "newfilter") {
	$tests[$count++] =
	  (&XML::Stream::GetXMLData("value",$node,"sub") eq "foo1");
      } else {
	$tests[$count++] = 0;
      }

      $node->{root} = $oldRoot;
    } else {

      if (&XML::Stream::GetXMLData("tag",$value[0]) eq "newfilter") {
	$tests[$count++] =
	  (&XML::Stream::GetXMLData("value",$value[0],"sub") eq "foo1");
      } else {
	$tests[$count++] = 0;
      }

    }
  } else {
    $tests[$count++] = 0;
  }

  # tests 29,49,69
  @value = &XML::Stream::XPath($node,'startest/*[@test]');
  if ($#value == 1) {
    if (ref($node) eq "HASH") {
      my $oldRoot = $node->{root};

      my $test = 1;

      $node->{root} = $value[0];
      $test &= (&XML::Stream::GetXMLData("tag",$node) eq "foo");

      $node->{root} = $value[1];
      $test &= (&XML::Stream::GetXMLData("tag",$node) eq "bing");

      $tests[$count++] = $test;

      $node->{root} = $oldRoot;
    } else {
      $tests[$count++] =
	((&XML::Stream::GetXMLData("tag",$value[0]) eq "foo") &&
	 (&XML::Stream::GetXMLData("tag",$value[1]) eq "bing"));
    }
  } else {
    $tests[$count++] = 0;
  }

  $tests[$count++] = 1; # test 30

}

foreach (11..70) {
  print "not " unless $tests[$_];
  print "ok $_\n";
}
