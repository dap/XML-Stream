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

package XML::Stream::Parser::DTD;

=head1 NAME

  XML::Stream::Parser::DTD - XML DTD Parser and Verifier

=head1 SYNOPSIS

  This is a work in progress.  I had need for a DTD parser and verifier
  and so am working on it here.  If you are reading this then you are
  snooping.  =)

=head1 DESCRIPTION

  This module provides the initial code for a DTD parser and verifier.

=head1 METHODS

=head1 EXAMPLES

=head1 AUTHOR

By Ryan Eatmon in February of 2001 for http://jabber.org/

=head1 COPYRIGHT

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

require 5.003;
use strict;
use vars qw($VERSION $UNICODE);

if ($] >= 5.006) {
  $UNICODE = 1;
} else {
  require Unicode::String;
  $UNICODE = 0;
}

$VERSION = "1.11";

sub new {
  my $self = { };

  bless($self);

  my %args;
  while($#_ >= 0) { $args{ lc pop(@_) } = pop(@_); }

  $self->{URI} = $args{uri};

  $self->{PARSING} = 0;
  $self->{DOC} = 0;
  $self->{XML} = "";
  $self->{CNAME} = ();
  $self->{CURR} = 0;

  $self->{ENTITY}->{"&lt;"} = "<";
  $self->{ENTITY}->{"&gt;"} = ">";
  $self->{ENTITY}->{"&quot;"} = "\"";
  $self->{ENTITY}->{"&apos;"} = "'";
  $self->{ENTITY}->{"&amp;"} = "&";

  $self->{HANDLER}->{startDocument} = sub{ $self->startDocument(@_); };
  $self->{HANDLER}->{endDocument} = sub{ $self->endDocument(@_); };
  $self->{HANDLER}->{startElement} = sub{ $self->startElement(@_); };
  $self->{HANDLER}->{endElement} = sub{ $self->endElement(@_); };

  $self->{STYLE} = "debug";

  open(DTD,$args{uri});
  my $dtd = join("",<DTD>);
  close(DTD);

  $self->parse($dtd);

  return $self;
}


sub parse {
  my $self = shift;
  my $xml = shift;

  while($xml =~ s/<\!--.*?-->//gs) {}
  while($xml =~ s/\n//g) {}

  $self->{XML} .= $xml;

  return if ($self->{PARSING} == 1);

  $self->{PARSING} = 1;

  if(!$self->{DOC} == 1) {
    my $start = index($self->{XML},"<");

    if (substr($self->{XML},$start,3) =~ /^<\?x$/i) {
      my $close = index($self->{XML},"?>");
      if ($close == -1) {
	$self->{PARSING} = 0;
	return;
      }
      $self->{XML} = substr($self->{XML},$close+2,length($self->{XML})-$close-2);
    }

    &{$self->{HANDLER}->{startDocument}}($self);
    $self->{DOC} = 1;
  }

  while(1) {

    if (length($self->{XML}) == 0) {
      $self->{PARSING} = 0;
      return;
    }

    my $estart = index($self->{XML},"<");
    if ($estart == -1) {
      $self->{PARSING} = 0;
      return;
    }

    my $close = index($self->{XML},">");
    my $dtddata = substr($self->{XML},$estart+1,$close-1);
    my $nextspace = index($dtddata," ");
    my $attribs;

    my $type = substr($dtddata,0,$nextspace);
    $dtddata = substr($dtddata,$nextspace+1,length($dtddata)-$nextspace-1);
    $nextspace = index($dtddata," ");

    if ($type eq "!ENTITY") {
      $self->entity($type,$dtddata);
    } else {
      my $tag = substr($dtddata,0,$nextspace);
      $dtddata = substr($dtddata,$nextspace+1,length($dtddata)-$nextspace-1);
      $nextspace = index($dtddata," ");

      $self->element($type,$tag,$dtddata) if ($type eq "!ELEMENT");
      $self->attlist($type,$tag,$dtddata) if ($type eq "!ATTLIST");
    }

    $self->{XML} = substr($self->{XML},$close+1,length($self->{XML})-$close-1);
    next;
  }
}


sub startDocument {
  my $self = shift;
}


sub endDocument {
  my $self = shift;
}


sub entity {
  my $self = shift;
  my ($type, $data) = @_;

  foreach my $entity (keys(%{$self->{ENTITY}})) {
    $data =~ s/$entity/$self->{ENTITY}->{$entity}/g;
  }

  my ($symbol,$tag,undef,$string) = ($data =~ /^\s*(\S+)\s+(\S+)\s+(\"|\')([^\3]*)\3\s*$/);
  $self->{ENTITY}->{"${symbol}${tag}\;"} = $string;
}

sub element {
  my $self = shift;
  my ($type, $tag, $data) = @_;

  foreach my $entity (keys(%{$self->{ENTITY}})) {
    $data =~ s/$entity/$self->{ENTITY}->{$entity}/g;
  }

  print "element: type($type) tag($tag) data($data)\n";
  $self->parseElementData($self->{ELEMENT}->{$tag},$data);
}

sub parseElementData {
  my $self = shift;
  my ($datastruct,$data) = @_;

  my $groupList = substr($data,1,length($data)-2);
  if ($groupList eq "#PCDATA") {


  } else {
    if ($groupList =~ /^\s*\(/) {
      my $firstGroup = $self->getgrouping($groupList);
      my ($seperator) = ($groupList =~ /^\s*$firstGroup\s*(\||\,)/);
      if ($seperator eq ",") {
	
      }
    }
  }
}

sub attlist {
  my $self = shift;
  my ($type, $tag, $data) = @_;

  foreach my $entity (keys(%{$self->{ENTITY}})) {
    $data =~ s/$entity/$self->{ENTITY}->{$entity}/g;
  }

  while($data ne "") {
    my ($att) = ($data =~ /^\s*(\S+)/);
    $data =~ s/^\s*\S+\s*//;

    my $value;
    if ($data =~ /^\(/) {
      $value = $self->getgrouping($data);
      $data = substr($data,length($value)+1,length($data));
      $data =~ s/^\s*//;
      $self->{ATTLIST}->{$tag}->{$att}->{type} = "list";
      foreach my $val (split(/\s+\|\s+/,substr($value,1,length($value)-2))) {
	$self->{ATTLIST}->{$tag}->{$att}->{value}->{$val} = 1;
      }
    } else {
      ($value) = ($data =~ /^(\S+)/);
      $data =~ s/^\S+\s*//;
      $self->{ATTLIST}->{$tag}->{$att}->{type} = $value;
    }

    my $default;
    if ($data =~ /^\"|^\'/) {
      my($sq,$val) = ($data =~ /^(\"|\')([^\"\']*)\1/);
      $default = $val;
      $data =~ s/^$sq$val$sq\s*//;
    } else {
      ($default) = ($data =~ /^(\S+)/);
      $data =~ s/^\S+\s*//;
    }

    $self->{ATTLIST}->{$tag}->{$att}->{default} = $default;
  }
}



sub getgrouping {
  my $self = shift;
  my ($data) = @_;

  my $count = 0;
  my $parens = 0;
  foreach my $char (split("",$data)) {
    $parens++ if ($char eq "(");
    $parens-- if ($char eq ")");
    $count++;
    last if ($parens == 0);
  }
  return substr($data,0,$count);
}


sub groupinglist {
  my $self = shift;
  my ($grouping,$seperator) = @_;

  my @list;
  my $item = "";
  my $parens = 0;
  foreach my $char (split("",substr($grouping,1,length($grouping)-2))) {
    $parens++ if ($char eq "(");
    $parens-- if ($char eq ")");
    if ($parens == 0) {
      
    }

  }
  return @list;
}

