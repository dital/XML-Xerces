# Before `make install' is performed this script should be runnable
# with `make test'. After `make install' it should work as `perl
# PerlErrorHandler.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use Carp;
# use blib;
use XML::Xerces;

use lib 't';
use TestUtils qw(result $PERSONAL);
use subs qw(warning error fatal_error);
use vars qw($error $loaded $i);

$loaded = 1;
$i = 1;
result($loaded);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $document = <<\END;
<?xml version="1.0" encoding="iso-8859-1" standalone="no"?>

<!-- @version: -->
<personnel>

  <person id="Big.Boss">
    <name><family>Boss</family> <given>Big</given></name>
    <email>chief@foo.com</email>
    <link subordinates="one.worker two.worker three.worker four.worker five.worker"/>
  </person>

  <person id="one.worker">
    <name><family>Worker</family> <given>One</given></name>
    <email>one@foo.com</email>
    <link manager="Big.Boss"/>
  </person>

  <foo id="two.worker">
    <name><family>Worker</family> <given>Two</given></name>
    <email>two@foo.com</email>
    <link manager="Big.Boss"/>
  </person>

  <person id="three.worker">
    <name><family>Worker</family> <given>Three</given></name>
    <email>three@foo.com</email>
    <link manager="Big.Boss"/>
  </person>

  <person id="four.worker">
    <name><family>Worker</family> <given>Four</given></name>
    <email>four@foo.com</email>
    <link manager="Big.Boss"/>
  </person>

  <person id="five.worker">
    <name><family>Worker</family> <given>Five</given></name>
    <email>five@foo.com</email>
    <link manager="Big.Boss"/>
  </person>

</personnel>
END

package MyErrorHandler;
use strict;
use vars qw(@ISA);
@ISA = qw(XML::Xerces::PerlErrorHandler);
sub warning {
  my $LINE = $_[1]->getLineNumber;
  my $COLUMN = $_[1]->getColumnNumber;
  my $MESSAGE = $_[1]->getMessage;
  $::error = <<"EOE";
WARNING:
LINE:    $LINE
COLUMN:  $COLUMN
MESSAGE: $MESSAGE
EOE
  die "\n";
}

sub error {
  my $LINE = $_[1]->getLineNumber;
  my $COLUMN = $_[1]->getColumnNumber;
  my $MESSAGE = $_[1]->getMessage;
  $::error = <<"EOE";
ERROR:
LINE:    $LINE
COLUMN:  $COLUMN
MESSAGE: $MESSAGE
EOE
  die "\n";
}

sub fatal_error {
  my $LINE = $_[1]->getLineNumber;
  my $COLUMN = $_[1]->getColumnNumber;
  my $MESSAGE = $_[1]->getMessage;
  $::error = <<"EOE";
FATAL ERROR:
LINE:    $LINE
COLUMN:  $COLUMN
MESSAGE: $MESSAGE
EOE
  die "\n";
}
1;

package main;

{
  $error = "";

  my $dom = XML::Xerces::DOMParser->new();

  my $error_handler = MyErrorHandler->new();
  $dom->setErrorHandler($error_handler);

  eval {
    $dom->parse(XML::Xerces::MemBufInputSource->new($document, 'foo') );
  };

  my $expected_error = <<EOE;
FATAL ERROR:
LINE:    22
COLUMN:  11
MESSAGE: Expected end of tag 'foo'
EOE
  result($expected_error eq $error);

}

{
  $error = "";

  my $dom = XML::Xerces::DOMParser->new();

  my $error_handler = MyErrorHandler->new();
  $dom->setErrorHandler($error_handler);

  $dom->setValidationScheme($XML::Xerces::DOMParser::Val_Always);
  eval {
    $dom->parse(XML::Xerces::MemBufInputSource->new($document, 'foo') );
  };

  my $expected_error = <<EOE;
ERROR:
LINE:    4
COLUMN:  11
MESSAGE: Unknown element 'personnel'
EOE
  result($expected_error eq $error);
}

