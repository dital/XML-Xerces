# Before `make install' is performed this script should be runnable
# with `make test'. After `make install' it should work as `perl
# URLInputSource.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok 1\n" unless $loaded;}
use Carp;
# use blib;
use XML::Xerces;

use lib 't';
use TestUtils qw(result
		 is_object
		 $PERSONAL_FILE_NAME);
use vars qw($i $loaded $error);
use strict;

$loaded = 1;
$i = 1;
result($loaded);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $URL = "file:$PERSONAL_FILE_NAME";
my $xml_url = XML::Xerces::XMLURL->new($URL);
result(is_object($xml_url) && $xml_url->isa('XML::Xerces::XMLURL'));

my $is = XML::Xerces::URLInputSource->new($xml_url);
result(is_object($xml_url) && $is->isa('XML::Xerces::URLInputSource'));

# now test the overloaded constructors
$is = XML::Xerces::URLInputSource->new('file:',"file:$PERSONAL_FILE_NAME");
result(is_object($xml_url) && $is->isa('XML::Xerces::URLInputSource'));

$is = XML::Xerces::URLInputSource->new('file:',"file:$PERSONAL_FILE_NAME", 'foo');
result($is->getPublicId() eq 'foo');

# test that a relative URL causes an exception
eval {
  $is = XML::Xerces::URLInputSource->new('file:',$PERSONAL_FILE_NAME, 'foo');
};
my $error = $@;
result($error &&
       is_object($error) &&
       $error->isa('XML::Xerces::XMLException') &&
       $error->getCode() == $XML::Xerces::XMLExcepts::URL_RelativeBaseURL
       );

# test that a bad protocol
eval {
  $is = XML::Xerces::URLInputSource->new('foo','blorphl://./foo.html', 'foo');
};
$error = $@;
result($error
       && is_object($error)
       && $error->isa('XML::Xerces::XMLException')
       && $error->getCode() == $XML::Xerces::XMLExcepts::URL_UnsupportedProto1
       );

# test a non-existent protocol
eval {
  $is = XML::Xerces::URLInputSource->new('foo','', 'foo');
};
$error = $@;
result($error
       && is_object($error)
       && $error->isa('XML::Xerces::XMLException')
       && $error->getCode() == $XML::Xerces::XMLExcepts::URL_NoProtocolPresent
       );
