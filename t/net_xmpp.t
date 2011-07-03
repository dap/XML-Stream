use strict;
use warnings;

use Test::More;
use XML::Stream;

# cases that are use in Net::XMPP


plan tests => 1;
#my $debug = bless {
#      'HEADER' => 'XMPP::Conn',
#      'LEVEL' => '-1',
#      'TIME' => 0,
#}, 'Net::XMPP::Debug';

my $xs = XML::Stream->new(
   'style'      =>    'node',
   'debugfh'    =>    undef,
   'debuglevel' =>    '-1',
   'debugtime'  =>    0,
);

isa_ok $xs, 'XML::Stream';

# TODO...

