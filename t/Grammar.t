# Before `make install' is performed this script should be runnable
# with `make test'. After `make install' it should work as `perl
# DOM_Attr.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Carp;
# use blib;
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

# test that we can fetch the grammar
my $grammar = $DOM->getValidator->getGrammar->getGrammarType();
result($grammar == $XML::Xerces::Grammar::DTDGrammarType);
