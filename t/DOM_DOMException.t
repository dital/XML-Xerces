# Before `make install' is performed this script should be runnable
# with `make test'. After `make install' it should work as `perl
# DOM_DOMException.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..7\n"; }
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


my $impl = XML::Xerces::DOM_DOMImplementation::getImplementation();
my $dt = $impl->createDocumentType('Foo', 'foo', 'Foo.dtd');
my $doc = $impl->createDocument('Foo', 'foo',$dt);
eval {
  $impl->createDocument('Bar', 'bar',$dt);
};
my $error = $@;
result($error && 
       is_object($error) &&
       $error->isa('XML::Xerces::DOM_DOMException') &&
       $error->{code} == $XML::Xerces::DOM_DOMException::WRONG_DOCUMENT_ERR
      );

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
$DOM1->parse(XML::Xerces::MemBufInputSource->new($document, 'foo'));

my $DOM2 = new XML::Xerces::DOMParser;
$DOM2->setErrorHandler($ERROR_HANDLER);
$DOM2->parse(XML::Xerces::MemBufInputSource->new($document, 'foo'));

my $doc1 = $DOM1->getDocument();
my $doc2 = $DOM2->getDocument();

my $root1 = $doc1->getDocumentElement();
my @persons1 = $root1->getChildNodes();
my $name1 = ($persons1[1]->getChildNodes())[1];
my $root2 = $doc2->getDocumentElement();
my @persons2 = $root2->getChildNodes();
my $name2 = ($persons2[1]->getChildNodes())[1];

# Trying to append to a DOM_Document node gives a hierarchy error
eval {
  $doc1->appendChild($root2);
};
$error = $@;
result($error && 
       is_object($error) &&
       $error->isa('XML::Xerces::DOM_DOMException') &&
       $error->{code} == $XML::Xerces::DOM_DOMException::HIERARCHY_REQUEST_ERR
      );

# Trying to append to a different DOM_Document gives a wrong doc error
eval {
  $root1->appendChild($root2);
};
$error = $@;
result($error && 
       is_object($error) &&
       $error->isa('XML::Xerces::DOM_DOMException') &&
       $error->{code} == $XML::Xerces::DOM_DOMException::WRONG_DOCUMENT_ERR
      );

# Trying to insert to a different DOM_Document gives a wrong doc error
eval {
  $persons1[1]->insertBefore($persons2[1],$persons1[1]);
};
$error = $@;
result($error && 
       is_object($error) &&
       $error->isa('XML::Xerces::DOM_DOMException') &&
       $error->{code} == $XML::Xerces::DOM_DOMException::WRONG_DOCUMENT_ERR
      );

# Trying to insert to a DOM_Document node gives a wrong doc error
eval {
  $doc1->insertBefore($persons2[1],$root1);
};
$error = $@;
result($error && 
       is_object($error) &&
       $error->isa('XML::Xerces::DOM_DOMException') &&
       $error->{code} == $XML::Xerces::DOM_DOMException::HIERARCHY_REQUEST_ERR
      );

# Trying to insert before a node that is not a subnode of the calling node
# gives a not found error
eval {
  $persons1[1]->insertBefore($name1,$persons1[3]);
};
$error = $@;
result($error && 
       is_object($error) &&
       $error->isa('XML::Xerces::DOM_DOMException') &&
       $error->{code} == $XML::Xerces::DOM_DOMException::NOT_FOUND_ERR
      );

# print STDERR "Code = $code\n";
# print STDERR "Eval = $@\n";
# print STDERR "Error = $error\n";
