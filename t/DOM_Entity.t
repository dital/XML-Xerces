# Before `make install' is performed this script should be runnable
# with `make test'. After `make install' it should work as `perl
# DOM_Entity.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use Carp;
use XML::Xerces;

use lib 't';
use TestUtils qw(result $DOM);
use vars qw($i $loaded);
use strict;

$loaded = 1;
$i = 1;
result($loaded);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $document = <<'EOT';
<?xml version="1.0" encoding="ISO-8859-1" standalone="yes"?>
<!DOCTYPE foo [
<!ENTITY data2    "DATA">
<!ENTITY data   "DATA">
<!ENTITY bar    "BAR">
<!ELEMENT  foo        ANY>
]>
<foo>This is a test &data; of entities</foo>
EOT

$DOM->setCreateEntityReferenceNodes(1);
$DOM->setValidationScheme($XML::Xerces::DOMParser::Val_Never);
my $is = XML::Xerces::MemBufInputSource->new($document);
$DOM->parse($is);

my $doc = $DOM->getDocument();
my $doctype = $doc->getDoctype();

# get the single <element> node
my %ents = $doctype->getEntities();
result(exists $ents{data} && $ents{data} eq 'DATA');

result(exists $ents{bar} && $ents{bar} eq 'BAR', my $fail=1);
