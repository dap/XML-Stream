use strict;
use warnings;

use Test::More tests => 11;

BEGIN { use_ok('XML::Stream', 'Node'); }

my $a = XML::Stream::Node->new;
isa_ok $a, 'XML::Stream::Node';
$a->set_tag("body");
$a->add_cdata("one");

is ($a->GetXML(), q[<body>one</body>], 'cdata');

my $b = $a->copy;
isa_ok $b, 'XML::Stream::Node';
isnt $a, $b, 'not the same';

is ($b->GetXML(), q[<body>one</body>], 'copy cdata');

$a->add_child("a","two")->put_attrib(href=>"http://www.google.com");
$a->add_cdata("three");

is ($a->GetXML(), q[<body>one<a href='http://www.google.com'>two</a>three</body>], 'cdata/element/cdata');

my $c = $a->copy;
isa_ok $c, 'XML::Stream::Node';
isnt $a, $c, 'not the same';
isnt $b, $c, 'not the same';

is ($c->GetXML(), q[<body>one<a href='http://www.google.com'>two</a>three</body>], 'copy cdata/element/cdata');

