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

  Just a collection of functions that do not need to be in memorf if you
choose one of the other methods of data storage.

=head1 AUTHOR

By Ryan Eatmon in March 2001 for http://jabber.org/

=head1 COPYRIGHT

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use vars qw($VERSION);

$VERSION = "1.13";

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

  $self->debug(2,"_handle_element: sid($sid) sax($sax) tag($tag) att(",%att,")")
    unless (ref($self) eq "XML::Stream::Parser");

  my $element;
  if ($#{$self->{SIDS}->{$sid}->{IDSTACK}} == -1) {
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

  if ($#{$self->{SIDS}->{$sid}->{IDSTACK}} >= 1) {
    my $parent = $self->{SIDS}->{$sid}->{IDSTACK}->[$#{$self->{SIDS}->{$sid}->{IDSTACK}}-1];

    $self->{SIDS}->{$sid}->{hash}->{"$parent-child"} .= ",$id";
    $self->{SIDS}->{$sid}->{hash}->{"$parent-child"} =~ s/^\,//;

    $self->{SIDS}->{$sid}->{DESCSTACK}->[$#{$self->{SIDS}->{$sid}->{DESCSTACK}}-1] .= "$id,";
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

  $self->debug(2,"_handle_cdata: sid($sid) sax($sax) cdata($cdata)")
    unless (ref($self) eq "XML::Stream::Parser");

  return if ($#{$self->{SIDS}->{$sid}->{IDSTACK}} == -1);

  my $id = $self->{SIDS}->{$sid}->{IDSTACK}->[$#{$self->{SIDS}->{$sid}->{IDSTACK}}];

  my $unicode = new Unicode::String();
  $unicode->utf8($cdata);
  $cdata = $unicode->latin1;

  $self->debug(2,"_handle_cdata: sax($sax) cdata($cdata)")
    unless (ref($self) eq "XML::Stream::Parser");

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

  $self->debug(2,"_handle_close: sid($sid) sax($sax) tag($tag)")
    unless (ref($self) eq "XML::Stream::Parser");

  my $id = pop(@{$self->{SIDS}->{$sid}->{IDSTACK}});
  my $desc = pop(@{$self->{SIDS}->{$sid}->{DESCSTACK}});

  $self->{SIDS}->{$sid}->{DESCSTACK}->[$#{$self->{SIDS}->{$sid}->{DESCSTACK}}] .= $desc unless ($#{$self->{SIDS}->{$sid}->{DESCSTACK}} == -1);

  if ($desc ne "") {
    $desc =~ s/\,$//;
    $self->{SIDS}->{$sid}->{hash}->{"$id-desc"} = $desc;
  }

  $self->debug(2,"_handle_close: check(",$#{$self->{SIDS}->{$sid}->{IDSTACK}},")")
    unless (ref($self) eq "XML::Stream::Parser");

  if($#{$self->{SIDS}->{$sid}->{IDSTACK}} == -1) {
    if($self->{SIDS}->{$sid}->{hash}->{"${id}-tag"} eq "stream:error") {
      $self->{SIDS}->{$sid}->{streamerror} =
	$self->{SIDS}->{$sid}->{hash}->{"$id-data"};
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
	    push(@array,$$XMLTree{$child."-data"});
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
    #---------------------------------------------------------------------
    # This is the root tag, so handle things a level up.
    #---------------------------------------------------------------------

    #---------------------------------------------------------------------
    # Return the raw CDATA value without mark ups, or the value of the
    # requested attribute.
    #---------------------------------------------------------------------
    if ($type eq "value") {
      if ($attrib eq "") {
	return $$XMLTree{$$XMLTree{root}."-data"};
      }
      return $$XMLTree{$$XMLTree{root}."-att-".$attrib}
        if (exists $$XMLTree{$$XMLTree{root}."-att-".$attrib});
    }
    #---------------------------------------------------------------------
    # Return a pointer to a new XML::Parser::Tree object that has the
    # requested tag as the root tag.
    #---------------------------------------------------------------------
    if ($type eq "tree") {
      my %hash =  %{$XMLTree};
      return %hash;
    }

    #---------------------------------------------------------------------
    # Return the 1 if the specified attribute exists in the root tag.
    #---------------------------------------------------------------------
    if ($type eq "existence") {
      return 1 if (($attrib ne "") && exists($$XMLTree{$$XMLTree{root}."-att-".$attrib}));
    }

    #---------------------------------------------------------------------
    # Return the attribute hash that matches this tag
    #---------------------------------------------------------------------
    if ($type eq "attribs") {
      my %hash;
      foreach my $att (grep { /^$$XMLTree{root}-att-/; } keys (%{$XMLTree})) {
	my ($name) = ($att =~ /^$$XMLTree{root}-att-(.*)$/);
	$hash{$name} = $$XMLTree{$att};
      }
      return %hash;
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
      foreach my $child (sort {$a cmp $b} split(",",$$hash{"${id}-child"})) {
	$str .= &XML::Stream::Hash::BuildXML($child,$hash);
      }
    }
    $str .= "</$tag>";
  } else {
    $str .= "/>";
  }

  return $str;
}

1;
