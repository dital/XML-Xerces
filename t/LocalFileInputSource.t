# Before `make install' is performed this script should be runnable
# with `make test'. After `make install' it should work as `perl
# LocalFileInputSource.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use Carp;
# use blib;
use XML::Xerces;
use Cwd;

use lib 't';
use TestUtils qw(result is_object $DOM $PERSONAL_FILE_NAME $SAMPLE_DIR);
use vars qw($i $loaded $error);
use strict;

$loaded = 1;
$i = 1;
result($loaded);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $is = XML::Xerces::LocalFileInputSource->new($PERSONAL_FILE_NAME);
result(is_object($is)
       && $is->isa('XML::Xerces::InputSource')
       && $is->isa('XML::Xerces::LocalFileInputSource')
      );

# test that a bogus relative path causes an exception
eval {
  $is = XML::Xerces::LocalFileInputSource->new('../foo/bar.xml');
};
my $error = $@;
result($error &&
       is_object($error) &&
       $error->isa('XML::Xerces::XMLException'));

# test that relative paths work
$is = XML::Xerces::LocalFileInputSource->new("$SAMPLE_DIR/personal.xml");
result(is_object($is) && $is->isa('XML::Xerces::LocalFileInputSource'));

# test the overloaded constructor
# this currently segfaults
my $cwd = cwd();
# $is = XML::Xerces::LocalFileInputSource->new($cwd, "$SAMPLE_DIR/personal.xml");
result(is_object($is) && $is->isa('XML::Xerces::LocalFileInputSource'));
