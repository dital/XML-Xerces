# Before `make install' is performed this script should be runnable
# with `make test'. After `make install' it should work as `perl
# SAXParser.t'

######################### We start with some black magic to print on failure.

END {ok(0) unless $loaded;}

use Carp;
# use blib;
use XML::Xerces;
use Test::More tests => 8;
use Config;

use lib 't';
use TestUtils qw($PERSONAL_FILE_NAME);
use vars qw($loaded $error);
use strict;

$loaded = 1;
ok($loaded, "module loaded");

######################### End of black magic.

my $document = q[<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
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

package MyDocumentHandler;
use strict;
use vars qw(@ISA);
@ISA = qw(XML::Xerces::PerlDocumentHandler);

sub start_element {
  my $self = shift;
  $self->{elements}++;
}
sub characters {
  my ($self,$str,$len) = @_;
  $self->{chars} += $len;
}
sub ignorable_whitespace {
  my ($self,$str,$len) = @_;
  $self->{ws} += $len;
}

package main;
my $SAX = XML::Xerces::SAXParser->new();
my $DOCUMENT_HANDLER = MyDocumentHandler->new();
my $ERROR_HANDLER = XML::Xerces::PerlErrorHandler->new();
$DOCUMENT_HANDLER->{elements} = 0;
$DOCUMENT_HANDLER->{chars} = 0;
$DOCUMENT_HANDLER->{ws} = 0;
$SAX->setDocumentHandler($DOCUMENT_HANDLER);
$SAX->setErrorHandler($ERROR_HANDLER);

$SAX->parse(XML::Xerces::MemBufInputSource->new($document, 'foo'));
ok($DOCUMENT_HANDLER->{elements} == 10);
ok($DOCUMENT_HANDLER->{chars} == 141);
ok($DOCUMENT_HANDLER->{ws} == 0);

# test the overloaded parse version
$SAX->parse($PERSONAL_FILE_NAME);
ok(1);


# test the progressive parsing interface
my $token = XML::Xerces::XMLPScanToken->new();
$SAX->parseFirst($PERSONAL_FILE_NAME,$token);
while ($SAX->parseNext($token)) {
  # do nothing
}
ok(1);



# test that we can reuse the parse again and again
$document = <<\END;
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
  die();
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
  die();
}
1;

package main;
$token = XML::Xerces::XMLPScanToken->new();
$SAX->setErrorHandler(MyErrorHandler->new());
$::error = '';
eval {
  $SAX->parseFirst(XML::Xerces::MemBufInputSource->new($document),$token);
  while ($SAX->parseNext($token)) {
    # do nothing
  }
};
ok($::error);
$::error = '';
$SAX->parseReset($token);
eval {
  $SAX->parse(XML::Xerces::MemBufInputSource->new($document));
};
ok($::error);

