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

package XML::Stream;

=head1 NAME

XML::Stream - Creates and XML Stream connection and parses return data

=head1 SYNOPSIS

  XML::Stream is an attempt at solidifying the use of XML via streaming.

=head1 DESCRIPTION

  This module provides the user with methods to connect to a remote
  server, send a stream of XML to the server, and receive/parse an XML
  stream from the server.  It is primarily based work for the Etherx XML
  router developed by the Jabber Development Team.  For more information
  about this project visit http://etherx.jabber.org/stream/.

  XML::Stream gives the user the ability to define a central callback
  that will be used to handle the tags received from the server.  These
  tags are passed in the format defined at instantiation time.
  the closing tag of an object is seen, the tree is finished and passed
  to the call back function.  What the user does with it from there is up
  to them.

  For a detailed description of how this module works, and about the data
  structure that it returns, please view the source of Stream.pm and
  look at the detailed description at the end of the file.


  NOTE: The parser that XML::Stream::Parser provides, as are most Perl
  parsers, is synchronous.  If you are in the middle of parsing a
  packet and call a user defined callback, the Parser is blocked until
  your callback finishes.  This means you cannot be operating on a
  packet, send out another packet and wait for a response to that packet.
  It will never get to you.  Threading might solve this, but as we all
  know threading in Perl is not quite up to par yet.  This issue will be
  revisted in the future.



=head1 METHODS

  new(debug=>string,       - creates the XML::Stream object.  debug
      debugfh=>FileHandle,   should be set to the path for the debug log
      debuglevel=>0|1|N,     to be written.  If set to "stdout" then the
      debugtime=>0|1,        debug will go there.   Also, you can specify
      style=>string)         a filehandle that already exists byt using
                             debugfh.  debuglevel determines the amount
                             of debug to generate.  0 is the least, 1 is
                             a little more, N is the limit you want.
                             debugtime determines wether a timestamp
                             should be preappended to the entry.  style
                             defines the way the data structure is
                             returned.  The two available styles are:

                               tree - XML::Parser Tree format
                               hash - XML::Stream::Hash format
                               node - XML::Stream::Node format

                             For more information see the respective man
                             pages.

  Connect(hostname=>string,       - opens a tcp connection to the
          port=>integer,            specified server and sends the proper
          to=>string,               opening XML Stream tag.  hostname,
          from=>string,             port, and namespace are required.
          myhostname=>string,       namespaces allows you to use
          namespace=>string,        XML::Stream::Namespace objects.
          namespaced=>array,        to is needed if you want the stream
          connectiontype=>string,   to attribute to be something other
          ssl=>0|1)                 than the hostname you are connecting
                                    to.  from is needed if you want the
                                    stream from attribute to be something
                                    other than the hostname you are
                                    connecting from.  myhostname should
                                    not be needed but if the module
                                    cannot determine your hostname
                                    properly (check the debug log), set
                                    this to the correct value, or if you
                                    want the other side of the  stream to
                                    think that you are someone else.  The
                                    type determines the kind of
                                    connection that is made:
                                      "tcpip"    - TCP/IP (default)
                                      "stdinout" - STDIN/STDOUT
                                      "http"     - HTTP
                                    HTTP recognizes proxies if the ENV
                                    variables http_proxy or https_proxy
                                    are set.  ssl specifies if an SLL
                                    socket should be used for encrypted
                                    communications.  This function
                                    returns the same hash from GetRoot()
                                    below. Make sure you get the SID
                                    (Session ID) since you have to use it
                                    to call most other functions in here.


  OpenFile(string) - opens a filehandle to the argument specified, and
                     pretends that it is a stream.  It will ignore the
                     outer tag, and not check if it was a
                     <stream:stream/>. This is useful for writing a
                     program that has to parse any XML file that is
                     basically made up of small packets (like RDF).

  Disconnect(sid) - sends the proper closing XML tag and closes the
                    specified socket down.

  Process(integer) - waits for data to be available on the socket.  If
                     a timeout is specified then the Process function
                     waits that period of time before returning nothing.
                     If a timeout period is not specified then the
                     function blocks until data is received.  The
                     function returns a hash with session ids as the key,
                     and status values or data as the hash values.

  SetCallBacks(node=>function,   - sets the callback that should be
               update=>function)   called in various situations.  node
                                   is used to handle the data structures
                                   that are built for each top level tag.
                                   Update is used for when Process is
                                   blocking waiting for data, but you
                                   want your original code to be updated.

  GetRoot(sid) - returns the attributes that the stream:stream tag sent
                 by the other end listed in a hash for the specified
                 session.

  GetSock(sid) - returns a pointer to the IO::Socket object for the
                 specified session.

  Send(sid,    - sends the string over the specified connection as is.
       string)   This does no checking if valid XML was sent or not.
                 Best behavior when sending information.

  GetErrorCode(sid) - returns a string for the specified session that
                      will hopefully contain some useful information
                      about why Process or Connect returned an undef
                      to you.

  XPath(node,path) - returns an array of results that match the xpath.
                     node can be any of the three types (Tree, Hash, Node).

=head1 VARIABLES

  $NONBLOCKING - tells the Parser to enter into a nonblocking state.  This
                 might cause some funky behavior since you can get nested
                 callbacks while things are waiting.  1=on, 0=off(default).

=head1 EXAMPLES

  ##########################
  # simple example

  use XML::Stream qw( Tree );

  $stream = new XML::Stream;

  my $status = $stream->Connect(hostname => "jabber.org",
                                port => 5222,
                                namespace => "jabber:client");

  if (!defined($status)) {
    print "ERROR: Could not connect to server\n";
    print "       (",$stream->GetErrorCode(),")\n";
    exit(0);
  }

  while($node = $stream->Process()) {
    # do something with $node
  }

  $stream->Disconnect();


  ###########################
  # example using a handler

  use XML::Stream qw( Tree );

  $stream = new XML::Stream;
  $stream->SetCallBacks(node=>\&noder);
  $stream->Connect(hostname => "jabber.org",
		   port => 5222,
		   namespace => "jabber:client",
		   timeout => undef) || die $!;

  # Blocks here forever, noder is called for incoming
  # packets when they arrive.
  while(defined($stream->Process())) { }

  print "ERROR: Stream died (",$stream->GetErrorCode(),")\n";

  sub noder
  {
    my $sid = shift;
    my $node = shift;
    # do something with $node
  }

=head1 AUTHOR

Tweaked, tuned, and brightness changes by Ryan Eatmon, reatmon@ti.com
in May of 2000.
Colorized, and Dolby Surround sound added by Thomas Charron,
tcharron@jabber.org
By Jeremie in October of 1999 for http://etherx.jabber.org/streams/

=head1 COPYRIGHT

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

require 5.003;
use strict;
use Socket;
use Sys::Hostname;
use IO::Socket;
use IO::Select 1.13;
use FileHandle;
use Carp;
use POSIX;
use Unicode::String;
use vars qw($VERSION $PAC $SSL $NONBLOCKING %HANDLERS);

$VERSION = "1.15";
$NONBLOCKING = 0;

use XML::Stream::Namespace;
($XML::Stream::Namespace::VERSION < $VERSION) &&
  die("XML::Stream::Namespace $VERSION required--this is only version $XML::Stream::Namespace::VERSION");

use XML::Stream::Parser;
($XML::Stream::Parser::VERSION < $VERSION) &&
  die("XML::Stream::Parser $VERSION required--this is only version $XML::Stream::Parser::VERSION");


##############################################################################
#
# Setup the exportable objects
#
##############################################################################
require Exporter;
my @ISA = qw(Exporter);
my @EXPORT_OK = qw(Hash Tree Node);

sub import {
  my $class = shift;

  foreach my $module (@_) {
    eval "use XML::Stream::$module;";
    die($@) if ($@);
    eval "(\$XML::Stream::${module}::VERSION < \$VERSION) && die(\"XML::Stream::$module \$VERSION required--this is only version \$XML::Stream::${module}::VERSION\");";
    die($@) if ($@);
  }
}

$HANDLERS{tree}->{startElement} = \&XML::Stream::Tree::_handle_element;
$HANDLERS{tree}->{endElement}   = \&XML::Stream::Tree::_handle_close;
$HANDLERS{tree}->{characters}   = \&XML::Stream::Tree::_handle_cdata;

$HANDLERS{hash}->{startElement} = \&XML::Stream::Hash::_handle_element;
$HANDLERS{hash}->{endElement}   = \&XML::Stream::Hash::_handle_close;
$HANDLERS{hash}->{characters}   = \&XML::Stream::Hash::_handle_cdata;

$HANDLERS{node}->{startElement} = \&XML::Stream::Node::_handle_element;
$HANDLERS{node}->{endElement}   = \&XML::Stream::Node::_handle_close;
$HANDLERS{node}->{characters}   = \&XML::Stream::Node::_handle_cdata;


sub new {
  my $proto = shift;
  my $self = { };

  bless($self,$proto);

  my %args;
  while($#_ >= 0) { $args{ lc pop(@_) } = pop(@_); }

  $self->{DATASTYLE} = "tree";
  $self->{DATASTYLE} = delete($args{style}) if exists($args{style});

  if ((($self->{DATASTYLE} eq "tree") &&
      !defined($XML::Stream::Tree::VERSION)) ||
      (($self->{DATASTYLE} eq "hash") &&
       !defined($XML::Stream::Hash::VERSION)) ||
      (($self->{DATASTYLE} eq "node") &&
       !defined($XML::Stream::Node::VERSION))
     ) {
    croak("The style that you have chosen was not defined when you \"use\"d the module.\n");
  }

  $self->{DEBUGARGS} = \%args;

  $self->{DEBUGTIME} = 0;
  $self->{DEBUGTIME} = $args{debugtime} if exists($args{debugtime});

  $self->{DEBUGLEVEL} = 0;
  $self->{DEBUGLEVEL} = $args{debuglevel} if exists($args{debuglevel});

  $self->{DEBUGFILE} = "";

  if (exists($args{debugfh}) && ($args{debugfh} ne "")) {
    $self->{DEBUGFILE} = $args{debugfh};
    $self->{DEBUG} = 1;
  }
  if ((exists($args{debugfh}) && ($args{debugfh} eq "")) ||
       (exists($args{debug}) && ($args{debug} ne ""))) {
    $self->{DEBUG} = 1;
    if (lc($args{debug}) eq "stdout") {
      $self->{DEBUGFILE} = new FileHandle(">&STDERR");
      $self->{DEBUGFILE}->autoflush(1);
    } else {
      if (-e $args{debug}) {
	if (-w $args{debug}) {
	  $self->{DEBUGFILE} = new FileHandle(">$args{debug}");
	  $self->{DEBUGFILE}->autoflush(1);
	} else {
	  print "WARNING: debug file ($args{debug}) is not writable by you\n";
	  print "         No debug information being saved.\n";
	  $self->{DEBUG} = 0;
	}
      } else {
	$self->{DEBUGFILE} = new FileHandle(">$args{debug}");
	if (defined($self->{DEBUGFILE})) {
	  $self->{DEBUGFILE}->autoflush(1);
	} else {
	  print "WARNING: debug file ($args{debug}) does not exist \n";
	  print "         and is not writable by you.\n";
	  print "         No debug information being saved.\n";
	  $self->{DEBUG} = 0;
	}
      }
    }
  }

  my $hostname = hostname();
  my $address = gethostbyname($hostname) ||
    die("Cannot resolve $hostname: $!");
  my $fullname = gethostbyaddr($address,AF_INET) || $hostname;

  $self->debug(1,"new: hostname = ($fullname)");

  #---------------------------------------------------------------------------
  # Setup the defaults that the module will work with.
  #---------------------------------------------------------------------------
  $self->{SIDS}->{default}->{hostname} = "";
  $self->{SIDS}->{default}->{port} = "";
  $self->{SIDS}->{default}->{sock} = 0;
  $self->{SIDS}->{default}->{ssl} = (exists($args{ssl}) ? $args{ssl} : 0);
  $self->{SIDS}->{default}->{namespace} = "";
  $self->{SIDS}->{default}->{myhostname} = $fullname;
  $self->{SIDS}->{default}->{derivedhostname} = $fullname;
  $self->{SIDS}->{default}->{id} = "";

  #---------------------------------------------------------------------------
  # We are only going to use one callback, let the user call other callbacks
  # on his own.
  #---------------------------------------------------------------------------
  $self->SetCallBacks(node=>sub { $self->_node(@_) });

  $self->{IDCOUNT} = 0;

  return $self;
}


###########################################################################
#
# debug - prints the arguments to the debug log if debug is turned on.
#
###########################################################################
sub debug {
  return if ($_[1] > $_[0]->{DEBUGLEVEL});
  my $self = shift;
  my ($limit,@args) = @_;
  return if ($self->{DEBUGFILE} eq "");
  my $fh = $self->{DEBUGFILE};
  if ($self->{DEBUGTIME} == 1) {
    my ($sec,$min,$hour) = localtime(time);
    print $fh sprintf("[%02d:%02d:%02d] ",$hour,$min,$sec);
  }
  print $fh "XML::Stream: @args\n";
}


sub Host2SID {
  my $self = shift;
  my $hostname = shift;

  foreach my $sid (keys(%{$self->{SIDS}})) {
    next if ($sid eq "default");
    next if ($sid =~ /^server/);

    return $sid if ($self->{SIDS}->{$sid}->{hostname} eq $hostname);
  }
  return;
}


##############################################################################
#
# Listen - starts the stream by listening on a port for someone to connect,
#          and send the opening stream tag, and then sending a response based
#          on if the received header was correct for this stream.  Server
#          name, port, and namespace are required otherwise we don't know
#          where to listen and what namespace to accept.
#
##############################################################################
sub Listen {
  my $self = shift;
  my %args;
  while($#_ >= 0) { $args{ lc pop(@_) } = pop(@_); }

  my $serverid = "server$args{port}";

  return if exists($self->{SIDS}->{$serverid});

  push(@{$self->{SIDS}->{server}},$serverid);

  foreach my $key (keys(%{$self->{SIDS}->{default}})) {
    $self->{SIDS}->{$serverid}->{$key} = $self->{SIDS}->{default}->{$key};
  }

  foreach my $key (keys(%args)) {
    $self->{SIDS}->{$serverid}->{$key} = $args{$key};
  }

  $self->debug(1,"Listen: start");

  if ($self->{SIDS}->{$serverid}->{namespace} eq "") {
    $self->SetErrorCode($serverid,"Namespace not specified");
    return;
  }

  #---------------------------------------------------------------------------
  # Check some things that we have to know in order get the connection up
  # and running.  Server hostname, port number, namespace, etc...
  #---------------------------------------------------------------------------
  if ($self->{SIDS}->{$serverid}->{hostname} eq "") {
    $self->SetErrorCode("$serverid","Server hostname not specified");
    return;
  }
  if ($self->{SIDS}->{$serverid}->{port} eq "") {
    $self->SetErrorCode("$serverid","Server port not specified");
    return;
  }
  if ($self->{SIDS}->{$serverid}->{myhostname} eq "") {
    $self->{SIDS}->{$serverid}->{myhostname} = $self->{SIDS}->{$serverid}->{derivedhostname};
  }

  #-------------------------------------------------------------------------
  # Open the connection to the listed server and port.  If that fails then
  # abort ourselves and let the user check $! on his own.
  #-------------------------------------------------------------------------

  while($self->{SIDS}->{$serverid}->{sock} == 0) {
    $self->{SIDS}->{$serverid}->{sock} =
      new IO::Socket::INET(LocalHost=>$self->{SIDS}->{$serverid}->{hostname},
			   LocalPort=>$self->{SIDS}->{$serverid}->{port},
			   Reuse=>1,
			   Listen=>10,
			   Proto=>'tcp');
    select(undef,undef,undef,.1);
  }
  $self->{SIDS}->{$serverid}->{status} = 1;
  $self->nonblock($self->{SIDS}->{$serverid}->{sock});
  $self->{SIDS}->{$serverid}->{sock}->autoflush(1);

  $self->{SELECT} =
    new IO::Select($self->{SIDS}->{$serverid}->{sock});
  $self->{SIDS}->{$serverid}->{select} =
    new IO::Select($self->{SIDS}->{$serverid}->{sock});

  $self->{SOCKETS}->{$self->{SIDS}->{$serverid}->{sock}} = "$serverid";

  return $serverid;
}


sub ConnectionAccept {
  my $self = shift;
  my $serverid = shift;

  my $sid = $self->NewSID();

  $self->debug(1,"ConnectionAccept: sid($sid)");

  $self->{SIDS}->{$sid}->{sock} = $self->{SIDS}->{$serverid}->{sock}->accept();

  $self->nonblock($self->{SIDS}->{$sid}->{sock});
  $self->{SIDS}->{$sid}->{sock}->autoflush(1);

  $self->debug(3,"ConnectionAccept: sid($sid) client($self->{SIDS}->{$sid}->{sock}) server($self->{SIDS}->{$serverid}->{sock})");

  $self->{SELECT}->add($self->{SIDS}->{$sid}->{sock});

  #-------------------------------------------------------------------------
  # Create the XML::Stream::Parser and register our callbacks
  #-------------------------------------------------------------------------
  $self->{SIDS}->{$sid}->{parser} =
    new XML::Stream::Parser(%{$self->{DEBUGARGS}},
			    nonblocking=>$NONBLOCKING,
			    sid=>$sid,
			    Handlers=>{
				       startElement=>sub{ $self->_handle_root(@_) },
				       endElement=>sub{ &{$HANDLERS{$self->{DATASTYLE}}->{endElement}}($self,@_) },
				       characters=>sub{ &{$HANDLERS{$self->{DATASTYLE}}->{characters}}($self,@_) },
				      }
			   );

  $self->{SIDS}->{$sid}->{select} =
    new IO::Select($self->{SIDS}->{$sid}->{sock});
  $self->{SIDS}->{$sid}->{connectiontype} = "tcpip";
  $self->{SOCKETS}->{$self->{SIDS}->{$sid}->{sock}} = $sid;

  $self->InitConnection($sid,$serverid);

  #---------------------------------------------------------------------------
  # Grab the init time so that we can check if we get data in the timeout
  # period or not.
  #---------------------------------------------------------------------------
  $self->{SIDS}->{$sid}->{activitytimeout} = time;

  return $sid;
}


sub InitConnection {
  my $self = shift;
  my $sid = shift;
  my $serverid = shift;

  #---------------------------------------------------------------------------
  # Set the default STATUS so that we can keep track of it throughout the
  # session.
  #   1 = no errors
  #   0 = no data has been received yet
  #  -1 = error from handlers
  #  -2 = error but keep the connection alive so that we can send some info.
  #---------------------------------------------------------------------------
  $self->{SIDS}->{$sid}->{status} = 0;

  #---------------------------------------------------------------------------
  # A storage place for when we don't have a callback registered and we need
  # to stockpile the nodes we receive until Process is called and we return
  # them.
  #---------------------------------------------------------------------------
  $self->{SIDS}->{$sid}->{nodes} = ();

  #---------------------------------------------------------------------------
  # If there is an error on the stream, then we need a place to indicate that.
  #---------------------------------------------------------------------------
  $self->{SIDS}->{$sid}->{streamerror} = "";

  #---------------------------------------------------------------------------
  # Grab the init time so that we can keep the connection alive by sending " "
  #---------------------------------------------------------------------------
  $self->{SIDS}->{$sid}->{keepalive} = time;

  #---------------------------------------------------------------------------
  # Keep track of the "server" we are connected to so we can check stuff
  # later.
  #---------------------------------------------------------------------------
  $self->{SIDS}->{$sid}->{serverid} = $serverid;

  #---------------------------------------------------------------------------
  # First acitivty is the connection... duh. =)
  #---------------------------------------------------------------------------
  $self->MarkActivity($sid);
}


sub Respond {
  my $self = shift;
  my $sid = shift;
  my $serverid = $self->{SIDS}->{$sid}->{serverid};

  if ($self->GetRoot($sid)->{xmlns} ne $self->{SIDS}->{$serverid}->{namespace}) {
    $self->Send($sid,"<stream:error>Invalid namespace specified.</stream:error>");
    $self->{SIDS}->{$sid}->{sock}->flush();
    select(undef,undef,undef,1);
    $self->Disconnect($sid);
  }

  #---------------------------------------------------------------------------
  # Next, we build the opening handshake.
  #---------------------------------------------------------------------------
  my $stream = '<?xml version="1.0"?>';
  $stream .= '<stream:stream ';
  $stream .= 'xmlns:stream="http://etherx.jabber.org/streams" ';
  $stream .= 'xmlns="'.$self->{SIDS}->{$serverid}->{namespace}.'" ';
  $stream .= 'from="'.$self->{SIDS}->{$serverid}->{hostname}.'" ' unless exists($self->{SIDS}->{$serverid}->{from});
  $stream .= 'from="'.$self->{SIDS}->{$serverid}->{from}.'" ' if exists($self->{SIDS}->{$serverid}->{from});
  $stream .= 'to="'.$self->GetRoot($sid)->{from}.'" ';
  $stream .= 'id="'.$sid.'" ';
  my $namespaces = "";
  my $ns;
  foreach $ns (@{$self->{SIDS}->{$serverid}->{namespaces}}) {
    $namespaces .= " ".$ns->GetStream();
    $stream .= " ".$ns->GetStream();
  }
  $stream .= ">";

  #---------------------------------------------------------------------------
  # Then we send the opening handshake.
  #---------------------------------------------------------------------------
  $self->Send($sid,$stream);
  delete($self->{SIDS}->{$sid}->{activitytimeout});
}


sub nonblock {
  my $self = shift;
  my $socket = shift;
  my $flags;

  $flags = fcntl($socket, F_GETFL, 0)
    or die "Can't get flags for socket: $!\n";
  fcntl($socket, F_SETFL, $flags | O_NONBLOCK)
    or die "Can't make socket nonblocking: $!\n";
}


##############################################################################
#
# Connect - starts the stream by connecting to the server, sending the opening
#           stream tag, and then waiting for a response and verifying that it
#           is correct for this stream.  Server name, port, and namespace are
#           required otherwise we don't know where to send the stream to...
#
##############################################################################
sub Connect {
  my $self = shift;
  my $timeout = exists $_{timeout} ? delete $_{timeout} : "";
  foreach my $key (keys(%{$self->{SIDS}->{default}})) {
    $self->{SIDS}->{newconnection}->{$key} = $self->{SIDS}->{default}->{$key};
  }
  while($#_ >= 0) { $self->{SIDS}->{newconnection}->{ lc pop(@_) } = pop(@_); }

  $self->{SIDS}->{newconnection}->{connectiontype} = "tcpip"
    unless exists($self->{SIDS}->{newconnection}->{connectiontype});

  $self->debug(1,"Connect: type($self->{SIDS}->{newconnection}->{connectiontype})");

  if ($self->{SIDS}->{newconnection}->{namespace} eq "") {
    $self->SetErrorCode("newconnection","Namespace not specified");
    return;
  }

  $self->InitConnection("newconnection","newconnection");

  #---------------------------------------------------------------------------
  # TCP/IP
  #---------------------------------------------------------------------------
  if ($self->{SIDS}->{newconnection}->{connectiontype} eq "tcpip") {
    #-------------------------------------------------------------------------
    # Check some things that we have to know in order get the connection up
    # and running.  Server hostname, port number, namespace, etc...
    #-------------------------------------------------------------------------
    if ($self->{SIDS}->{newconnection}->{hostname} eq "") {
      $self->SetErrorCode("newconnection","Server hostname not specified");
      return;
    }
    if ($self->{SIDS}->{newconnection}->{port} eq "") {
      $self->SetErrorCode("newconnection","Server port not specified");
      return;
    }
    if ($self->{SIDS}->{newconnection}->{myhostname} eq "") {
      $self->{SIDS}->{newconnection}->{myhostname} = $self->{SIDS}->{newconnection}->{derivedhostname};
    }

    #-------------------------------------------------------------------------
    # Open the connection to the listed server and port.  If that fails then
    # abort ourselves and let the user check $! on his own.
    #-------------------------------------------------------------------------
    $self->{SIDS}->{newconnection}->{sock} =
      new IO::Socket::INET(PeerAddr=>$self->{SIDS}->{newconnection}->{hostname},
			   PeerPort=>$self->{SIDS}->{newconnection}->{port},
			   Proto=>"tcp");
    return unless $self->{SIDS}->{newconnection}->{sock};

    if ($self->{SIDS}->{newconnection}->{ssl} == 1) {
      $self->debug(1,"Connect: Convert normal socket to SSL");
      $self->debug(1,"Connect: sock($self->{SIDS}->{newconnection}->{sock})");
      $self->LoadSSL();
      $self->{SIDS}->{newconnection}->{sock} =
	IO::Socket::SSL::socketToSSL($self->{SIDS}->{newconnection}->{sock},
				     {SSL_verify_mode=>0x00});
      $self->debug(1,"Connect: ssl_sock($self->{SIDS}->{newconnection}->{sock})");
      $self->debug(1,"Connect: SSL: We are secure") if ($self->{SIDS}->{newconnection}->{sock});
    }
    return unless $self->{SIDS}->{newconnection}->{sock};
  }

  #---------------------------------------------------------------------------
  # STDIN/OUT
  #---------------------------------------------------------------------------
  if ($self->{SIDS}->{newconnection}->{connectiontype} eq "stdinout") {
    $self->{SIDS}->{newconnection}->{sock} =
      new FileHandle(">&STDOUT");
  }	

  #---------------------------------------------------------------------------
  # HTTP
  #---------------------------------------------------------------------------
  if ($self->{SIDS}->{newconnection}->{connectiontype} eq "http") {
    #-------------------------------------------------------------------------
    # Check some things that we have to know in order get the connection up
    # and running.  Server hostname, port number, namespace, etc...
    #-------------------------------------------------------------------------
    if ($self->{SIDS}->{newconnection}->{hostname} eq "") {
      $self->SetErrorCode("newconnection","Server hostname not specified");
      return;
    }
    if ($self->{SIDS}->{newconnection}->{port} eq "") {
      $self->SetErrorCode("newconnection","Server port not specified");
      return;
    }
    if ($self->{SIDS}->{newconnection}->{myhostname} eq "") {
      $self->{SIDS}->{newconnection}->{myhostname} = $self->{SIDS}->{newconnection}->{derivedhostname};
    }

    if (!defined($PAC)) {
      eval("use HTTP::ProxyAutoConfig;");
      if ($@) {
	$PAC = 0;
      } else {
	require HTTP::ProxyAutoConfig;
	$PAC = new HTTP::ProxyAutoConfig();
      }
    }

    if ($PAC eq "0") {
      if (exists($ENV{"http_proxy"})) {
	my($host,$port) = ($ENV{"http_proxy"} =~ /^(\S+)\:(\d+)$/);
	$self->{SIDS}->{newconnection}->{httpproxyhostname} = $host;
	$self->{SIDS}->{newconnection}->{httpproxyport} = $port;
	$self->{SIDS}->{newconnection}->{httpproxyhostname} =~ s/^http\:\/\///;
      }
      if (exists($ENV{"https_proxy"})) {
	my($host,$port) = ($ENV{"https_proxy"} =~ /^(\S+)\:(\d+)$/);
	$self->{SIDS}->{newconnection}->{httpsproxyhostname} = $host;
	$self->{SIDS}->{newconnection}->{httpsproxyport} = $port;
	$self->{SIDS}->{newconnection}->{httpsproxyhostname} =~ s/^https?\:\/\///;
      }
    } else {
      my $proxy = $PAC->FindProxy("http://".$self->{SIDS}->{newconnection}->{hostname});
      if ($proxy ne "DIRECT") {
	($self->{SIDS}->{newconnection}->{httpproxyhostname},$self->{SIDS}->{newconnection}->{httpproxyport}) = ($proxy =~ /^PROXY ([^:]+):(\d+)$/);
      }

      $proxy = $PAC->FindProxy("https://".$self->{SIDS}->{newconnection}->{hostname});

      if ($proxy ne "DIRECT") {
	($self->{SIDS}->{newconnection}->{httpsproxyhostname},$self->{SIDS}->{newconnection}->{httpsproxyport}) = ($proxy =~ /^PROXY ([^:]+):(\d+)$/);
      }
    }

    $self->debug(1,"Connect: http_proxy($self->{SIDS}->{newconnection}->{httpproxyhostname}:$self->{SIDS}->{newconnection}->{httpproxyport})")
      if (exists($self->{SIDS}->{newconnection}->{httpproxyhostname}) &&
	  defined($self->{SIDS}->{newconnection}->{httpproxyhostname}) &&
	  exists($self->{SIDS}->{newconnection}->{httpproxyport}) &&
	  defined($self->{SIDS}->{newconnection}->{httpproxyport}));
    $self->debug(1,"Connect: https_proxy($self->{SIDS}->{newconnection}->{httpsproxyhostname}:$self->{SIDS}->{newconnection}->{httpsproxyport})")
      if (exists($self->{SIDS}->{newconnection}->{httpsproxyhostname}) &&
	  defined($self->{SIDS}->{newconnection}->{httpsproxyhostname}) &&
	  exists($self->{SIDS}->{newconnection}->{httpsproxyport}) &&
	  defined($self->{SIDS}->{newconnection}->{httpsproxyport}));

    #-------------------------------------------------------------------------
    # Open the connection to the listed server and port.  If that fails then
    # abort ourselves and let the user check $! on his own.
    #-------------------------------------------------------------------------
    my $connect = "CONNECT $self->{SIDS}->{newconnection}->{hostname}:$self->{SIDS}->{newconnection}->{port} HTTP/1.1\r\nHost: $self->{SIDS}->{newconnection}->{hostname}\r\n\r\n";
    my $put = "PUT http://$self->{SIDS}->{newconnection}->{hostname}:$self->{SIDS}->{newconnection}->{port} HTTP/1.1\r\nHost: $self->{SIDS}->{newconnection}->{hostname}\r\nProxy-Connection: Keep-Alive\r\n\r\n";

    my $connected = 0;
    #-------------------------------------------------------------------------
    # Combo #0 - The user didn't specify a proxy
    #-------------------------------------------------------------------------
    if (!exists($self->{SIDS}->{newconnection}->{httpproxyhostname}) &&
	!exists($self->{SIDS}->{newconnection}->{httpsproxyhostname})) {

      $self->debug(1,"Connect: Combo #0: User did not specify a proxy... connecting DIRECT");

      $self->debug(1,"Connect: Combo #0: Create normal socket");
      $self->{SIDS}->{newconnection}->{sock} =
	new IO::Socket::INET(PeerAddr=>$self->{SIDS}->{newconnection}->{hostname},
			     PeerPort=>$self->{SIDS}->{newconnection}->{port},
			     Proto=>"tcp");
      $connected = defined($self->{SIDS}->{newconnection}->{sock});
      $self->debug(1,"Connect: Combo #0: connected($connected)");
    }

    #-------------------------------------------------------------------------
    # Combo #1 - PUT through http_proxy
    #-------------------------------------------------------------------------
    if (!$connected &&
	exists($self->{SIDS}->{newconnection}->{httpproxyhostname}) &&
	($self->{SIDS}->{newconnection}->{ssl} == 0)) {

      $self->debug(1,"Connect: Combo #1: PUT through http_proxy");
      $self->{SIDS}->{newconnection}->{sock} =
	new IO::Socket::INET(PeerAddr=>$self->{SIDS}->{newconnection}->{httpproxyhostname},
			     PeerPort=>$self->{SIDS}->{newconnection}->{httpproxyport},
			     Proto=>"tcp");
      $connected = defined($self->{SIDS}->{newconnection}->{sock});
      $self->debug(1,"Connect: Combo #1: connected($connected)");
      if ($connected) {
	$self->{SIDS}->{newconnection}->{sock}->syswrite($put,length($put),0);
	my $buff;
	$self->{SIDS}->{newconnection}->{sock}->sysread($buff,4*POSIX::BUFSIZ);
	my ($code) = ($buff =~ /^\S+\s+(\S+)\s+/);
	$self->debug(1,"Connect: Combo #1: buff($buff)");
	$connected = 0 if ($code !~ /2\d\d/);
      }
      $self->debug(1,"Connect: Combo #1: connected($connected)");
    }
    #-------------------------------------------------------------------------
    # Combo #2 - CONNECT through http_proxy
    #-------------------------------------------------------------------------
    if (!$connected &&
	exists($self->{SIDS}->{newconnection}->{httpproxyhostname}) &&
	($self->{SIDS}->{newconnection}->{ssl} == 0)) {

      $self->debug(1,"Connect: Combo #2: CONNECT through http_proxy");
      $self->{SIDS}->{newconnection}->{sock} =
	new IO::Socket::INET(PeerAddr=>$self->{SIDS}->{newconnection}->{httpproxyhostname},
			     PeerPort=>$self->{SIDS}->{newconnection}->{httpproxyport},
			     Proto=>"tcp");
      $connected = defined($self->{SIDS}->{newconnection}->{sock});
      $self->debug(1,"Connect: Combo #2: connected($connected)");
      if ($connected) {
	$self->{SIDS}->{newconnection}->{sock}->syswrite($connect,length($connect),0);
	my $buff;
	$self->{SIDS}->{newconnection}->{sock}->sysread($buff,4*POSIX::BUFSIZ);
	my ($code) = ($buff =~ /^\S+\s+(\S+)\s+/);
	$self->debug(1,"Connect: Combo #2: buff($buff)");
	$connected = 0 if ($code !~ /2\d\d/);
      }
      $self->debug(1,"Connect: Combo #2: connected($connected)");
    }

    #-------------------------------------------------------------------------
    # Combo #3 - CONNECT through https_proxy
    #-------------------------------------------------------------------------
    if (!$connected &&
	exists($self->{SIDS}->{newconnection}->{httpsproxyhostname})) {
      $self->debug(1,"Connect: Combo #3: CONNECT through https_proxy");
      $self->{SIDS}->{newconnection}->{sock} =
	new IO::Socket::INET(PeerAddr=>$self->{SIDS}->{newconnection}->{httpsproxyhostname},
			     PeerPort=>$self->{SIDS}->{newconnection}->{httpsproxyport},
			     Proto=>"tcp");
      $connected = defined($self->{SIDS}->{newconnection}->{sock});
      $self->debug(1,"Connect: Combo #3: connected($connected)");
      if ($connected) {
	$self->{SIDS}->{newconnection}->{sock}->syswrite($connect,length($connect),0);
	my $buff;
	$self->{SIDS}->{newconnection}->{sock}->sysread($buff,4*POSIX::BUFSIZ);
	my ($code) = ($buff =~ /^\S+\s+(\S+)\s+/);
	$self->debug(1,"Connect: Combo #3: buff($buff)");
	$connected = 0 if ($code !~ /2\d\d/);
      }
      $self->debug(1,"Connect: Combo #3: connected($connected)");
    }

    #-------------------------------------------------------------------------
    # We have failed
    #-------------------------------------------------------------------------
    if (!$connected) {
      $self->debug(1,"Connect: No connection... I have failed... I.. must... end it all...");
      $self->SetErrorCode("newconnection","Unable to open a connection to destination.  Please check your http_proxy and/or https_proxy environment variables.");
      return;
    }

    return unless $self->{SIDS}->{newconnection}->{sock};

    $self->debug(1,"Connect: We are connected");

    if (($self->{SIDS}->{newconnection}->{ssl} == 1) &&
	(ref($self->{SIDS}->{newconnection}->{sock}) eq "IO::Socket::INET")) {
      $self->debug(1,"Connect: Convert normal socket to SSL");
      $self->debug(1,"Connect: sock($self->{SIDS}->{newconnection}->{sock})");
      $self->LoadSSL();
      $self->{SIDS}->{newconnection}->{sock} =
	IO::Socket::SSL::socketToSSL($self->{SIDS}->{newconnection}->{sock},
				     {SSL_verify_mode=>0x00});
      $self->debug(1,"Connect: ssl_sock($self->{SIDS}->{newconnection}->{sock})");
      $self->debug(1,"Connect: SSL: We are secure") if ($self->{SIDS}->{newconnection}->{sock});
    }
    return unless $self->{SIDS}->{newconnection}->{sock};
  }

  $self->debug(1,"Connect: Got a connection");

  $self->{SIDS}->{newconnection}->{sock}->autoflush(1);

  #---------------------------------------------------------------------------
  # Next, we build the opening handshake.
  #---------------------------------------------------------------------------
  my $stream;
  $stream .= '<?xml version="1.0"?>';
  $stream .= '<stream:stream ';
  $stream .= 'xmlns:stream="http://etherx.jabber.org/streams" ';
  $stream .= 'xmlns="'.$self->{SIDS}->{newconnection}->{namespace}.'" ';
  if (($self->{SIDS}->{newconnection}->{connectiontype} eq "tcpip") ||
      ($self->{SIDS}->{newconnection}->{connectiontype} eq "http")) {
    $stream .= 'to="'.$self->{SIDS}->{newconnection}->{hostname}.'" ' unless exists($self->{SIDS}->{newconnection}->{to});
    $stream .= 'to="'.$self->{SIDS}->{newconnection}->{to}.'" ' if exists($self->{SIDS}->{newconnection}->{to});
    $stream .= 'from="'.$self->{SIDS}->{newconnection}->{myhostname}.'" ' if (!exists($self->{SIDS}->{newconnection}->{from}) && ($self->{SIDS}->{newconnection}->{myhostname} ne ""));
    $stream .= 'from="'.$self->{SIDS}->{newconnection}->{from}.'" ' if exists($self->{SIDS}->{newconnection}->{from});
    $stream .= 'id="'.$self->{SIDS}->{newconnection}->{id}.'"' if (exists($self->{SIDS}->{newconnection}->{id}) && ($self->{SIDS}->{newconnection}->{id} ne ""));
    my $namespaces = "";
    my $ns;
    foreach $ns (@{$self->{SIDS}->{newconnection}->{namespaces}}) {
      $namespaces .= " ".$ns->GetStream();
      $stream .= " ".$ns->GetStream();
    }
  }
  $stream .= ">";

  #---------------------------------------------------------------------------
  # Create the XML::Stream::Parser and register our callbacks
  #---------------------------------------------------------------------------
  $self->{SIDS}->{newconnection}->{parser} =
    new XML::Stream::Parser(%{$self->{DEBUGARGS}},
			    nonblocking=>$NONBLOCKING,
			    sid=>"newconnection",
			    Handlers=>{
				       startElement=>sub{ $self->_handle_root(@_) },
				       endElement=>sub{ &{$HANDLERS{$self->{DATASTYLE}}->{endElement}}($self,@_) },
				       characters=>sub{ &{$HANDLERS{$self->{DATASTYLE}}->{characters}}($self,@_) },
				      }
			   );

  $self->{SIDS}->{newconnection}->{select} =
    new IO::Select($self->{SIDS}->{newconnection}->{sock});

  if (($self->{SIDS}->{newconnection}->{connectiontype} eq "tcpip") ||
      ($self->{SIDS}->{newconnection}->{connectiontype} eq "http")) {
    $self->{SELECT} = new IO::Select($self->{SIDS}->{newconnection}->{sock});
    $self->{SOCKETS}->{$self->{SIDS}->{newconnection}->{sock}} = "newconnection";
  }

  if ($self->{SIDS}->{newconnection}->{connectiontype} eq "stdinout") {
    $self->{SELECT} = new IO::Select(*STDIN);
    $self->{SOCKETS}->{$self->{SIDS}->{newconnection}->{sock}} = "newconnection";
    $self->{SOCKETS}->{*STDIN} = "newconnection";
    $self->{SIDS}->{newconnection}->{select}->add(*STDIN);
  }

  $self->{SIDS}->{newconnection}->{status} = 0;

  #---------------------------------------------------------------------------
  # Then we send the opening handshake.
  #---------------------------------------------------------------------------
  $self->Send("newconnection",$stream) || return;

  #---------------------------------------------------------------------------
  # Before going on let's make sure that the server responded with a valid
  # root tag and that the stream is open.
  #---------------------------------------------------------------------------
  my $buff = "";
  my $timeStart = time();
  while($self->{SIDS}->{newconnection}->{status} == 0) {
    $self->debug(5,"Connect: can_read(",join(",",$self->{SIDS}->{newconnection}->{select}->can_read(0)),")");
    if ($self->{SIDS}->{newconnection}->{select}->can_read(0)) {
      $self->{SIDS}->{newconnection}->{status} = -1
	unless defined($buff = $self->Read("newconnection"));
      return unless($self->{SIDS}->{newconnection}->{status} == 0);
      return unless($self->ParseStream("newconnection",$buff) == 1);
    } else {
      if ($timeout ne "") {
	if ($timeout <= (time() - $timeStart)) {
	  $self->SetErrorCode("newconnection","Timeout limit reached");
	  return;
	}
      }
    }

    return if($self->{SIDS}->{newconnection}->{select}->has_exception(0));
  }
  return if($self->{SIDS}->{newconnection}->{status} != 1);

  $self->debug(3,"Connect: status($self->{SIDS}->{newconnection}->{status})");

  my $sid = $self->GetRoot("newconnection")->{id};
  foreach my $key (keys(%{$self->{SIDS}->{newconnection}})) {
    $self->{SIDS}->{$sid}->{$key} = $self->{SIDS}->{newconnection}->{$key};
  }
  $self->{SIDS}->{$sid}->{parser}->setSID($sid);

  if (($self->{SIDS}->{newconnection}->{connectiontype} eq "tcpip") ||
      ($self->{SIDS}->{newconnection}->{connectiontype} eq "http")) {
    $self->{SOCKETS}->{$self->{SIDS}->{newconnection}->{sock}} = $sid;
  }

  if ($self->{SIDS}->{newconnection}->{connectiontype} eq "stdinout") {
    $self->{SOCKETS}->{$self->{SIDS}->{newconnection}->{sock}} = $sid;
    $self->{SOCKETS}->{*STDIN} = $sid;
  }

  delete($self->{SIDS}->{newconnection});

  return $self->GetRoot($sid);
}


##############################################################################
#
# Disconnect - sends the closing XML tag and shuts down the socket.
#
##############################################################################
sub Disconnect {
  my $self = shift;
  my $sid = shift;

  $self->Send($sid,"</stream:stream>");
  close($self->{SIDS}->{$sid}->{sock})
    if (($self->{SIDS}->{$sid}->{connectiontype} eq "tcpip") ||
	($self->{SIDS}->{$sid}->{connectiontype} eq "http"));
  delete($self->{SOCKETS}->{$self->{SIDS}->{$sid}->{sock}});
  foreach my $key (keys(%{$self->{SIDS}->{$sid}})) {
    delete($self->{SIDS}->{$sid}->{$key});
  }
  delete($self->{SIDS}->{$sid});
}


##############################################################################
#
# OpenFile - starts the stream by opening a file and setting it up so that
#            Process reads from the filehandle to get the incoming stream.
#
##############################################################################
sub OpenFile {
  my $self = shift;
  my $file = shift;

  $self->debug(1,"OpenFile: file($file)");

  $self->{SIDS}->{newconnection}->{connectiontype} = "file";

  $self->{SIDS}->{newconnection}->{sock} = new FileHandle($file);
  $self->{SIDS}->{newconnection}->{sock}->autoflush(1);

  #---------------------------------------------------------------------------
  # Create the XML::Stream::Parser and register our callbacks
  #---------------------------------------------------------------------------
  $self->{SIDS}->{newconnection}->{parser} =
    new XML::Stream::Parser(%{$self->{DEBUGARGS}},
			    nonblocking=>$NONBLOCKING,
			    sid=>"newconnection",
			    Handlers=>{
				       startElement=>sub{ $self->_handle_root(@_) },
				       endElement=>sub{ &{$HANDLERS{$self->{DATASTYLE}}->{endElement}}($self,@_) },
				       characters=>sub{ &{$HANDLERS{$self->{DATASTYLE}}->{characters}}($self,@_) },
				      }
			   );

  $self->{SIDS}->{newconnection}->{select} =
    new IO::Select($self->{SIDS}->{newconnection}->{sock});

  $self->{SELECT} = new IO::Select($self->{SIDS}->{newconnection}->{sock});

  $self->{SIDS}->{newconnection}->{status} = 0;

  my $buff = "";
  my $timeStart = time();
  while($self->{SIDS}->{newconnection}->{status} == 0) {
    $self->debug(5,"OpenFile: can_read(",join(",",$self->{SIDS}->{newconnection}->{select}->can_read(0)),")");
    if ($self->{SIDS}->{newconnection}->{select}->can_read(0)) {
      $self->{SIDS}->{newconnection}->{status} = -1
	unless defined($buff = $self->Read("newconnection"));
      return unless($self->{SIDS}->{newconnection}->{status} == 0);
      return unless($self->ParseStream("newconnection",$buff) == 1);
    }

    return if($self->{SIDS}->{newconnection}->{select}->has_exception(0));
  }
  return if($self->{SIDS}->{newconnection}->{status} != 1);


  my $sid = $self->NewSID();
  foreach my $key (keys(%{$self->{SIDS}->{newconnection}})) {
    $self->{SIDS}->{$sid}->{$key} = $self->{SIDS}->{newconnection}->{$key};
  }
  $self->{SIDS}->{$sid}->{parser}->setSID($sid);

  $self->{SOCKETS}->{$self->{SIDS}->{newconnection}->{sock}} = $sid;

  delete($self->{SIDS}->{newconnection});

  return $sid;
}


##############################################################################
#
# Process - checks for data on the socket and returns a status code depending
#           on if there was data or not.  If a timeout is not defined in the
#           call then the timeout defined in Connect() is used.  If a timeout
#           of 0 is used then the call blocks until it gets some data,
#           otherwise it returns after the timeout period.
#
##############################################################################
# checks for data on the socket, uses timeout passed to Connect()
sub Process {
  my $self = shift;
  my($timeout) = @_;
  $timeout = "" if !defined($timeout);

  $self->debug(4,"Process: timeout($timeout)");
  #---------------------------------------------------------------------------
  # We need to keep track of what's going on in the function and tell the
  # outside world about it so let's return something useful.  We track this
  # information based on sid:
  #    -1    connection closed and error
  #     0    connection open but no data received.
  #     1    connection open and data received.
  #   array  connection open and the data that has been collected
  #          over time (No CallBack specified)
  #---------------------------------------------------------------------------
  my %status;
  foreach my $sid (keys(%{$self->{SIDS}})) {
    next if ($sid eq "default");
    $self->debug(5,"Process: initialize sid($sid) status to 0");
    $status{$sid} = 0;
  }

  #---------------------------------------------------------------------------
  # Either block until there is data and we have parsed it all, or wait a
  # certain period of time and then return control to the user.
  #---------------------------------------------------------------------------
  my $block = 1;
  my $timeStart = time();
  while($block == 1) {
    $self->debug(4,"Process: let's wait for data");
    $self->debug(5,"Process: can_read(",$self->{SELECT}->can_read(0),")");
    foreach my $connection ($self->{SELECT}->can_read(0)) {

      $self->debug(4,"Process: connection($connection)");
      $self->debug(4,"Process: sid($self->{SOCKETS}->{$connection})");
      $self->debug(4,"Process: connection_status($self->{SIDS}->{$self->{SOCKETS}->{$connection}}->{status})");

      next unless (($self->{SIDS}->{$self->{SOCKETS}->{$connection}}->{status} == 1) ||
		   exists($self->{SIDS}->{$self->{SOCKETS}->{$connection}}->{activitytimeout}));

      my $processit = 1;
      if (exists($self->{SIDS}->{server})) {
	foreach my $serverid (@{$self->{SIDS}->{server}}) {
	  if (exists($self->{SIDS}->{$serverid}->{sock}) &&
	      ($connection == $self->{SIDS}->{$serverid}->{sock})) {
	    my $sid = $self->ConnectionAccept($serverid);
	    $status{$sid} = 0;
	    $processit = 0;
	    last;
	  }
	}
      }
      if ($processit == 1) {
	my $sid = $self->{SOCKETS}->{$connection};
	$self->debug(4,"Process: there's something to read");
	$self->debug(4,"Process: connection($connection) sid($sid)");
	my $buff;
	$self->debug(4,"Process: read");
	$status{$sid} = 1;
	$self->{SIDS}->{$sid}->{status} = -1
	  if (!defined($buff = $self->Read($sid)));
	$buff = "" unless defined($buff);
	$self->debug(4,"Process: connection_status($self->{SIDS}->{$sid}->{status})");
	$status{$sid} = -1 unless($self->{SIDS}->{$sid}->{status} == 1);
	$self->debug(4,"Process: parse($buff)");
	$status{$sid} = -1 unless($self->ParseStream($sid,$buff) == 1);
      }
      $block = 0;
    }

    if ($timeout ne "") {
      if ($timeout <= (time - $timeStart)) {
	$block = 0;
      } else {
	select(undef,undef,undef,.25);
      }
    } else {
      select(undef,undef,undef,.25) if ($block == 1);
    }
    $self->debug(4,"Process: timeout($timeout)");

    if (exists($self->{CB}->{update})) {
      $self->debug(4,"Process: Calling user defined update function");
      &{$self->{CB}->{update}}();
    }

    $block = 1 if $self->{SELECT}->can_read(0);
    #-------------------------------------------------------------------------
    # Check for connections that need to be kept alive
    #-------------------------------------------------------------------------
    $self->debug(4,"Process: check for keepalives");
    foreach my $sid (keys(%{$self->{SIDS}})) {
      next if ($sid eq "default");
      next if ($sid =~ /^server/);
      if ((time - $self->{SIDS}->{$sid}->{keepalive}) > 60) {
	$self->IgnoreActivity($sid,1);
	$self->Send($sid," ");
	$self->IgnoreActivity($sid,0);
      }

    }
    #-------------------------------------------------------------------------
    # Check for connections that have timed out.
    #-------------------------------------------------------------------------
    $self->debug(4,"Process: check for timeouts");
    foreach my $sid (keys(%{$self->{SIDS}})) {
      next if ($sid eq "default");
      next if ($sid =~ /^server/);
      $self->debug(4,"Process: sid($sid) time(",time,") timeout($self->{SIDS}->{$sid}->{activitytimeout})") if exists($self->{SIDS}->{$sid}->{activitytimeout});
      $self->debug(4,"Process: sid($sid) time(",time,") timeout(undef)") unless exists($self->{SIDS}->{$sid}->{activitytimeout});
      $self->Respond($sid)
	if (exists($self->{SIDS}->{$sid}->{activitytimeout}) &&
	    defined($self->GetRoot($sid)));
      $self->Disconnect($sid)
	if (exists($self->{SIDS}->{$sid}->{activitytimeout}) &&
	    ((time - $self->{SIDS}->{$sid}->{activitytimeout}) > 10) &&
	    ($self->{SIDS}->{$sid}->{status} != 1));
    }


    #-------------------------------------------------------------------------
    # If any of the connections have status == -1 then return so that the user
    # can handle it.
    #-------------------------------------------------------------------------
    foreach my $connection (keys(%status)) {
      if ($status{$connection} == -1) {
	$self->debug(4,"Process: sid($connection) is broken... let's tell someone and watch it hit the fan... =)");
	$block = 0;
      }
    }

    $self->debug(4,"Process: block($block)");
  }

  #---------------------------------------------------------------------------
  # If the Select has an error then shut this party down.
  #---------------------------------------------------------------------------
  foreach my $connection ($self->{SELECT}->has_exception(0)) {
    $self->debug(4,"Process: has_exception sid($self->{SOCKETS}->{$connection})");
    $status{$self->{SOCKETS}->{$connection}} = -1;
  }

  #---------------------------------------------------------------------------
  # If there are data structures that have not been collected return
  # those, otherwise return the status which indicates if nodes were read or
  # not.
  #---------------------------------------------------------------------------
  foreach my $sid (keys(%status)) {
    $status{$sid} = shift @{$self->{SIDS}->{$sid}->{nodes}}
      if (($status{$sid} == 1) &&
	  ($#{$self->{SIDS}->{$sid}->{nodes}} > -1));
  }

  return %status;
}


##############################################################################
#
# ParseStream - takes the incoming stream and makes sure that only full
#               XML tags gets passed to the parser.  If a full tag has not
#               read yet, then the Stream saves the incomplete part and
#               sends the rest to the parser.
#
##############################################################################
sub ParseStream {
  my $self = shift;
  my $sid = shift;
  my $stream = shift;

  $stream = "" unless defined($stream);

  $self->debug(3,"ParseStream: sid($sid) stream($stream)");

  $self->{SIDS}->{$sid}->{parser}->parse($stream);

  if (defined($self->{SIDS}->{$sid}->{streamerror}) &&
      ($self->{SIDS}->{$sid}->{streamerror} ne "")) {
    $self->debug(3,"ParseStream: ERROR($self->{SIDS}->{$sid}->{streamerror})");
    $self->SetErrorCode($sid,$self->{SIDS}->{$sid}->{streamerror});
    return 0;
  }

  return 1;
}


##############################################################################
#
# NewSID - returns a session ID to send to an incoming stream in the return
#          header.  By default it just increments a counter and returns that,
#          or you can define a function and set it using the SetCallBacks
#          function.
#
##############################################################################
sub NewSID {
  my $self = shift;
  return &{$self->{CB}->{sid}}() if (exists($self->{CB}->{sid}) &&
				     defined($self->{CB}->{sid}));
  return $$.time.$self->{IDCOUNT}++;
}


###########################################################################
#
# SetCallBacks - Takes a hash with top level tags to look for as the keys
#                and pointers to functions as the values.
#
###########################################################################
sub SetCallBacks {
  my $self = shift;
  while($#_ >= 0) {
    my $func = pop(@_);
    my $tag = pop(@_);
    if (($tag eq "node") && !defined($func)) {
      $self->SetCallBacks(node=>sub { $self->_node(@_) });
    } else {
      $self->debug(1,"SetCallBacks: tag($tag) func($func)");
      $self->{CB}->{$tag} = $func;
    }
  }
}


##############################################################################
#
# GetRoot - returns the hash of attributes for the root <stream:stream/> tag
#           so that any attributes returned can be accessed.  from and any
#           xmlns:foobar might be important.
#
##############################################################################
sub GetRoot {
  my $self = shift;
  my $sid = shift;
  return unless exists($self->{SIDS}->{$sid}->{root});
  return $self->{SIDS}->{$sid}->{root};
}


##############################################################################
#
# GetSock - returns the Socket so that an outside function can access it if
#           desired.
#
##############################################################################
sub GetSock {
  my $self = shift;
  my $sid = shift;
  return $self->{SIDS}->{$sid}->{sock};
}


##############################################################################
#
# IgnoreActivity - Takes the data string and sends it to the server
#
##############################################################################
sub IgnoreActivity {
  my $self = shift;
  my $sid = shift;
  my $ignoreActivity = shift;
  $ignoreActivity = 1 unless defined($ignoreActivity);

  $self->debug(1,"IgnoreActivity: ignoreActivity($ignoreActivity)");
  $self->debug(3,"IgnoreActivity: sid($sid)");

  $self->{SIDS}->{$sid}->{ignoreActivity} = $ignoreActivity;
}


##############################################################################
#
# LastActivity - Takes the data string and sends it to the server
#
##############################################################################
sub LastActivity {
  my $self = shift;
  my $sid = shift;

  $self->debug(3,"LastActivity: sid($sid)");
  $self->debug(1,"LastActivity: lastActivity($self->{SIDS}->{$sid}->{lastActivity})");

  return $self->{SIDS}->{$sid}->{lastActivity};
}


##############################################################################
#
# MarkActivity - Record the current time for this sid.
#
##############################################################################
sub MarkActivity {
  my $self = shift;
  my $sid = shift;

  return if (exists($self->{SIDS}->{$sid}->{ignoreActivity}) &&
	     ($self->{SIDS}->{$sid}->{ignoreActivity} == 1));

  $self->debug(3,"MarkActivity: sid($sid)");

  $self->{SIDS}->{$sid}->{lastActivity} = time;
}


##############################################################################
#
# Send - Takes the data string and sends it to the server
#
##############################################################################
sub Send {
  my $self = shift;
  my $sid = shift;
  $self->debug(1,"Send: (@_)");
  $self->debug(3,"Send: sid($sid)");
  $self->debug(3,"Send: status($self->{SIDS}->{$sid}->{status})");

  return if ($self->{SIDS}->{$sid}->{status} == -1);

  $self->debug(3,"Send: socket($self->{SIDS}->{$sid}->{sock})");

  if (!defined($self->{SIDS}->{$sid}->{sock})) {
    $self->{SIDS}->{$sid}->{status} = -1;
    $self->SetErrorCode($sid,"Socket does not defined.");
    return;
  }

  $self->{SIDS}->{$sid}->{sock}->flush();

  if ($self->{SIDS}->{$sid}->{select}->can_write(0)) {
    $self->{SENDSTRING} = join("",@_);

    $self->{SENDWRITTEN} = 0;
    $self->{SENDOFFSET} = 0;
    $self->{SENDLENGTH} = length($self->{SENDSTRING});
    while ($self->{SENDLENGTH}) {
      $self->{SENDWRITTEN} = $self->{SIDS}->{$sid}->{sock}->syswrite($self->{SENDSTRING},$self->{SENDLENGTH},$self->{SENDOFFSET});

      $self->debug(4,"Send: SENDWRITTEN($self->{SENDWRITTEN})");

      return unless defined($self->{SENDWRITTEN});

      $self->{SENDLENGTH} -= $self->{SENDWRITTEN};
      $self->{SENDOFFSET} += $self->{SENDWRITTEN};
    }
  } else {
    $self->debug(3,"Send: can't write...");
  }

  return if($self->{SIDS}->{$sid}->{select}->has_exception(0));

  $self->debug(3,"Send: no exceptions");

  $self->{SIDS}->{$sid}->{keepalive} = time;

  $self->MarkActivity($sid);

  return 1;
}


##############################################################################
#
# Read - Takes the data from the server and returns a string
#
##############################################################################
sub Read {
  my $self = shift;
  my $sid = shift;
  my $buff;
  my $status = 1;

  $self->debug(3,"Read: sid($sid)");
  $self->debug(3,"Read: connectionType($self->{SIDS}->{$sid}->{connectiontype})");
  $self->debug(3,"Read: socket($self->{SIDS}->{$sid}->{sock})");

  return if ($self->{SIDS}->{$sid}->{status} == -1);

  if (!defined($self->{SIDS}->{$sid}->{sock})) {
    $self->{SIDS}->{$sid}->{status} = -1;
    $self->SetErrorCode($sid,"Socket does not defined.");
    return;
  }

  $self->{SIDS}->{$sid}->{sock}->flush();

  $status = $self->{SIDS}->{$sid}->{sock}->sysread($buff,4*POSIX::BUFSIZ)
    if (($self->{SIDS}->{$sid}->{connectiontype} eq "tcpip") ||
	($self->{SIDS}->{$sid}->{connectiontype} eq "http") ||
	($self->{SIDS}->{$sid}->{connectiontype} eq "file"));
  $status = sysread(STDIN,$buff,1024)
    if ($self->{SIDS}->{$sid}->{connectiontype} eq "stdinout");

  $buff =~ s/^HTTP[\S\s]+\n\n// if ($self->{SIDS}->{$sid}->{connectiontype} eq "http");
  $self->debug(1,"Read: buff($buff)");
  $self->debug(3,"Read: status($status)") if defined($status);
  $self->debug(3,"Read: status(undef)") unless defined($status);
  $self->{SIDS}->{$sid}->{keepalive} = time
    unless (($buff eq "") || !defined($status) || ($status == 0));
  return $buff unless (!defined($status) || ($status == 0));
  $self->debug(1,"Read: ERROR");
  return;
}


##############################################################################
#
# GetErrorCode - if you are returned an undef, you can call this function
#                and hopefully learn more information about the problem.
#
##############################################################################
sub GetErrorCode {
  my $self = shift;
  my $sid = shift;

  $sid = "newconnection" unless defined($sid);

  $self->debug(3,"GetErrorCode: sid($sid)");
  return ((exists($self->{SIDS}->{$sid}->{errorcode}) &&
	   ($self->{SIDS}->{$sid}->{errorcode} ne "")) ?
	  $self->{SIDS}->{$sid}->{errorcode} :
	  $!);
}


##############################################################################
#
# SetErrorCode - sets the error code so that the caller can find out more
#                information about the problem
#
##############################################################################
sub SetErrorCode {
  my $self = shift;
  my $sid = shift;
  my ($errorcode) = @_;
  $self->{SIDS}->{$sid}->{errorcode} = $errorcode;
}


##############################################################################
#
# _handle_root - handles a root tag and checks that it is a stream:stream tag
#                with the proper namespace.  If not then it sets the STATUS
#                to -1 and let's the outer code know that an error occurred.
#                Then it changes the Start tag handlers to the methond listed
#                in $self->{DATASTYLE}
#
##############################################################################
sub _handle_root {
  my $self = shift;
  my ($sax, $tag, %att) = @_;
  my $sid = $sax->getSID();

  $self->debug(2,"_handle_root: sid($sid) sax($sax) tag($tag) att(",%att,")");

  $self->{SIDS}->{$sid}->{rootTag} = $tag;

  if ($self->{SIDS}->{$sid}->{connectiontype} ne "file") {
    #-------------------------------------------------------------------------
    # Make sure we are receiving a valid stream on the same namespace.
    #-------------------------------------------------------------------------
    $self->{SIDS}->{$sid}->{status} =
      ((($tag eq "stream:stream") &&
	exists($att{'xmlns'}) &&
	($att{'xmlns'} eq $self->{SIDS}->{$self->{SIDS}->{$sid}->{serverid}}->{namespace})
       ) ?
       1 :
       -1
      );
  } else {
    $self->{SIDS}->{$sid}->{status} = 1;
  }

  #---------------------------------------------------------------------------
  # Get the root tag attributes and save them for later.  You never know when
  # you'll need to check the namespace or the from attributes sent by the
  # server.
  #---------------------------------------------------------------------------
  $self->{SIDS}->{$sid}->{root} = \%att;

  #---------------------------------------------------------------------------
  # Sometimes we will get an error, so let's parse the tag assuming that we
  # got a stream:error
  #---------------------------------------------------------------------------
  if ($tag eq "stream:error") {
    &XML::Stream::Tree::_handle_element($self,$sax,$tag,%att)
      if ($self->{DATASTYLE} eq "tree");
    &XML::Stream::Hash::_handle_element($self,$sax,$tag,%att)
      if ($self->{DATASTYLE} eq "hash");
    &XML::Stream::Node::_handle_element($self,$sax,$tag,%att)
      if ($self->{DATASTYLE} eq "node");
  }

  #---------------------------------------------------------------------------
  # Now that we have gotten a root tag, let's look for the tags that make up
  # the stream.  Change the handler for a Start tag to another function.
  #---------------------------------------------------------------------------
  $sax->setHandlers(startElement=>sub{ &{$HANDLERS{$self->{DATASTYLE}}->{startElement}}($self,@_) },
		    endElement=>sub{ &{$HANDLERS{$self->{DATASTYLE}}->{endElement}}($self,@_) },
		    characters=>sub{ &{$HANDLERS{$self->{DATASTYLE}}->{characters}}($self,@_) },
		   );

  push(@{$self->{SIDS}->{$sid}->{IDSTACK}},"root")
    if ($self->{DATASTYLE} eq "hash");
}


##############################################################################
#
# _node - internal callback for nodes.  All it does is place the nodes in a
#         list so that Process() can return them later.
#
##############################################################################
sub _node {
  my $self = shift;
  my $sid = shift;
  my @PassedNode = @_;
  push(@{$self->{SIDS}->{$sid}->{nodes}},\@PassedNode);
}

1;


##############################################################################
#
# SetXMLData - takes a host of arguments and sets a portion of the specified
#              data strucure with that data.  The function works in two
#              modes "single" or "multiple".  "single" denotes that the
#              function should locate the current tag that matches this
#              data and overwrite it's contents with data passed in.
#              "multiple" denotes that a new tag should be created even if
#              others exist.
#
#              type    - single or multiple
#              XMLTree - pointer to XML::Stream data object (tree or hash)
#              tag     - name of tag to create/modify (if blank assumes
#                        working with top level tag)
#              data    - CDATA to set for tag
#              attribs - attributes to ADD to tag
#
##############################################################################
sub SetXMLData {
  return &XML::Stream::Node::SetXMLData(@_) if (ref($_[1]) eq "XML::Stream::Node");
  return &XML::Stream::Tree::SetXMLData(@_) if (ref($_[1]) eq "ARRAY");
  return &XML::Stream::Hash::SetXMLData(@_) if (ref($_[1]) eq "HASH");
}


##############################################################################
#
# GetXMLData - takes a host of arguments and returns various data structures
#              that match them.
#
#              type - "existence" - returns 1 or 0 if the tag exists in the
#                                   top level.
#                     "value" - returns either the CDATA of the tag, or the
#                               value of the attribute depending on which is
#                               sought.  This ignores any mark ups to the data
#                               and just returns the raw CDATA.
#                     "value array" - returns an array of strings representing
#                                     all of the CDATA in the specified tag.
#                                     This ignores any mark ups to the data
#                                     and just returns the raw CDATA.
#                     "tree" - returns a data structure that represents the
#                              XML with the specified tag as the root tag.
#                              Depends on the format that you are working with.
#                     "tree array" - returns an array of data structures each
#                                    with the specified tag as the root tag.
#                     "index array" - returns a list of all of the tags,
#                                     and the indexes into the array:
#                                     (foo,1,bar,3,test,7,etc...)
#                     "attribs" - returns a hash with the attributes, and
#                                 their values, for the things that match
#                                 the parameters
#                     "count" - returns the number of things that match
#                               the arguments
#                     "tag" - returns the root tag of this tree
#              XMLTree - pointer to XML::Stream data structure
#              tag     - tag to pull data from.  If blank then the top level
#                        tag is accessed.
#              attrib  - attribute value to retrieve.  Ignored for types
#                        "value array", "tree", "tree array".  If paired
#                        with value can be used to filter tags based on
#                        attributes and values.
#              value   - only valid if an attribute is supplied.  Used to
#                        filter for tags that only contain this attribute.
#                        Useful to search through multiple tags that all
#                        reference different name spaces.
#
##############################################################################
sub GetXMLData {
  return &XML::Stream::Node::GetXMLData(@_) if (ref($_[1]) eq "XML::Stream::Node");
  return &XML::Stream::Tree::GetXMLData(@_) if (ref($_[1]) eq "ARRAY");
  return &XML::Stream::Hash::GetXMLData(@_) if (ref($_[1]) eq "HASH");
}


##############################################################################
#
# XPath - run an xpath query on a node and return back the results.  Calls
#         XPathExec to do the work.
#
##############################################################################
sub XPath {
  my @exec = &XPathExec(@_);

  my %results;
  my @results;
  foreach my $res (@exec) {
    if ((ref($res) eq "ARRAY") && ($res->[0] eq "__xmlstream__:return")) {
      if (ref($res->[1]) eq "ARRAY") {
	if (!exists($results{$res->[1]->[1]})) {
	  push(@results,$res->[2]);
	  $results{$res->[1]->[1]} = 1;
	}
      } else {
	if (!exists($results{$res->[1]})) {
	  push(@results,$res->[2]);
	  $results{$res->[1]} = 1;
	}
      }
    } else {
      if (ref($res) eq "ARRAY") {
	if (!exists($results{$res->[1]})) {
	  push(@results,$res);
	  $results{$res->[1]} = 1;
	}
      } else {
	if (!exists($results{$res})) {
	  push(@results,$res);
	  $results{$res} = 1;
	}
      }
    }
  }

  return @results;
}


##############################################################################
#
# XPathExec - run an xpath query on a node and return back the results.  This
#             is a helper function and should NEVER be called directly.
#
##############################################################################
sub XPathExec {
  my ($XMLTree,$path,$debug) = @_;

  $debug = 0 unless defined($debug);

  print "XPath: XMLTree($XMLTree) path($path)\n" if ($debug);
  print &BuildXML($XMLTree),"\n" if ($debug);

  my ($desc,$fullStep,$restPath) = ($path =~ /^(\/?\/?)([^\/]+)(.*)$/);

  print "XPath: desc($desc) fullStep($fullStep) restPath($restPath)\n" if ($debug);

  my $newPath = $restPath;
  my $descPath = $restPath;
  $descPath = $path if ($desc eq "//");

  my ($filter) = ($fullStep =~ /\[([^\]]+)\]/);
  $filter = "" unless defined($filter);
  my $step = $fullStep;
  $step =~ s/\[([^\]]+)\]// if ($step =~ /\[/);

  print "XPath: fullStep($fullStep) step($step) filter($filter)\n" if ($debug);
  print "XPath: newPath($newPath) descPath($descPath)\n" if ($debug);

  return $XMLTree if ($step eq ".");

  if ($step eq "text()") {
    print "XPath: return text() of tree($XMLTree)\n" if ($debug);
    return ["__xmlstream__:return",$XMLTree,&GetXMLData("value",$XMLTree)]
  }


  if ($step =~ /^\@/) {
    my ($att) = ($step =~ /^@(.+)$/);
    if ($att eq "*") {
      my %atts = &GetXMLData("attribs",$XMLTree);
      print "XPath: return attributes of tree($XMLTree)\n" if ($debug);
      if (ref($XMLTree) eq "HASH") {
	return ["__xmlstream__:return",$XMLTree->{root},\%atts];
      } else{
	return ["__xmlstream__:return",$XMLTree,\%atts];
      }
    } else {
      print "XPath: check for attribute in tree($XMLTree)\n" if ($debug);
      return unless &GetXMLData("existence",$XMLTree,"",$att);
      print "XPath: return single attribute of tree($XMLTree)\n" if ($debug);
      if (ref($XMLTree) eq "HASH") {
	return ["__xmlstream__:return",$XMLTree->{root},&GetXMLData("value",$XMLTree,"",$att)];
      } else{
	return ["__xmlstream__:return",$XMLTree,&GetXMLData("value",$XMLTree,"",$att)];
      }
    }
  }

  my @return;
  my $oldRoot = $XMLTree->{root} if (ref($XMLTree) eq "HASH");
  foreach my $treePtr (&GetXMLData("tree array",$XMLTree,"*")) {
    my $tree = $treePtr;
    if (ref($XMLTree) eq "HASH") {
      $tree = $XMLTree;
      $tree->{root} = $treePtr;
    }
    next if (&GetXMLData("tag",$tree) eq "__xmlstream__:node:cdata");

    print "XPath: loop: tag(",&GetXMLData("tag",$tree),") step($step) newPath($newPath)\n" if ($debug);

    if ((&GetXMLData("tag",$tree) eq $step) || ($step eq "*")) {
      print "XPath: we matched the step...\n" if ($debug);

      my $pass = 1;
      if ($filter ne "") {
	print "XPath: and we have a filter... ($filter) run it\n" if ($debug);
	foreach my $subFilter (split(/\s+and\s+/,$filter)) {
	  if ($subFilter =~ /^\@/) {
	    my ($att,$check,$value) = ($subFilter =~ /^\@([^\=]+)(\=?)[\'\"]?([^\'\"]*)[\'\"]?/);
	    print "XPath: filter: att($att) check($check) value($value)\n" if ($debug);
	    if ($check eq "") {
	      print "XPath: res(",&GetXMLData("existence",$tree,"",$att),")\n" if ($debug);
	      $pass &= &GetXMLData("existence",$tree,"",$att);
	    } else {
	      my $attVal = &GetXMLData("value",$tree,"",$att);
	      print "XPath: res(",($attVal eq $value),")\n" if ($debug);
	      $pass &= ($attVal eq $value);
	    }
	    last unless $pass;
	  } else {
	    my ($child,$check,$value) = ($subFilter =~ /^([^\=]+)(\=?)[\'\"]?([^\'\"]*)[\'\"]?/);
	    print "XPath: filter: child($child) check($check) value($value)\n" if ($debug);
	    if ($check eq "") {
	      print "XPath: res(",&GetXMLData("existence",$tree,$child),")\n" if ($debug);
	      $pass &= &GetXMLData("existence",$tree,$child);
	    } else {
	      my $childVal = &GetXMLData("value",$tree,$child);
	      print "XPath: res(",($childVal eq $value),")\n" if ($debug);
	      $pass &= ($childVal eq $value);
	    }
	    last unless $pass;
	  }
	}
      }

      if ($pass == 1) {
	print "XPath: we have passed any and all tests...\n" if ($debug);
	
	if (($newPath eq "") || ($newPath eq $step) || ($step eq "*")) {
	  print "XPath: return the tree($tree)\n" if ($debug);
	  if (ref($tree) eq "HASH") {
	    push(@return,$tree->{root});
	  } else {
	    push(@return,$tree);
	  }
	} else {
	  print "XPath: return the results from XPathExec on tree($tree) newPath($newPath)\n" if ($debug);
	  push(@return,&XPathExec($tree,$newPath,$debug));
	}
	if ($descPath =~ /^\/\//) {
	  print "XPath: we passed, but we have a desc path... return that result\n" if ($debug);
	  push(@return,&XPathExec($tree,$descPath,$debug));
	}
      }
    } else {
      print "XPath: no match...\n" if ($debug);
      if ($desc eq "//") {
	print "XPath: but descend...\n" if ($debug);
	push(@return,&XPathExec($tree,$descPath,$debug));
      }
    }
  }
  $XMLTree->{root} = $oldRoot if (ref($XMLTree) eq "HASH");

  print "XPath: finish\n" if ($debug);

  return @return;
}


##############################################################################
#
# XML2Config - takes an XML data tree and turns it into a hash of hashes.
#              This only works for certain kinds of XML trees like this:
#
#                <foo>
#                  <bar>1</bar>
#                  <x>
#                    <y>foo</y>
#                  </x>
#                  <z>5</z>
#                  <z>6</z>
#                </foo>
#
#              The resulting hash would be:
#
#                $hash{bar} = 1;
#                $hash{x}->{y} = "foo";
#                $hash{z}->[0] = 5;
#                $hash{z}->[1] = 6;
#
#              Good for config files.
#
##############################################################################
sub XML2Config {
  return &XML::Stream::Node::XML2Config(@_) if (ref($_[0]) eq "XML::Stream::Node");
  return &XML::Stream::Tree::XML2Config(@_) if (ref($_[0]) eq "ARRAY");
  return &XML::Stream::Hash::XML2Config(@_) if (ref($_[0]) eq "HASH");
}


##############################################################################
#
# Config2XML - takes a hash and produces an XML string from it.  If the hash
#              looks like this:
#
#                $hash{bar} = 1;
#                $hash{x}->{y} = "foo";
#                $hash{z}->[0] = 5;
#                $hash{z}->[1] = 6;
#
#              The resulting xml would be:
#
#                <foo>
#                  <bar>1</bar>
#                  <x>
#                    <y>foo</y>
#                  </x>
#                  <z>5</z>
#                  <z>6</z>
#                </foo>
#
#              Good for config files.
#
##############################################################################
sub Config2XML {
  my ($tag,$hash,$indent) = @_;
  $indent = "" unless defined($indent);

  my $xml;

  if (ref($hash) eq "ARRAY") {
    foreach my $item (@{$hash}) {
      $xml .= &XML::Stream::Config2XML($tag,$item,$indent);
    }
  } else {
    if ((ref($hash) eq "HASH") && ((scalar keys(%{$hash})) == 0)) {
      $xml .= "$indent<$tag/>\n";
    } else {
      if (ref($hash) eq "") {
	if ($hash eq "") {
	  return "$indent<$tag/>\n";
	} else {
	  return "$indent<$tag>$hash</$tag>\n";
	}
      } else {
	$xml .= "$indent<$tag>\n";
	foreach my $item (sort {$a cmp $b} keys(%{$hash})) {
	  $xml .= &XML::Stream::Config2XML($item,$hash->{$item},"  $indent");
	}
	$xml .= "$indent</$tag>\n";
      }
    }
  }
  return $xml;
}


##############################################################################
#
# EscapeXML - Simple function to make sure that no bad characters make it into
#             in the XML string that might cause the string to be
#             misinterpreted.
#
##############################################################################
sub EscapeXML {
  my $data = shift;

  if (defined($data)) {
    $data =~ s/&/&amp;/g;
    $data =~ s/</&lt;/g;
    $data =~ s/>/&gt;/g;
    $data =~ s/\"/&quot;/g;
    $data =~ s/\'/&apos;/g;

    my $unicode = new Unicode::String();
    $unicode->latin1($data);
    $data = $unicode->utf8;
  }

  return $data;
}


##############################################################################
#
# UnescapeXML - Simple function to take an escaped string and return it to
#               normal.
#
##############################################################################
sub UnescapeXML {
  my $data = shift;

  if (defined($data)) {
    $data =~ s/&amp;/&/g;
    $data =~ s/&lt;/</g;
    $data =~ s/&gt;/>/g;
    $data =~ s/&quot;/\"/g;
    $data =~ s/&apos;/\'/g;
  }

  return $data;
}


##############################################################################
#
# BuildXML - takes one of the data formats that XML::Stream supports and call
#            the proper BuildXML_xxx function on it.
#
##############################################################################
sub BuildXML {
  return &XML::Stream::Node::BuildXML(@_) if (ref($_[0]) eq "XML::Stream::Node");
  return &XML::Stream::Hash::BuildXML(1,@_) if (ref($_[0]) eq "HASH");
  return &XML::Stream::Tree::BuildXML(@{$_[0]}) if (ref($_[0]) eq "ARRAY");
  return &XML::Stream::Tree::BuildXML(@_) if (ref($_[1]) eq "ARRAY");
}


##############################################################################
#
# LoadSSL - simple call to set everything up for SSL one time.
#
##############################################################################
sub LoadSSL {
  if (!defined($SSL)) {
    my $SSL_Version = "0.81";
    eval "use IO::Socket::SSL $SSL_Version";
    if ($@) {
      croak("You requested that XML::Stream turn the socket into an SSL socket, but you don't have the correct version of IO::Socket::SSL v$SSL_Version.");
    }
    IO::Socket::SSL::context_init({SSL_verify_mode=>0x00});
    $SSL = 1;
  }
}


##############################################################################
#
# printData - debugging function to print out any data structure in an
#             organized manner.  Very useful for debugging XML::Parser::Tree
#             objects.  This is a private function that will only exist in
#             in the development version.
#
##############################################################################
sub printData {
  print &sprintData(@_);
}


##############################################################################
#
# sprintData - debugging function to build a string out of any data structure
#              in an organized manner.  Very useful for debugging
#              XML::Parser::Tree objects and perl hashes of hashes.
#
#              This is a private function.
#
##############################################################################
sub sprintData {
  my ($preString,$data) = @_;

  my $outString = "";

  if (ref($data) eq "HASH") {
    my $key;
    foreach $key (sort { $a cmp $b } keys(%{$data})) {
      if (ref($$data{$key}) eq "") {
	my $value = defined($$data{$key}) ? $$data{$key} : "";
	$outString .= $preString."{'$key'} = \"".$value."\";\n";
      } else {
	if (ref($$data{$key}) =~ /Net::Jabber/) {
	  $outString .= $preString."{'$key'} = ".ref($$data{$key}).";\n";
	} else {
	  $outString .= $preString."{'$key'};\n";
	  $outString .= &sprintData($preString."{'$key'}->",$$data{$key});
	}
      }
    }
  } else {
    if (ref($data) eq "ARRAY") {
      my $index;
      foreach $index (0..$#{$data}) {
	if (ref($$data[$index]) eq "") {
	  $outString .= $preString."[$index] = \"$$data[$index]\";\n";
	} else {
	  if (ref($$data[$index]) =~ /Net::Jabber/) {
	    $outString .= $preString."[$index] = ".ref($$data[$index]).";\n";
	  } else {
	    $outString .= $preString."[$index];\n";
	    $outString .= &sprintData($preString."[$index]->",$$data[$index]);
	  }
	}
      }
    } else {
      if (ref($data) eq "REF") {
	$outString .= &sprintData($preString."->",$$data);
      } else {
	if (ref($data) eq "") {
	  $outString .= $preString." = \"$data\";\n";
	} else {
 	  $outString .= $preString." = ".ref($data).";\n";
	}
      }
    }
  }

  return $outString;
}


