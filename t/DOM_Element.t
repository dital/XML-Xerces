# Before `make install' is performed this script should be runnable
# with `make test'. After `make install' it should work as `perl
# DOM_Element.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use Carp;
use XML::Xerces;

use lib 't';
use TestUtils qw(result $DOM $PERSONAL_FILE_NAME);
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
my @names = $doc->getElementsByTagName('name');

# try to set an Attribute, 'foo', to undef
result(!$persons[0]->setAttribute('foo',undef));

# try to set an Attribute, undef, to 'foo'
result(!$persons[0]->setAttribute(undef,'foo'));

# ensure that actual_cast() is being called
result(ref $persons[0] eq 'XML::Xerces::DOM_Element');
