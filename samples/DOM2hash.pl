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
#       "This product includes software developed by the
#        Apache Software Foundation (http://www.apache.org/)."
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

use XML::Xerces qw(error);
use Getopt::Long;
use Data::Dumper;
use strict;
my %OPTIONS;
my $rc = GetOptions(\%OPTIONS,
		    'help'
		   );

my $USAGE = <<"EOU";
usage: $0 xml_file
EOU

die "Bad option: $rc\n$USAGE" unless $rc;
die $USAGE if exists $OPTIONS{help};

die "Must specify input files\n$USAGE" unless scalar @ARGV;

package MyNodeFilter;
use strict;
use vars qw(@ISA);
@ISA = qw(XML::Xerces::PerlNodeFilter);
sub acceptNode {
  my ($self,$node) = @_;
  return $XML::Xerces::DOMNodeFilter::FILTER_ACCEPT;
}

package main;

my $DOM = XML::Xerces::XercesDOMParser->new();
my $ERROR_HANDLER = XML::Xerces::PerlErrorHandler->new();
$DOM->setErrorHandler($ERROR_HANDLER);
eval{$DOM->parse($ARGV[0])};
error($@,"Couldn't parse file: $ARGV[0]")
  if $@;

my $doc = $DOM->getDocument();
my $root = $doc->getDocumentElement();

my $hash = node2hash($root);
print STDOUT Data::Dumper->Dump([$hash]);
exit(0);

sub node2hash {
  my $node = shift;
  my $return = {};

  # build a hasref that represents this element
  $return->{node_name} = $node->getNodeName();
  if ($node->hasAttributes()) {
    my %attrs = $node->getAttributes();
    $return->{attributes} = \%attrs;
  }

  # insert code to handle children
  if ($node->hasChildNodes()) {
    my $text;
    foreach my $child ($node->getChildNodes) {
      push(@{$return->{children}},node2hash($child))
	if $child->isa('XML::Xerces::DOMElement');
      $text .= $child->getNodeValue()
	if $child->isa('XML::Xerces::DOMText');
    }
    $return->{text} = $text
      if $text !~ /^\s*$/;
  }
  return $return;
}
