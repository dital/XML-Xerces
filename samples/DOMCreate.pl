######################################################################
#
# The Apache Software License, Version 1.1
# 
# Copyright (c) 1999 The Apache Software Foundation.  All rights 
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
# DOMCreate
#
# This sample creates a DOM document in memory and then outputs
# the "printed" form of the document.
#
######################################################################

use strict;

use blib;
use XML::Xerces;

#
# create a document
#

my $impl = XML::Xerces::DOMImplementationRegistry::getDOMImplementation('LS');
my $dt = eval{$impl->createDocumentType('contributors', '', 'contributors.dtd')};
XML::Xerces::error($@) if $@;
my $doc = eval{$impl->createDocument('contributors', 'contributors',$dt)};
XML::Xerces::error($@) if $@;

my $root = $doc->getDocumentElement();

$root->appendChild(CreatePerson(	
	$doc,
	'Mike Pogue',
	'manager',
	'mpogue@us.ibm.com'
));

$root->appendChild(CreatePerson(
	$doc,
	'Tom Watson',
	'developer',
	'rtwatson@us.ibm.com'
));

$root->appendChild(CreatePerson(
	$doc,
	'Susan Hardenbrook',
	'tech writer',
	'susanhar@us.ibm.com'
));

my $writer = $impl->createDOMWriter();
if ($writer->canSetFeature('format-pretty-print',1)) {
  $writer->setFeature('format-pretty-print',1);
}
my $target = XML::Xerces::StdOutFormatTarget->new();
$writer->writeNode($target,$doc);


#################################################################
# routines to create the document
# no magic here ... they just organize many DOM calls
#################################################################


sub CreatePerson {
  my ($doc, $name, $role, $email) = @_;
  my $person = $doc->createElement ("person");
  &SetName ($doc, $person, $name);
  &SetEmail ($doc, $person, $email);
  $person->setAttribute ("Role", $role);
  return $person;
}


sub SetName {
  my ($doc, $person, $nameText) = @_;
  my $nameNode = $doc->createElement ("name");
  my $nameTextNode = $doc->createTextNode ($nameText);
  $nameNode->appendChild ($nameTextNode);
  $person->appendChild ($nameNode);
}


sub SetEmail {
  my ($doc, $person, $emailText) = @_;
  my $emailNode = $doc->createElement ("email");
  my $emailTextNode = $doc->createTextNode ($emailText);
  $emailNode->appendChild ($emailTextNode);
  $person->appendChild ($emailNode);
}


__END__




