######################################################################
#
# The Apache Software License, Version 1.1
#
# Copyright (c) 1999-2000 The Apache Software Foundation.  All rights
# reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer. 
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in
#    the documentation and/or other materials provided with the
#    distribution.
#
# 3. The end-user documentation included with the redistribution,
#    if any, must include the following acknowledgment:  
# 	"This product includes software developed by the
# 	 Apache Software Foundation (http://www.apache.org/)."
#    Alternately, this acknowledgment may appear in the software itself,
#    if and wherever such third-party acknowledgments normally appear.
#
# 4. The names "Xerces" and "Apache Software Foundation" must
#    not be used to endorse or promote products derived from this
#    software without prior written permission. For written 
#    permission, please contact apache\@apache.org.
#
# 5. Products derived from this software may not be called "Apache",
#    nor may "Apache" appear in their name, without prior written
#    permission of the Apache Software Foundation.
#
# THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESSED OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED.  IN NO EVENT SHALL THE APACHE SOFTWARE FOUNDATION OR
# ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
# USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
# OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
# ====================================================================
#
# This software consists of voluntary contributions made by many
# individuals on behalf of the Apache Software Foundation, and was
# originally based on software copyright (c) 1999, International
# Business Machines, Inc., http://www.ibm.com .  For more information
# on the Apache Software Foundation, please see
# <http://www.apache.org/>.
#
######################################################################

package XML::Xerces::DOMParse;

######################################################################
#
# A collection of useful utilities to parse a DOM tree and do something
# with each node.  Includes a couple very useful concrete uses - 
#
# DOMParse::print		- prints an XML file for the DOM tree
# DOMParse::unformat	- removes format white space from the DOM tree
# DOMParse::format		- adds format white space to the DOM tree
#
######################################################################


use XML::Xerces;


######################################################################
# Replace these to hook your own code into the framework.  Sure,
# this could have all been done with objects instead of file scope,
# but for most applications this will be a lot more concise.
######################################################################
use strict;
use vars qw($INDENT
	    $ESCAPE
	    $NODE_PRINTER
	    $DOCUMENT_NODE_PRINTER
	    $DOCUMENT_TYPE_NODE_PRINTER
	    $COMMENT_NODE_PRINTER
	    $TEXT_NODE_PRINTER
	    $CDATA_SECTION_NODE_PRINTER
	    $ELEMENT_NODE_PRINTER
	    $ENTITY_REFERENCE_NODE_PRINTER
	    $PROCESSING_INSTRUCTION_NODE_PRINTER
	    $ATTRIBUTE_PRINTER
	    $XML_DECL_NODE_PRINTER
	   );

$INDENT = "\t";	# indent char used to add formatting
$ESCAPE = 1;		# 1 to do conversions like "&" to "&amp;" when printing

$NODE_PRINTER = \&print_node;
$XML_DECL_NODE_PRINTER = \&print_xml_decl_node;
$DOCUMENT_NODE_PRINTER = \&print_document_node;
$DOCUMENT_TYPE_NODE_PRINTER = \&print_document_type_node;
$COMMENT_NODE_PRINTER = \&print_comment_node;
$TEXT_NODE_PRINTER = \&print_text_node;
$CDATA_SECTION_NODE_PRINTER = \&print_cdata_section_node;
$ELEMENT_NODE_PRINTER = \&print_element_node;
$ENTITY_REFERENCE_NODE_PRINTER = \&print_entity_reference_node;
$PROCESSING_INSTRUCTION_NODE_PRINTER = \&print_processing_instruction_node;
$ATTRIBUTE_PRINTER = \&print_attributes;

######################################################################
# Parse a formatted DOM tree
######################################################################

use Carp;



sub parse_nodes {
  my ($node, $process_node, $data) = @_;

  my $child = $node->getFirstChild ();
  my $proceed = &$process_node ($node, $data);

  if ( $proceed ) {
    XML::Xerces::DOMParse::parse_child_nodes ($child, $process_node, $data);
  }
}

sub parse_child_nodes {
  my ($child, $process_node, $data) = @_;

  while ( defined $child ) {
    my $nextchild = $child->getNextSibling ();
    XML::Xerces::DOMParse::parse_nodes ($child, $process_node, $data);
    $child = $nextchild;
  }
}

sub doc {
  my ($node) = @_;
  my $parent = $node;

  while ( defined $parent ) {
    $parent = $node->getParentNode ();
  }

  return $node;
}

sub depth {
  my ($node) = @_;
  my $d = -1;

  while ( defined $node ) {
    $d++;
    $node = $node->getParentNode ();
  }

  return $d;
}

sub insert_before {
  my ($ref, $new_node) = @_;
  my $parent = $ref->getParentNode ();
  if ( defined $parent ) {
    $parent->insertBefore ($new_node, $ref);
  }
}

sub insert_after {
  my ($ref, $new_node) = @_;

  my $next = $ref->getNextSibling ();
  if ( !defined $next ) {
    my $parent = $ref->getParentNode ();
    if ( defined $parent ) {
      $parent->appendChild ($new_node);
    }
  } else {
    insert_before ($next, $new_node);
  }
}

sub remove {
  my ($node) = @_;

  my $parent = $node->getParentNode ();
  if ( defined $parent ) {
    $parent->removeChild ($node);
  }
}

sub element_text {
  my ($node) = @_;
  return $node->getFirstChild()->getNodeValue();
}


######################################################################
# Print a DOM tree to stdout
######################################################################

sub print {
  my ($fh, $node) = @_;
  XML::Xerces::DOMParse::parse_nodes($node, \&parse_nodes_to_print, $fh);
}

sub parse_nodes_to_print {
  my ($node, $fh) = @_;
  &$NODE_PRINTER ($fh, $node);
}


sub print_node {
  my ($fh, $node) = @_;

  my $type = $node->getNodeType ();

  if ($type == $XML::Xerces::DOM_Node::DOCUMENT_NODE ) {
    return &$DOCUMENT_NODE_PRINTER ($fh, $node);
  } elsif ($type == $XML::Xerces::DOM_Node::COMMENT_NODE ) {
    return &$COMMENT_NODE_PRINTER ($fh, $node);
  } elsif ($type == $XML::Xerces::DOM_Node::DOCUMENT_TYPE_NODE ) {
    return &$DOCUMENT_TYPE_NODE_PRINTER ($fh, $node);
  } elsif ($type == $XML::Xerces::DOM_Node::CDATA_SECTION_NODE) {
    return &$CDATA_SECTION_NODE_PRINTER ($fh, $node);
  } elsif ($type == $XML::Xerces::DOM_Node::TEXT_NODE) {
    return &$TEXT_NODE_PRINTER ($fh, $node);
  } elsif ($type == $XML::Xerces::DOM_Node::ELEMENT_NODE) {
    return &$ELEMENT_NODE_PRINTER ($fh, $node);
  } elsif ($type == $XML::Xerces::DOM_Node::ENTITY_REFERENCE_NODE) {
    return &$ENTITY_REFERENCE_NODE_PRINTER ($fh, $node);
  } elsif ($type == $XML::Xerces::DOM_Node::PROCESSING_INSTRUCTION_NODE) {
    return &$PROCESSING_INSTRUCTION_NODE_PRINTER ($fh, $node);
  } elsif ($type == $XML::Xerces::DOM_Node::XML_DECL_NODE) {
    return &$XML_DECL_NODE_PRINTER ($fh, $node);
  }

  my $name = $node->getNodeName ();
  my $value = $node->getNodeValue ();
  print STDERR "UNHANDLED (type=$type;name=\"";
  XML::Xerces::DOMParse::print_string ($fh, $name);
  print STDERR "\",value=\"";
  XML::Xerces::DOMParse::print_string ($fh, $value);
  print STDERR "\")\n";
}

#
# printers
#

sub print_xml_decl_node {
  my ($fh,$decl_node) = @_;
  my $string = '<?xml version="' . $decl_node->getVersion() . '"';
  my $encoding = $decl_node->getEncoding();
  $string .= qq[ encoding="$encoding"] if $encoding;
  my $standalone = $decl_node->getStandalone();
  $string .= qq[ standalone="$standalone"] if $standalone;
  print $fh "$string?>\n";
  return 0;			# no children to parse
}

sub print_document_node {
  my ($fh, $node) = @_;
#   my $decl_node = $node->getFirstChild();
#   unless($decl_node->getNodeType() == $XML::Xerces::DOM_Node::XML_DECL_NODE) {
#     die "$0: couldn't find an XMLDecl node, try \$parser->setToCreateXMLDeclTypeNode(1)";
#   }
  return 1;			# children to parse
}

sub print_document_type_node {
  my ($fh, $node) = @_;
  my $name = $node->getName ();
  print $fh "<!DOCTYPE ";
  XML::Xerces::DOMParse::print_string ($fh, $name);
  if ($node->getPublicId()) {
    print $fh " PUBLIC ";
    print $fh "'", $node->getPublicId(), "' ";
  } elsif ($node->getSystemId()) {
    print $fh " SYSTEM ";
    print $fh "'", $node->getSystemId(), "' ";
  } else {
    print STDERR "Couldn't find either SYSTEM id or PUBLIC id for DOCTYPE\n";
  }
  if ($node->getInternalSubset()) {
    print $fh "[", $node->getInternalSubset(), "]";
  }
  print $fh ">\n";
  return 0;			# no children to parse
}

sub print_text_node {
  my ($fh, $node) = @_;
  my $value = $node->getNodeValue ();
  XML::Xerces::DOMParse::print_string ($fh, $value);
  return 0;			# no children to parse
}

sub print_comment_node {
  my ($fh, $node) = @_;
  my $value = $node->getNodeValue ();
  print $fh "<!--";
  XML::Xerces::DOMParse::print_string ($fh,$value);
  print $fh "-->\n";
  return 0;			# no children to parse
}

sub print_cdata_section_node {
  my ($fh, $node) = @_;
  my $value = $node->getNodeValue ();
  print $fh "<![CDATA[$value]]>";
  return 0;			# no children to parse
}

sub print_element_node {
  my ($fh, $node) = @_;
  my $name = $node->getNodeName ();
  my $value = $node->getNodeValue ();

  if ( $node->hasChildNodes() ) {
    print $fh "<";
    XML::Xerces::DOMParse::print_string ($fh,$name); 
    &$ATTRIBUTE_PRINTER ($fh, $node);
    print $fh ">";
    XML::Xerces::DOMParse::parse_child_nodes ($node->getFirstChild(), \&parse_nodes_to_print, $fh);
    print $fh "</";
    XML::Xerces::DOMParse::print_string ($fh,$name);
    print $fh ">";
  } else {
    print $fh "<";
    XML::Xerces::DOMParse::print_string ($fh,$name);
    &$ATTRIBUTE_PRINTER ($fh, $node);
    print $fh "/>";
  }
  return 0;			# children have already been parsed
}

sub print_entity_reference_node {
  my ($fh, $node) = @_;
  return 1;			# children to parse
}

sub print_processing_instruction_node {
  my ($fh, $node) = @_;
  my $name = $node->getNodeName ();
  my $value = $node->getNodeValue ();
  print $fh "<?";
  XML::Xerces::DOMParse::print_string ($fh, "$name $value");
  print $fh "?>\n";
  return 0;			# no children to parse
}

sub print_attributes {
  my ($fh, $node) = @_;

  my $attributes = $node->getAttributes ();
  my $attr_count = $attributes->getLength ();

  for ( my $i=0; $i<$attr_count; $i++ ) {
    my $attr = $attributes->item ($i);
    my $name = $attr->getNodeName ();
    my $value = $attr->getNodeValue ();
    print $fh " ";
    XML::Xerces::DOMParse::print_string ($fh, $name);
    print $fh "=\"";
    XML::Xerces::DOMParse::print_string ($fh, $value);
    print $fh "\"";
  }
}

sub print_string {
  my ($fh, $string) = @_;

  if ( $ESCAPE == 1 ) {
    my $newstring = "";
    while ( $string =~ /^(.*?)&(.*)$/ ) {
      $newstring = $newstring . $1 . "&amp;";
      $string = $2;
    }	
    $string = $newstring . $string;

    while ( $string =~ s/^(.*?)<(.*)$/$1&lt;$2/) {
    }
    ;
    while ( $string =~ s/^(.*?)>(.*)$/$1&gt;$2/) {
    }
    ;
    while ( $string =~ s/^(.*?)\"(.*)$/$1&quot;$2/) {
    }
    ;
  }
  print $fh "$string";
}


######################################################################
# Remove formatting (white space) from a formatted DOM tree
######################################################################

sub unformat {
  my ($node) = @_;
  XML::Xerces::DOMParse::parse_nodes ($node, \&XML::Xerces::DOMParse::remove_white_space);
}

sub remove_white_space {
  my ($node) = @_;

  if ( $node->getNodeType () == $XML::Xerces::DOM_Node::TEXT_NODE ) {
    my $value = $node->getNodeValue ();
    $value =~ s/\s*(.*?)\s*/$1/;
    if ( $value eq "" ) {
      XML::Xerces::DOMParse::remove ($node);
    } else {
      $node->setNodeValue ($value);
    }
  }

  return 1;			#proceed
}


######################################################################
# Add formatting (white space) to an unformatted DOM tree
######################################################################

sub format {
  my ($node) = @_;
  my $doc = XML::Xerces::DOMParse::doc ($node);
  XML::Xerces::DOMParse::parse_nodes ($node, \&XML::Xerces::DOMParse::add_white_space, $doc);
}

sub add_white_space {
  my ($node, $doc) = @_;

  my $level = XML::Xerces::DOMParse::depth($node);

  if ( $level > 1 && $node->getNodeType () == $XML::Xerces::DOM_Node::ELEMENT_NODE ) {

    my $formatText = XML::Xerces::DOMParse::create_format_text ($doc, $level-1);
    XML::Xerces::DOMParse::insert_before ($node, $formatText);

    if ( !defined $node->getNextSibling() ) {
      my $formatText = XML::Xerces::DOMParse::create_format_text ($doc, $level-2);
      XML::Xerces::DOMParse::insert_after ($node, $formatText);
    }

  }

  return 1;			#proceed
}

sub create_format_text {
  my ($doc, $level) = @_;

  my $text = "\n";
  for (my $i=0; $i<$level; $i++) {
    $text .= $INDENT;
  }
		
  return $doc->createTextNode ($text);
}



1;


=head1 NAME

XML::Xerces::DOMParse -  A Perl module for parsing DOMs.  

=head1 SYNOPSIS


	# Here;s an example that reads in an XML file from the 
	# command line and then removes all formatting, re-adds
	# formatting and then prints the DOM back to a file.

	use XML::Xerces;
	use XML::Xerces::DOMParse;

	my $parser = new XML::Xerces::DOMParser ();
	$parser->parse ($ARGV[0]);
	my $doc = $parser->getDocument ();

	XML::Xerces::DOMParse::unformat ($doc);
	XML::Xerces::DOMParse::format ($doc);
	XML::Xerces::DOMParse::print (\*STDOUT, $doc);



=head1 DESCRIPTION

Use this module in conjunction with XML::Xerces.  Once you have 
read an XML file into a DOM tree in memory, this module provides
routines for recursive descent parsing of the DOM tree.  It also
provides three concrete and useful functions to format, unformat 
and print DOM trees, all which are built on the more general
parsing functions.

=head1 FUNCTIONS

=head2 DOMParse::unformat ($node)

Processes $node and its children recursively and removes all white 
space text nodes.  It is often difficult to process a DOM tree with
formatting while preserving reasonable formatting.  Use unformat to
remove formatting, then proces the unformatted DOM, then use format
to add formatting back in that is reasonable for the new tree.

=head2 DOMParse::format ($node)

Processes $node and its children recursively and introduces white
space text nodes to create a DOM tree that will print with 
reasonable indents and newlines.  Only call format on a DOM tree
that nas no formatting white space in it.  Otherwise the results
will be incorrect.  Call unformat to remove formatting white space.

You can optionally set the string variable $INDENT to 
the indent characters you want to use.  By default it is a single
tab.

=head2 DOMParse::print ($file_handle, $node)

Processes $node and its children recursively and prints the DOM
tree to $file_handle as a standard XML file.  You can override
printing behavior by supplying any of several "printer" functions.

	$NODE_PRINTER
	$DOCUMENT_NODE_PRINTER
	$DOCUMENT_TYPE_NODE_PRINTER
	$COMMENT_NODE_PRINTER
	$TEXT_NODE_PRINTER
	$CDATA_SECTION_NODE_PRINTER
	$ELEMENT_NODE_PRINTER
	$ENTITY_REFERENCE_NODE_PRINTER 
	$PROCESSING_INSTRUCTION_NODE_PRINTER
	$ATTRIBUTE_PRINTER

Some of these printers call other printers.  For example, 
$NODE_PRINTER determines the node type and calls
the correponsing printer for that type, e.g. 
$ELEMENT_NODE_PRINTER.  So if you replace a printer
for a node which has children, you must take the responsibility
for calling the child node printers.  

All printers take two parameters, a file handle and the node.
See DOMParse::parse_nodes and DOMParse::parse_child_nodes for details.

It is very easy to write a replacement printer that adds value
and then calls the default processing as follows.

	my $original_text_node_printer = $TEXT_NODE_PRINTER;
	$TEXT_NODE_PRINTER = \&my_text_node_printer;

	sub my_text_node_printer {
	  my ($fh, $node) = @_;
	  # look at the text node and do something extra
	  return &$original_text_node_printer ($fh, $node);
	}	

The $ESCAPE variable (integer) controls whether special
XML characters like ampersand "&" are escaped, e.g. "&amp;".  Set
$ESCAPE to 1 (default) to escape special characters, or
to 0 to print characters literally.

=head2 print_string ($file_handle, $node)

Call print_string whenever you need to expand special 
characters (& < > ") to their escape sequence equivalents.  
The print_string is used extensively
by the default implementation of DOMParse::print.  When you replace
various node printers, you should also be careful to use it to print 
node and attribute names and values (but probably not anything else).

The print function respects the global $ESCAPE flag.  By 
default it is set to true (1) and escape conversion is performed.
Set it to false (0) when you don't want escape conversion.

=head2 parse_nodes ($node, $process_node, $data)

Call parse_nodes to parse $node and all of its children
recursively.  Each node will be visited and your
parsing function, $process_node, will be called.
Optional data $data will be passed through if provided.

Your parsing funtion must have the following signature.

	process_node ($node, $data)

If it returns 1 then children of $node will also be parsed.
If it returns 0 then they won't.  It is common to use 
one parsing function to get to a certain level in the DOM
tree, then to return 0 and to call parse_child_nodes to
parse nodes under that level with a different processing
function.

=head2 parse_child_nodes ($node, $process_node, $data)

Call to parse the children of $node recursively.  This is just
like parse_nodes except that $node is not parsed.

=head2 doc ($node)

Looks up the DOM tree until it finds the document node
associated with the given $node.  Then returns the
document node.

=head2 depth ($node)

Returns the depth of the specified $node in the DOM document.
The document has depth 0, the root node has depth 1, and so on.

=head2 element_text ($node)

It is common practice to have an element node that encloses
a single text node.  If you know you have such a node, you
can call element_text to directly access the enclosed text
as a string.  This is faster than accessing the enclosed
text node and then getting the value of it.

=head2 insert_before ($ref_node, $new_node)

Inserts $new_node in the DOM tree immediately before and as
a sibling of $ref_node.  It is safe to call insert_before
while in the middle of parsing a DOM tree if $ref_node is
the current node being parsed.  The newly inserted node will 
not be parsed.

=head2 insert_after ($ref_node, $new_node)

Inserts $new_node in the DOM tree immediately after and as
a sibling of $ref_node.  It is safe to call insert_after
while in the middle of parsing a DOM tree if $ref_node is
the current node being parsed.  The newly inserted node will 
not be parsed.

=head2 remove ($node)

Removes $node from the DOM tree.  It is safe to call remove
while in the middle of parsing a DOM tree if $node is the 
current node being parsed.  The next node to be parsed will 
be the same that would have been parsed had $node not been 
removed, e.g. $node's next sibling.

=head1 AUTHORS

Tom Watson <F<rtwatson@us.ibm.com>> wrote version 1.0 and submitted to
the XML Apache project <F<http://xml.apache.org>>, where you can contribute 
to future versions and where the corresponding C++ and Java compilers are
also developed as OpenSource projects.

Jason Stewart <F<jason@openinformatics.com>> adapted it to the
Xerces-1.3 API. 

=head1 BUGS

Any comments or questions about this module can be addressed to the
Xerces.pm development list <F<xerces-p-dev@xml.apache.org>>

=cut



