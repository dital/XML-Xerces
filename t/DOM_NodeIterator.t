# Before `make install' is performed this script should be runnable
# with `make test'. After `make install' it should work as `perl
# DOM_NodeIterator.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use Carp;

# use blib;
use XML::Xerces;
use Config;

use lib 't';
use TestUtils qw(result is_object);
use vars qw($i $loaded);
use strict;

$loaded = 1;
$i = 1;
result($loaded);

package MyNodeFilter;
use strict;
use vars qw(@ISA);
@ISA = qw(XML::Xerces::PerlNodeFilter);
sub acceptNode {
  my ($self,$node) = @_;
  return $XML::Xerces::DOM_NodeFilter::FILTER_ACCEPT;
}

package main;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# Create a couple of identical test documents
my $document = q[<?xml version="1.0" encoding="utf-8"?>
<contributors>
	<person Role="manager">
		<name>Mike Pogue</name>
		<email>mpogue@us.ibm.com</email>
	</person>
	<person Role="developer">
		<name>Tom Watson</name>
		<email>rtwatson@us.ibm.com</email>
	</person>
	<person Role="tech writer">
		<name>Susan Hardenbrook</name>
		<email>susanhar@us.ibm.com</email>
	</person>
</contributors>];

my $DOM = new XML::Xerces::DOMParser;
my $ERROR_HANDLER = XML::Xerces::PerlErrorHandler->new();
$DOM->setErrorHandler($ERROR_HANDLER);
$DOM->parse(XML::Xerces::MemBufInputSource->new($document));

my $doc = $DOM->getDocument();
my $root = $doc->getDocumentElement();
my $filter = MyNodeFilter->new();
my $what = $XML::Xerces::DOM_NodeFilter::SHOW_ELEMENT;
my $iterator = $doc->createNodeIterator($root,$what,$filter,1);
result(defined $iterator
      and is_object($iterator)
      and $iterator->isa('XML::Xerces::DOM_NodeIterator'));

# test that nextNode() returns the first node in the set
result($iterator->nextNode() == $root);

my $success = 1;
my $count = 0;
while (my $node = $iterator->nextNode()) {
  $count++;
  $success = 0 unless $node->isa('XML::Xerces::DOM_Element');
}
# test that we only got elements
result($success);

#test that we got all the elements
result($count == 9);
