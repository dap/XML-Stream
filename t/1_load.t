BEGIN {print "1..1\n";}
END {print "not ok 1\n" unless $loaded;}
use XML::Stream;
$loaded = 1;
print "ok 1\n";

