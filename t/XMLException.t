# Before `make install' is performed this script should be runnable
# with `make test'. After `make install' it should work as `perl
# SAXParser.t'

######################### We start with some black magic to print on failure.

END {ok(0) unless $loaded;}

use Carp;

# use blib;
use XML::Xerces;
use Test::More tests => 1;
use Config;

use vars qw($loaded $error);
use strict;

$loaded = 1;
ok($loaded, "module loaded");

######################### End of black magic.

# test that we get an exception object
# 2003-06-10 JES: it seems that this has changed for 2.3 and 
# now a fatal error is thrown at parse time instead
#
# eval {
#   XML::Xerces::LocalFileInputSource->new('../I/AM/NOT/A/FILE');
# };
# my $error = $@;
# ok($error &&
#    UNIVERSAL::isa($error,'XML::Xerces::XMLException') &&
#    $error->getCode() == $XML::Xerces::XMLExcepts::File_CouldNotGetBasePathName);
