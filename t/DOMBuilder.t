# Before `make install' is performed this script should be runnable
# with `make test'. After `make install' it should work as `perl
# DOMParser.t'

######################### We start with some black magic to print on failure.

END {fail() unless $loaded;}

use Carp;
# use blib;
use XML::Xerces qw(error);
use Test::More tests => 12;
use Config;

use lib 't';
use TestUtils qw($PERSONAL_FILE_NAME);
use vars qw($loaded $error);
use strict;

$loaded = 1;
pass('module loaded');

######################### End of black magic.

my $document = q[<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
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

my $impl = XML::Xerces::DOMImplementationRegistry::getDOMImplementation('LS');
my $DOM = $impl->createDOMBuilder($XML::Xerces::DOMImplementationLS::MODE_SYNCHRONOUS,'');
SKIP: {
  skip "DOMErrorHandler not implemented", 1;
  $DOM->setErrorHandler(XML::Xerces::PerlErrorHandler->new());
  pass('setErrorHandler');
}
if ($DOM->canSetFeature("$XML::Xerces::XMLUni::fgDOMValidation", 1)) {
  $DOM->setFeature("$XML::Xerces::XMLUni::fgDOMValidation", 1);
  pass('validation=>1');
} else {
  fail('validation=>1');
}
if ($DOM->canSetFeature("$XML::Xerces::XMLUni::fgDOMValidateIfSchema", 0)) {
  $DOM->setFeature("$XML::Xerces::XMLUni::fgDOMValidateIfSchema", 0);
  pass('validate_if_schema=>1');
} else {
  fail('validate_if_schema=>1');
}

SKIP: {
  skip "DOMInputSource not implemented", 2;
  my $is = eval{$impl->createDOMInputSource()};
  ok(defined $is)
    or diag
      $is->setSystemId($PERSONAL_FILE_NAME);
  eval{$DOM->parse($is)};
  ok((not $@),'parse input source');
}

my $doc = eval{$DOM->parseURI($PERSONAL_FILE_NAME)};
ok((not $@),'parseURI');
isa_ok($doc,'XML::Xerces::DOMDocument');

my @persons = $doc->getElementsByTagName('person');
is(scalar @persons, 6,'getting <person>s');

# test the overloaded parse version
$doc = eval{$DOM->parseURI("file:$PERSONAL_FILE_NAME")};
ok((not $@),'parseURI with file:');
isa_ok($doc,'XML::Xerces::DOMDocument');

@persons = $doc->getElementsByTagName('person');
is(scalar @persons, 6,'getting <person>s');

