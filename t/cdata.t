use Test::More tests => 5;

use strict;

BEGIN { use_ok('XML::Stream', 'Node'); }

my $a = XML::Stream::Node->new;
$a->set_tag("body");
$a->add_cdata("one");

is ($a->GetXML(), q[<body>one</body>], 'cdata');

my $b = $a->copy;

is ($b->GetXML(), q[<body>one</body>], 'copy cdata');

$a->add_child("a","two")->put_attrib(href=>"http://www.google.com");
$a->add_cdata("three");

is ($a->GetXML(), q[<body>one<a href='http://www.google.com'>two</a>three</body>], 'cdata/element/cdata');

my $c = $a->copy;

is ($c->GetXML(), q[<body>one<a href='http://www.google.com'>two</a>three</body>], 'copy cdata/element/cdata');

