# Before `make install' is performed this script should be runnable
# with `make test'. After `make install' it should work as `perl
# DOM_Attr.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use Carp;
# use blib;
use utf8;
use XML::Xerces;

use lib 't';
use TestUtils qw(result is_object $DOM $PERSONAL_FILE_NAME);
use vars qw($i $loaded);
use strict;

$loaded = 1;
$i = 1;
result($loaded);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$DOM->parse($PERSONAL_FILE_NAME);

my $doc = $DOM->getDocument();
my $doctype = $doc->getDoctype();
my @persons = $doc->getElementsByTagName('person');

# test getting the attribute node
my $attr = $persons[0]->getAttributeNode('id');
result(is_object($attr)
       && $attr->isa('XML::Xerces::DOM_Attr')
      );

# test getting the attribute value
result($attr->getValue() eq $persons[0]->getAttribute('id'));

# test that we can use integers and floats as values for setting attribtes
eval {
  $attr->setValue(3);
};
result(!$@);

eval {
  $attr->setValue(.03);
};
result(!$@);
