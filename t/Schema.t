# Before `make install' is performed this script should be runnable
# with `make test'. After `make install' it should work as `perl
# Schema.t

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use Carp;
# use blib;
use XML::Xerces;

use lib 't';
use TestUtils qw(result $PERSONAL_SCHEMA_FILE_NAME);
use vars qw($i $loaded $file);
use strict;

$loaded = 1;
$i = 1;
result($loaded);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $dom = XML::Xerces::DOMParser->new();
my $handler = XML::Xerces::PerlErrorHandler->new();
$dom->setDoSchema(1);
$dom->setDoNamespaces(1);
$dom->setErrorHandler($handler);

# test a valid file
eval {
  $dom->parse($PERSONAL_SCHEMA_FILE_NAME);
};
result(!$@);

# test an invalid file
open(IN,$PERSONAL_SCHEMA_FILE_NAME)
  or die "Couldn't open $PERSONAL_SCHEMA_FILE_NAME for reading";
my $buf;
while (<IN>) {
  if (m|</personnel>|) {
    s|</personnel>|</foo>|;
  }
  $buf .= $_;
}
# print STDERR $buf;
eval {
  $dom->parse(XML::Xerces::MemBufInputSource->new($buf));
};
result($@);
