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

package XML::Stream::Hash;

=head1 NAME

XML::Stream::Hash - Functions to make building and parsing the hash easier
to work with.

=head1 SYNOPSIS

  Just a collection of functions that do not need to be in memory if you
choose one of the other methods of data storage.

  The Hash format is an exercise to reduce the memory foot print of the
XML.  By not using the Tree format with many levels of arrays and hashs,
and just using one large Hash you lower the memory requirements but lose
some flexability.

  One thing you lose is that you cannot do:

    "text <tag>something</tag> more text"

  The format is not setup to handle that.  It is optimized to only handle
either children, or cdata, but not a mixture of both.

=head1 FORMAT

The result of parsing:

  <foo><head id="a">Hello <em>there</em></head><bar>Howdy<ref/></bar>do</foo>

would be:

  $hash{'root'}     = "1";
  $hash{'1-child'}  = "2,4";
  $hash{'1-data'}   = "do";
  $hash{'1-desc'}   = "2,3,4,5";
  $hash{'1-tag'}    = "foo";
  $hash{'2-att-id'} = "a";
  $hash{'2-child'}  = "3";
  $hash{'2-data'}   = "Hello ";
  $hash{'2-desc'}   = "3";
  $hash{'2-tag'}    = "head";
  $hash{'3-data'}   = "there";
  $hash{'3-tag'}    = "em";
  $hash{'4-child'}  = "5";
  $hash{'4-data'}   = "Howdy";
  $hash{'4-desc'}   = "5";
  $hash{'4-tag'}    = "bar";
  $hash{'5-tag'}    = "ref";

=head1 AUTHOR

By Ryan Eatmon in March 2001 for http://jabber.org/

=head1 COPYRIGHT

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use vars qw($VERSION);

$VERSION = "1.15";

##############################################################################
#
# _handle_element - handles the main tag elements sent from the server.
#                   The tag is appended onto the hash key so that the
#                   sub tags can be formed properly.
#
##############################################################################
sub _handle_element {
  my $self;
  $self = $_[0] if (ref($_[0]) eq "XML::Stream::Parser");
  $self = shift unless (ref($_[0]) eq "XML::Stream::Parser");
  my ($sax, $tag, %att) = @_;
  my $sid = $sax->getSID();

  $self->debug(2,"_handle_element: sid($sid) sax($sax) tag($tag) att(",%att,")");

  if (!exists($self->{SIDS}->{$sid}->{rootTag}) ||
      !defined($self->{SIDS}->{$sid}->{rootTag})) {
    $self->{SIDS}->{$sid}->{rootTag} = $tag;
  }

  my $element;
  if ($#{$self->{SIDS}->{$sid}->{IDSTACK}} == 0) {
    $self->{SIDS}->{$sid}->{ID} = 0;
    $self->{SIDS}->{$sid}->{hash}->{root} = 1;
  }
  $self->{SIDS}->{$sid}->{ID}++;
  my $id = $self->{SIDS}->{$sid}->{ID};
  push(@{$self->{SIDS}->{$sid}->{IDSTACK}},$id);
  push(@{$self->{SIDS}->{$sid}->{DESCSTACK}},"");

  $self->{SIDS}->{$sid}->{hash}->{"${id}-tag"} = $tag;
  my $key;
  my $value;
  while (($key,$value) = each(%att)) {
    $self->{SIDS}->{$sid}->{hash}->{"${id}-att-${key}"} = $value;
  }

  if ($#{$self->{SIDS}->{$sid}->{IDSTACK}} >= 2) {
    my $parent = $self->{SIDS}->{$sid}->{IDSTACK}->[$#{$self->{SIDS}->{$sid}->{IDSTACK}}-1];

    $self->{SIDS}->{$sid}->{hash}->{"${parent}-child"} .= ",${id}";
    $self->{SIDS}->{$sid}->{hash}->{"${parent}-child"} =~ s/^\,//;

    $self->{SIDS}->{$sid}->{DESCSTACK}->[$#{$self->{SIDS}->{$sid}->{DESCSTACK}}-1] .= "${id},";
  }
}


##############################################################################
#
# _handle_cdata - handles the CDATA that is encountered.  This is
#                      appended onto the hash entry for the tag
#
##############################################################################
sub _handle_cdata {
  my $self;
  $self = $_[0] if (ref($_[0]) eq "XML::Stream::Parser");
  $self = shift unless (ref($_[0]) eq "XML::Stream::Parser");
  my ($sax, $cdata) = @_;
  my $sid = $sax->getSID();

  $self->debug(2,"_handle_cdata: sid($sid) sax($sax) cdata($cdata)");

  return if ($#{$self->{SIDS}->{$sid}->{IDSTACK}} == 0);

  my $id = $self->{SIDS}->{$sid}->{IDSTACK}->[$#{$self->{SIDS}->{$sid}->{IDSTACK}}];

  my $unicode = new Unicode::String();
  $unicode->utf8($cdata);
  $cdata = $unicode->latin1;

  $self->debug(2,"_handle_cdata: sax($sax) cdata($cdata)");

  $self->{SIDS}->{$sid}->{hash}->{"${id}-data"} = $cdata;
}


##############################################################################
#
# _handle_close - when you see a close tag you need to adjust the hash
#                      key to show that the tag closed.
#
##############################################################################
sub _handle_close {
  my $self;
  $self = $_[0] if (ref($_[0]) eq "XML::Stream::Parser");
  $self = shift unless (ref($_[0]) eq "XML::Stream::Parser");
  my ($sax, $tag) = @_;
  my $sid = $sax->getSID();

  $self->debug(2,"_handle_close: sid($sid) sax($sax) tag($tag)");

  my $id = pop(@{$self->{SIDS}->{$sid}->{IDSTACK}});
  my $desc = pop(@{$self->{SIDS}->{$sid}->{DESCSTACK}});

  $self->{SIDS}->{$sid}->{DESCSTACK}->[$#{$self->{SIDS}->{$sid}->{DESCSTACK}}] .= $desc unless ($#{$self->{SIDS}->{$sid}->{DESCSTACK}} == -1);

  if (defined($desc) && ($desc ne "")) {
    $desc =~ s/\,$//;
    $self->{SIDS}->{$sid}->{hash}->{"${id}-desc"} = $desc;
  }

  $self->debug(2,"_handle_close: check(",$#{$self->{SIDS}->{$sid}->{IDSTACK}},")");

  if ($#{$self->{SIDS}->{$sid}->{IDSTACK}} == -1) {
    if ($self->{SIDS}->{$sid}->{rootTag} ne $tag) {
      $self->{SIDS}->{$sid}->{streamerror} = "Root tag mis-match: <$self->{SIDS}->{$sid}->{rootTag}> ... </$tag>\n";
    }
    return;
  }

  if($#{$self->{SIDS}->{$sid}->{IDSTACK}} < 1) {
    if($self->{SIDS}->{$sid}->{hash}->{"${id}-tag"} eq "stream:error") {
      $self->{SIDS}->{$sid}->{streamerror} =
	$self->{SIDS}->{$sid}->{hash}->{"${id}-data"};
    } else {
      if (ref($self) ne "XML::Stream::Parser") {
	&{$self->{CB}->{node}}($sid,$self->{SIDS}->{$sid}->{hash});
	$self->{SIDS}->{$sid}->{hash} = {};
      }
    }
  }
}


##############################################################################
#
# SetXMLData - takes a host of arguments and sets a portion of the specified
#              XML::Parser::Tree object with that data.  The function works
#              in two modes "single" or "multiple".  "single" denotes that
#              the function should locate the current tag that matches this
#              data and overwrite it's contents with data passed in.
#              "multiple" denotes that a new tag should be created even if
#              others exist.
#
#              type    - single or multiple
#              XMLTree - pointer to XML::Parser::Tree
#              tag     - name of tag to create/modify (if blank assumes
#                        working with top level tag)
#              data    - CDATA to set for tag
#              attribs - attributes to ADD to tag
#
##############################################################################
sub SetXMLData {
  my ($type,$XMLTree,$tag,$data,$attribs) = @_;
  my ($key);

  return;

  if ($tag ne "") {
    if ($type eq "single") {
      my ($child);
      foreach $child (1..$#{$$XMLTree[1]}) {
	if ($$XMLTree[1]->[$child] eq $tag) {
	  if ($data ne "") {
	    #todo: add code to handle writing the cdata again and appending it.
	    $$XMLTree[1]->[$child+1]->[1] = 0;
	    $$XMLTree[1]->[$child+1]->[2] = $data;
	  }
	  foreach $key (keys(%{$attribs})) {
	    $$XMLTree[1]->[$child+1]->[0]->{$key} = $$attribs{$key};
	  }
	  return;
	}
      }
    }
    $$XMLTree[1]->[($#{$$XMLTree[1]}+1)] = $tag;
    $$XMLTree[1]->[($#{$$XMLTree[1]}+1)]->[0] = {};
    foreach $key (keys(%{$attribs})) {
      $$XMLTree[1]->[$#{$$XMLTree[1]}]->[0]->{$key} = $$attribs{$key};
    }
    if ($data ne "") {
      $$XMLTree[1]->[$#{$$XMLTree[1]}]->[1] = 0;
      $$XMLTree[1]->[$#{$$XMLTree[1]}]->[2] = $data;
    }
  } else {
    foreach $key (keys(%{$attribs})) {
      $$XMLTree[1]->[0]->{$key} = $$attribs{$key};
    }
    if ($data ne "") {
      if (($#{$$XMLTree[1]} > 0) &&
	  ($$XMLTree[1]->[($#{$$XMLTree[1]}-1)] eq "0")) {
	$$XMLTree[1]->[$#{$$XMLTree[1]}] .= $data;
      } else {
	$$XMLTree[1]->[($#{$$XMLTree[1]}+1)] = 0;
	$$XMLTree[1]->[($#{$$XMLTree[1]}+1)] = $data;
      }
    }
  }
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
#                     "tree" - returns an XML::Parser::Tree object with the
#                              specified tag as the root tag.
#                     "tree array" - returns an array of XML::Parser::Tree
#                                    objects each with the specified tag as
#                                    the root tag.
#                     "index array" - returns a list of all of the tags,
#                                     and the indexes into the array:
#                                     (foo,1,bar,3,test,7,etc...)
#                     "attribs" - returns a hash with the attributes, and
#                                 their values, for the things that match
#                                 the parameters
#                     "count" - returns the number of things that match
#                               the arguments
#                     "tag" - returns the root tag of this tree
#              XMLTree - pointer to XML::Parser::Tree object
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
  my ($type,$XMLTree,$tag,$attrib,$value) = @_;

  $tag = "" if !defined($tag);
  $attrib = "" if !defined($attrib);
  $value = "" if !defined($value);

  #---------------------------------------------------------------------------
  # Check if a child tag in the root tag is being requested.
  #---------------------------------------------------------------------------
  if ($tag ne "") {
    my $count = 0;
    my @array;
    if (exists($$XMLTree{"$$XMLTree{root}-child"})) {
      foreach my $child (split(",",$$XMLTree{"$$XMLTree{root}-child"})) {
	if (($$XMLTree{"$child-tag"} eq $tag) || ($tag eq "*")) {

	  #-------------------------------------------------------------------
	  # Filter out tags that do not contain the attribute and value.
	  #-------------------------------------------------------------------
	  next if (($value ne "") && ($attrib ne "") && exists($$XMLTree{$child."-att-".$attrib}) && ($$XMLTree{$child."-att-".$attrib} ne $value));
	  next if (($attrib ne "") && !exists($$XMLTree{$child."-att-".$attrib}));

	  #-------------------------------------------------------------------
	  # Check for existence
	  #-------------------------------------------------------------------
	  if ($type eq "existence") {
	    return 1;
	  }
	  #-------------------------------------------------------------------
	  # Return the raw CDATA value without mark ups, or the value of the
	  # requested attribute.
	  #-------------------------------------------------------------------
	  if ($type eq "value") {
	    if ($attrib eq "") {
	      return $$XMLTree{$child."-data"};
	    }
	    return $$XMLTree{$child."-att-".$attrib}
	      if (exists $$XMLTree{$child."-att-".$attrib});
	  }
	  #-------------------------------------------------------------------
	  # Return an array of values that represent the raw CDATA without
	  # mark up tags for the requested tags.
	  #-------------------------------------------------------------------
	  if ($type eq "value array") {
	    if ($attrib eq "") {
	      push(@array,$$XMLTree{$child."-data"});
	    } else {
	      push(@array,$$XMLTree{$child."-att-".$attrib})
		if (exists $$XMLTree{$child."-att-".$attrib});
	    }
	  }
	  #-------------------------------------------------------------------
	  # Return a pointer to a new XML::Stream::Hash object that has the
	  # requested tag as the root tag if the type is "tree".
	  # Return an array of pointers to XML::Stream::Hash objects that have
	  # the requested tag as the root tags if the type is "tree array".
	  #-------------------------------------------------------------------
	  if (($type eq "tree") || ($type eq "tree array")) {
	    return $child if ($type eq "tree");
	    push(@array,$child) if ($type eq "tree array");
	  }
	  #-------------------------------------------------------------------
	  # Return a count of the number of tags that match
	  #-------------------------------------------------------------------
	  if ($type eq "count") {
	    $count++;
	  }
	  #-------------------------------------------------------------------
	  # Return a count of the number of tags that match
	  #-------------------------------------------------------------------
#  	  if ($type eq "index array") {
#	    my @tree = ( $$XMLTree[1]->[$child] , $$XMLTree[1]->[$child+1] );
#	    push(@array,$$XMLTree[1]->[$child],$child);
# 	  }
	  #-------------------------------------------------------------------
	  # Return the attribute hash that matches this tag
	  #-------------------------------------------------------------------
	  if ($type eq "attribs") {
	    my %hash;
	    foreach my $att (grep { /^$child-att-/; } keys (%{$XMLTree})) {
	      my ($name) = ($att =~ /^$child-att-(.*)$/);
	      $hash{$name} = $$XMLTree{$att};
	    }
	    return %hash;
	  }
	}
      }
    }
    #-------------------------------------------------------------------------
    # If we are returning arrays then return array.
    #-------------------------------------------------------------------------
    if (($type eq "tree array") || ($type eq "value array") ||
        ($type eq "index array")) {
      return @array;
    }

    #-------------------------------------------------------------------------
    # If we are returning then count, then do so
    #-------------------------------------------------------------------------
    if ($type eq "count") {
      return $count;
    }
  } else {
    #-------------------------------------------------------------------------
    # This is the root tag, so handle things a level up.
    #-------------------------------------------------------------------------

    #-------------------------------------------------------------------------
    # Return the raw CDATA value without mark ups, or the value of the
    # requested attribute.
    #-------------------------------------------------------------------------
    if ($type eq "value") {
      if ($attrib eq "") {
	return $$XMLTree{$$XMLTree{root}."-data"};
      }
      return $$XMLTree{$$XMLTree{root}."-att-".$attrib}
        if (exists $$XMLTree{$$XMLTree{root}."-att-".$attrib});
    }
    #-------------------------------------------------------------------------
    # Return a pointer to a new XML::Parser::Tree object that has the
    # requested tag as the root tag.
    #-------------------------------------------------------------------------
    if ($type eq "tree") {
      my %hash =  %{$XMLTree};
      return %hash;
    }

    #-------------------------------------------------------------------------
    # Return the 1 if the specified attribute exists in the root tag.
    #-------------------------------------------------------------------------
    if ($type eq "existence") {
      return 1 if (($attrib ne "") && exists($$XMLTree{$$XMLTree{root}."-att-".$attrib}));
    }

    #-------------------------------------------------------------------------
    # Return the attribute hash that matches this tag
    #-------------------------------------------------------------------------
    if ($type eq "attribs") {
      my %hash;
      foreach my $att (grep { /^$$XMLTree{root}-att-/; } keys (%{$XMLTree})) {
	my ($name) = ($att =~ /^$$XMLTree{root}-att-(.*)$/);
	$hash{$name} = $$XMLTree{$att};
      }
      return %hash;
    }
    #-------------------------------------------------------------------------
    # Return the tag of this node
    #-------------------------------------------------------------------------
    if ($type eq "tag") {
      return $$XMLTree{$$XMLTree{root}."-tag"};
    }
  }
  #---------------------------------------------------------------------------
  # Return 0 if this was a request for existence, or "" if a request for
  # a "value", or [] for "tree", "value array", and "tree array".
  #---------------------------------------------------------------------------
  return 0 if ($type eq "existence");
  return "" if ($type eq "value");
  return [];
}


##############################################################################
#
# BuildXML - takes an XML::Stream hash and builds the XML string that
#                 it represents.
#
##############################################################################
sub BuildXML {
  my ($id,$hash) = @_;
  my $str;

  my $tag = $$hash{"${id}-tag"};
  $str = "<$tag";

  foreach my $att (grep /^$id\-att/, keys(%{$hash})) {
    my ($name) = ($att =~ /^$id\-att\-(.*)$/);
    $str .= " $name='".&XML::Stream::EscapeXML($$hash{$att})."'";
  }

  if (exists($$hash{"${id}-data"}) || exists($$hash{"${id}-child"})) {
    $str .= ">";
    $str .= &XML::Stream::EscapeXML($$hash{"${id}-data"})
      if exists($$hash{"${id}-data"});
    if (exists($$hash{"${id}-child"})) {
      foreach my $child (sort {$a <=> $b} split(",",$$hash{"${id}-child"})) {
	$str .= &XML::Stream::Hash::BuildXML($child,$hash);
      }
    }
    $str .= "</$tag>";
  } else {
    $str .= "/>";
  }

  return $str;
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
#                </foo>
#
#              The resulting hash would be:
#
#                $hash{bar} = 1;
#                $hash{x}->{y} = "foo";
#                $hash{z} = 5;
#
#              Good for config files.
#
##############################################################################
sub XML2Config {
  my ($XMLHash) = @_;

  my %hash;
  my $root = $XMLHash->{root};
  foreach my $child (&XML::Stream::GetXMLData("tree array",$XMLHash,"*")) {
    if (exists($XMLHash->{$child."-data"}) && !($XMLHash->{$child."-data"} =~ /^\s*$/)) {
      $hash{$XMLHash->{$child."-tag"}} = $XMLHash->{$child."-data"};
    } else {
      $XMLHash->{root} = $child;
      if (&XML::Stream::GetXMLData("count",$XMLHash,$XMLHash->{$child."-tag"}) > 1) {
	push(@{$hash{$XMLHash->{$child."-tag"}}},&XML::Stream::XML2Config($XMLHash));
      } else {
	$hash{$XMLHash->{$child."-tag"}} = &XML::Stream::XML2Config($XMLHash);
      }
      $XMLHash->{root} = $root;
    }
  }
  return \%hash;
}


1;
