# Before `make install' is performed this script should be runnable
# with `make test'. After `make install' it should work as `perl
# SAX2Count.t

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
use TestUtils qw(result $PERSONAL_FILE_NAME $SAMPLE_DIR);
use vars qw($i $loaded $file);
use strict;

$loaded = 1;
$i = 1;
result($loaded);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
my $perl = $Config{startperl};
$perl =~ s/^\#!//;
my @output = split(/\n/,`$perl -Mblib $SAMPLE_DIR/SAX2Count.pl $PERSONAL_FILE_NAME 2>/dev/null`);
$output[1] =~ /\s(\d+)/;
result($1 == 37);
$output[2] =~ /\b(\d+)\b/;
result($1 == 12);
$output[3] =~ /\b(\d+)\b/;
result($1 == 134);
$output[4] =~ /\b(\d+)\b/;
result($1 == 134);
