# Before `make install' is performed this script should be runnable
# with `make test'. After `make install' it should work as `perl
# actualCast.t'

######################### We start with some black magic to print on failure.

END {ok(0) unless $loaded;}

use Carp;
# use blib;
use XML::Xerces;
use Test::More tests => 3;

use lib 't';
use TestUtils qw($DOM $PERSONAL $PERSONAL_FILE_NAME);
use vars qw($loaded);
use strict;

$loaded = 1;
ok($loaded, "module loaded");

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$DOM->parse( new XML::Xerces::LocalFileInputSource($PERSONAL_FILE_NAME) );

# test that we get a subclass of DOMNode back
my $name = $DOM->getDocument->getElementsByTagName('link')->item(0);
ok(ref($name) && $name->isa('XML::Xerces::DOMNode'));

# test that it really is a subclass
ok(ref($name) ne 'XML::Xerces::DOMNode');
