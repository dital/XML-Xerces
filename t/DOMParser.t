# Before `make install' is performed this script should be runnable
# with `make test'. After `make install' it should work as `perl
# DOMParser.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok 1\n" unless $loaded;}
use Carp;
# use blib;
use XML::Xerces;

use lib 't';
use TestUtils qw(result $PERSONAL_FILE_NAME $PERSONAL_NO_DOCTYPE $PERSONAL $DOM);
use vars qw($i $loaded);
use strict;

$loaded = 1;
$i = 1;
result($loaded);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

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

my $is;
eval {
  $is = XML::Xerces::MemBufInputSource->new($PERSONAL_NO_DOCTYPE, 'foo');
};
error($@) if $@;

eval {
  $DOM->parse($is);
};
error($@) if $@;

my $serialize = $DOM->getDocument->serialize;
result($serialize eq $PERSONAL_NO_DOCTYPE);

# now test reparsing a file
$DOM->reset();
eval {
  $is = XML::Xerces::MemBufInputSource->new($document, 'foo');
};
error($@) if $@;

eval {
  $DOM->parse($is);
};
result(!$@);
error($@) if $@;

my $doc = $DOM->getDocument();
my @persons = $doc->getElementsByTagName('person');
result(scalar @persons == 3);

result($persons[0]->getAttributes()->getLength == 1);

result($persons[0]->getAttribute('Role') eq 'manager');

# now test the overloaded methods in DOMParser
eval {
  $DOM->parse($PERSONAL_FILE_NAME);
};
result(!$@);
error($@) if $@;

$DOM = XML::Xerces::DOMParser->new();
$DOM->setValidationScheme($XML::Xerces::DOMParser::Val_Always);
$DOM->setIncludeIgnorableWhitespace(0);
eval {
  $DOM->parse($PERSONAL_FILE_NAME);
};
error($@) if $@;

# now check that we do *not* get whitespace nodes
my @nodes = $DOM->getDocument->getDocumentElement->getChildNodes();
result(scalar @nodes == 6);
