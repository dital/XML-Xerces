# Before `make install' is performed this script should be runnable
# with `make test'. After `make install' it should work as `perl
# DOMElement.t'

######################### We start with some black magic to print on failure.

END {ok(0) unless $loaded;}

use Carp;
use XML::Xerces;
use Test::More tests => 4;

use lib 't';
use TestUtils qw($DOM $PERSONAL_FILE_NAME);
use vars qw($loaded);
use strict;

$loaded = 1;
ok($loaded, "module loaded");

######################### End of black magic.

$DOM->parse($PERSONAL_FILE_NAME);

my $doc = $DOM->getDocument();
my $doctype = $doc->getDoctype();
my @persons = $doc->getElementsByTagName('person');
my @names = $doc->getElementsByTagName('name');

# try to set an Attribute, 'foo', to undef
ok(!$persons[0]->setAttribute('foo',undef));

# try to set an Attribute, undef, to 'foo'
ok(!$persons[0]->setAttribute(undef,'foo'));

# ensure that actual_cast() is being called
ok(ref $persons[0] eq 'XML::Xerces::DOMElement');
