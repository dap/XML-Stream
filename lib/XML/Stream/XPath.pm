##############################################################################
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Library General Public
#  License as published by the Free Software Foundation; either
#  version 2 of the License, or (at your option) any later version.
#
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  Library General Public License for more details.
#
#  You should have received a copy of the GNU Library General Public
#  License along with this library; if not, write to the
#  Free Software Foundation, Inc., 59 Temple Place - Suite 330,
#  Boston, MA  02111-1307, USA.
#
#  Jabber
#  Copyright (C) 1998-1999 The Jabber Team http://jabber.org/
#
##############################################################################

package XML::Stream::XPath;

use 5.006_001;
use strict;
use vars qw($VERSION %FUNCTIONS);

$VERSION = "1.18";

use XML::Stream::XPath::Value;
($XML::Stream::XPath::Value::VERSION < $VERSION) &&
  die("XML::Stream::XPath::Value $VERSION required--this is only version $XML::Stream::XPath::Value::VERSION");

use XML::Stream::XPath::Op;
($XML::Stream::XPath::Op::VERSION < $VERSION) &&
  die("XML::Stream::XPath::Op $VERSION required--this is only version $XML::Stream::XPath::Op::VERSION");

use XML::Stream::XPath::Query;
($XML::Stream::XPath::Query::VERSION < $VERSION) &&
  die("XML::Stream::XPath::Query $VERSION required--this is only version $XML::Stream::XPath::Query::VERSION");


sub AddFunction
{
    my $function = shift;
    my $code = shift;
    if (!defined($code))
    {
        delete($FUNCTIONS{$code});
        return;
    }

    $FUNCTIONS{$function} = $code;
}


1;

