# Before `make install' is performed this script should be runnable
# with `make test'. After `make install' it should work as `perl
# MemBufInputSource.t'

######################### We start with some black magic to print on failure.

END {ok(0) unless $loaded;}

use Carp;
# use blib;
use XML::Xerces;
use Test::More tests => 4;

use lib 't';
use TestUtils qw($DOM $PERSONAL_NO_DOCTYPE);
use vars qw($loaded);
use strict;

$loaded = 1;
ok($loaded, "module loaded");

######################### End of black magic.

my $is = eval{XML::Xerces::MemBufInputSource->new($PERSONAL_NO_DOCTYPE,'foo')};
XML::Xerces::error($@) if $@;
ok(UNIVERSAL::isa($is,'XML::Xerces::InputSource')
   && $is->isa('XML::Xerces::MemBufInputSource')
  );

eval {$DOM->parse($is)};
XML::Xerces::error($@) if $@;
my $serialize = $DOM->getDocument->serialize;
ok($serialize eq $PERSONAL_NO_DOCTYPE);

# now test that the fake system ID is optional
$is = eval{XML::Xerces::MemBufInputSource->new($PERSONAL_NO_DOCTYPE)};
XML::Xerces::error($@) if $@;
ok($is->getSystemId() eq 'FAKE_SYSTEM_ID');
