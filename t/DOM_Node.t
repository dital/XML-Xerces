# Before `make install' is performed this script should be runnable
# with `make test'. After `make install' it should work as `perl
# DOM_Node.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
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

my $DOM1 = new XML::Xerces::DOMParser;
my $ERROR_HANDLER = XML::Xerces::PerlErrorHandler->new();
$DOM1->setErrorHandler($ERROR_HANDLER);
$DOM1->parse(XML::Xerces::MemBufInputSource->new($document));

my $DOM2 = new XML::Xerces::DOMParser;
$DOM2->setErrorHandler($ERROR_HANDLER);
$DOM2->parse(XML::Xerces::MemBufInputSource->new($document, 'foo'));

my $doc1 = $DOM1->getDocument();
my $doc2 = $DOM2->getDocument();

my $root1 = $doc1->getDocumentElement();
my @persons1 = $doc1->getElementsByTagName('person');
my @names1 = $doc1->getElementsByTagName('name');
my $root2 = $doc2->getDocumentElement();
my @persons2 = $doc2->getElementsByTagName('person');
my @names2 = $doc1->getElementsByTagName('name');

# importing a child from a different document
eval {
  my $copy = $doc1->importNode($persons1[0],0);
  $root1->appendChild($copy);
};
result(!$@ &&
      scalar @persons1 < scalar ($root1->getElementsByTagName('person')));
