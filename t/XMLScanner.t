# Before `make install' is performed this script should be runnable
# with `make test'. After `make install' it should work as `perl
# XMLScanner.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..12\n"; }
END {print "not ok 1\n" unless $loaded;}
use Carp;
# use blib;
use XML::Xerces;

use lib 't';
use TestUtils qw(result $PERSONAL_FILE_NAME);
use vars qw($i $loaded $error);
use strict;

$loaded = 1;
$i = 1;
result($loaded);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $document = q[<?xml version="1.0" encoding="utf-8" standalone="yes"?>
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
  my ($self,$name,$attrs) = @_;
  $self->{elements}++;
  my $offset = $self->{parser}->getScanner->getSrcOffset();
  push(@{$self->{offsets}},$offset);
}
sub characters {
  my ($self,$str,$len) = @_;
}
sub ignorable_whitespace {
  my ($self,$str,$len) = @_;
}

package main;
my $SAX = XML::Xerces::SAXParser->new();
my $DOCUMENT_HANDLER = MyDocumentHandler->new();
$DOCUMENT_HANDLER->{parser} = $SAX;
my $ERROR_HANDLER = XML::Xerces::PerlErrorHandler->new();
$DOCUMENT_HANDLER->{elements} = 0;
$DOCUMENT_HANDLER->{chars} = 0;
$DOCUMENT_HANDLER->{ws} = 0;
$SAX->setDocumentHandler($DOCUMENT_HANDLER);
$SAX->setErrorHandler($ERROR_HANDLER);

$SAX->parse(XML::Xerces::MemBufInputSource->new($document, 'foo'));
my $offset_ref = $DOCUMENT_HANDLER->{offsets};
result(scalar @{$offset_ref} == 10);

foreach my $offset (qw(70 96 107 136 201 212 241 310 321 357)) {
  my $value = shift @{$offset_ref};
  result($offset == $value);
}

