# Before `make install' is performed this script should be runnable
# with `make test'. After `make install' it should work as `perl
# DOM_NamedNodeMap.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Carp;
use XML::Xerces;
use Config;

use lib 't';
use TestUtils qw(result $SAMPLE_DIR);
use vars qw($i $loaded);
use strict;

$loaded = 1;
$i = 1;
result($loaded);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $document = q[<!DOCTYPE contributors SYSTEM 'contributors.dtd' >
<contributors>
  <person Role="manager">
    <name>Mike Pogue</name>
    <email>mpogue@us.ibm.com</email>
  </person>
  <person Role="developer">
    <name>Tom Watson</name>
    <email>rtwatson@us.ibm.com</email>
  </person>
  <person Role="tech writer">
    <name>Susan Hardenbrook</name>
    <email>susanhar@us.ibm.com</email>
  </person>
</contributors>];


my $perl = $Config{startperl};
$perl =~ s/^\#!//;
my $cmd = "$perl -Mblib $SAMPLE_DIR/DOMCreate.pl 2>/dev/null";
# print STDERR "Running: $cmd\n";
my $output = `$cmd`;

result($document eq $output);
