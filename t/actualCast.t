# Before `make install' is performed this script should be runnable
# with `make test'. After `make install' it should work as `perl
# actualCast.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use Carp;
use XML::Xerces;

use lib 't';
use TestUtils qw(result $DOM $PERSONAL $PERSONAL_FILE_NAME);
use vars qw($i $loaded);
use strict;

$loaded = 1;
$i = 1;
result($loaded);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$DOM->parse( new XML::Xerces::LocalFileInputSource($PERSONAL_FILE_NAME) );

# test that we get a subclass of DOM_Node back
my $name = $DOM->getDocument->getElementsByTagName('link')->item(0);
result(ref($name) && $name->isa('XML::Xerces::DOM_Node'));

# test that it really is a subclass
result(ref($name) ne 'XML::Xerces::DOM_Node');
