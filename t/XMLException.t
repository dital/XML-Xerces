# Before `make install' is performed this script should be runnable
# with `make test'. After `make install' it should work as `perl
# SAXParser.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use Carp;

# use blib;
use XML::Xerces;
use Config;

use lib 't';
use TestUtils qw(result is_object);
use vars qw($i $loaded $error);
use strict;

$loaded = 1;
$i = 1;
result($loaded);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# test that we get an exception object
eval {
  XML::Xerces::LocalFileInputSource->new('../I/AM/NOT/A/FILE');
};
my $error = $@;
result($error);
result(is_object($error));
result($error->isa('XML::Xerces::XMLException'));
result($error->getCode() == $XML::Xerces::XMLExcepts::File_CouldNotGetBasePathName);
