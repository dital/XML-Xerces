# Before `make install' is performed this script should be runnable
# with `make test'. After `make install' it should work as `perl
# DOMException.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

END {ok(0) unless $loaded;}

use Carp;
# use blib;
use XML::Xerces;
use Test::More tests => 7;
use Config;

use lib 't';
use vars qw($loaded);
use strict;

$loaded = 1;
ok($loaded, "module loaded");

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):


my $impl = XML::Xerces::DOMImplementation::getImplementation();
my $dt = $impl->createDocumentType('Foo', 'foo', 'Foo.dtd');
my $doc = $impl->createDocument('Foo', 'foo',$dt);
eval {
  $impl->createDocument('Bar', 'bar',$dt);
};
my $error = $@;
ok($error &&
   UNIVERSAL::isa($error,'XML::Xerces::DOMException') &&
   $error->{code} == $XML::Xerces::DOMException::WRONG_DOCUMENT_ERR
  );

# Create a couple of identical test documents
my $document = q[<?xml version="1.0" encoding="UTF-8"?>
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

my $DOM1 = new XML::Xerces::XercesDOMParser;
my $ERROR_HANDLER = XML::Xerces::PerlErrorHandler->new();
$DOM1->setErrorHandler($ERROR_HANDLER);
my $is = eval{XML::Xerces::MemBufInputSource->new($document)};
XML::Xerces::error($@) if $@;
eval{$DOM1->parse($is)};
XML::Xerces::error($@) if $@;

my $DOM2 = new XML::Xerces::XercesDOMParser;
$DOM2->setErrorHandler($ERROR_HANDLER);
eval {$DOM2->parse($is)};
XML::Xerces::error($@) if $@;

my $doc1 = $DOM1->getDocument();
my $doc2 = $DOM2->getDocument();

my $root1 = $doc1->getDocumentElement();
my @persons1 = $root1->getChildNodes();
my $name1 = ($persons1[1]->getChildNodes())[1];
my $root2 = $doc2->getDocumentElement();
my @persons2 = $root2->getChildNodes();
my $name2 = ($persons2[1]->getChildNodes())[1];

# Trying to append to a DOMDocument node gives a hierarchy error
eval {
  $doc1->appendChild($root2);
};
$error = $@;
ok($error &&
   UNIVERSAL::isa($error,'XML::Xerces::DOMException') &&
   $error->{code} == $XML::Xerces::DOMException::HIERARCHY_REQUEST_ERR
  );

# Trying to append to a different DOMDocument gives a wrong doc error
eval {
  $root1->appendChild($root2);
};
$error = $@;
ok($error &&
   UNIVERSAL::isa($error,'XML::Xerces::DOMException') &&
   $error->{code} == $XML::Xerces::DOMException::WRONG_DOCUMENT_ERR
  );

# Trying to insert to a different DOMDocument gives a wrong doc error
eval {
  $persons1[1]->insertBefore($persons2[1],$persons1[1]);
};
$error = $@;
ok($error &&
   UNIVERSAL::isa($error,'XML::Xerces::DOMException') &&
   $error->{code} == $XML::Xerces::DOMException::WRONG_DOCUMENT_ERR
  );

# Trying to insert to a DOMDocument node gives a wrong doc error
eval {
  $doc1->insertBefore($persons2[1],$root1);
};
$error = $@;
ok($error &&
   UNIVERSAL::isa($error,'XML::Xerces::DOMException') &&
   $error->{code} == $XML::Xerces::DOMException::HIERARCHY_REQUEST_ERR
  );

# Trying to insert before a node that is not a subnode of the calling node
# gives a not found error
eval {
  $persons1[1]->insertBefore($name1,$persons1[3]);
};
$error = $@;
ok($error &&
   UNIVERSAL::isa($error,'XML::Xerces::DOMException') &&
   $error->{code} == $XML::Xerces::DOMException::NOT_FOUND_ERR
  );

# print STDERR "Code = $code\n";
# print STDERR "Eval = $@\n";
# print STDERR "Error = $error\n";
