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
#
# EnumVal
#
# This sample is modeled after its XML4C counterpart.  You give it an
# XML file and it parses it and enumerates the DTD Grammar. It shows 
# how to access the DTD information stored in the internal data structurs
#
######################################################################

use strict;
use XML::Xerces qw(error);
use Getopt::Long;
use Benchmark;
use vars qw(%OPTIONS);

#
# Read and validate command line args
#

my $USAGE = <<EOU;
USAGE: $0 file
EOU
my $VERSION = q[$Id: DOMCount.pl,v 1.13 2002/08/27 19:33:19 jasons Exp $ ];

my $rc = GetOptions(\%OPTIONS,
		    'help');

die $USAGE if exists $OPTIONS{help};
die $USAGE unless scalar @ARGV;

my $file = $ARGV[0];
-f $file or die "File '$file' does not exist!\n";

my $val_to_use = XML::Xerces::SchemaValidator->new();
my $parser = XML::Xerces::SAXParser->new($val_to_use);
$parser->setValidationScheme ($XML::Xerces::AbstractDOMParser::Val_Auto);
$parser->setErrorHandler(XML::Xerces::PerlErrorHandler->new());
$parser->setDoNamespaces(1);
$parser->setDoSchema(1);

my $t0 = new Benchmark;
eval {$parser->parse ($file)};
error($@) if $@;

my $count = $parser->getErrorCount();
if ($count == 0) {
  my $grammar = $val_to_use->getGrammar();
  printf STDOUT "Found Grammar: %s\n", $grammar;
  my $iterator = $grammar->getElemEnumerator();
  if ($iterator->hasMoreElements()) {
    printf STDOUT "Found Elements\n";
    while ($iterator->hasMoreElements()) {
      my $elem = $iterator->nextElement();
      printf STDOUT "Element Name: %s, Content Model: %s\n",
	$elem->getFullName(),
	$elem->getFormattedContentModel();
      if ($elem->hasAttDefs()) {
	my $attr_list = $elem->getAttDefList();
	while ($attr_list->hasMoreElements()) {
	  my $attr = $attr_list->nextElement();
	  my $type = $attr->getType();
	  my $type_name;
	  if ($type == $XML::Xerces::XMLAttDef::CData) {
	    $type_name = 'CDATA';
	  } elsif ($type == $XML::Xerces::XMLAttDef::ID) {
	    $type_name = 'ID';
	  } elsif ($type == $XML::Xerces::XMLAttDef::Notation) {
	    $type_name = 'NOTATION';
	  } elsif ($type == $XML::Xerces::XMLAttDef::Enumeration) {
	    $type_name = 'ENUMERATION';
	  } elsif ($type == $XML::Xerces::XMLAttDef::Nmtoken
		   or $type == $XML::Xerces::XMLAttDef::Nmtokens
		  ) {
	    $type_name = 'NMTOKEN(S)';
	  } elsif ($type == $XML::Xerces::XMLAttDef::IDRef
		   or $type == $XML::Xerces::XMLAttDef::IDRefs
		  ) {
	    $type_name = 'IDREF(S)';
	  } elsif ($type == $XML::Xerces::XMLAttDef::Entity
		   or $type == $XML::Xerces::XMLAttDef::Entities
		  ) {
	    $type_name = 'ENTITY(IES)';
	  } elsif ($type == $XML::Xerces::XMLAttDef::NmToken
		   or $type == $XML::Xerces::XMLAttDef::NmTokens
		  ) {
	    $type_name = 'NMTOKEN(S)';
	  }
	  printf STDOUT "\tattribute Name: %s, Type: %s\n",
	    $attr->getFullName(),
	      $type_name;
	}
      }
    }
  }
} else {
  print STDERR "Errors occurred, no output available\n";
}
my $t1 = new Benchmark;
my $td = timediff($t1, $t0);

print STDOUT "$file: duration: ", timestr($td), "\n";
exit(0);
