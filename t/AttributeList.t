# Before `make install' is performed this script should be runnable
# with `make test'. After `make install' it should work as `perl
# AttributeList.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok 1\n" unless $loaded;}
use Carp;
# use blib;
use XML::Xerces;
use Config;

use lib 't';
use TestUtils qw(result $PERSONAL_FILE_NAME);
use vars qw($i $loaded);
use strict;

$loaded = 1;
$i = 1;
result($loaded);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

package MyDocumentHandler;
use strict;
use vars qw(@ISA);
@ISA = qw(XML::Xerces::PerlDocumentHandler);

sub start_element {
  my ($self,$name,$attrs) = @_;
  if ($name eq 'foo') {
    $self->{test} = $attrs->getLength();
  }
}
sub end_element {
}
sub characters {
}
sub ignorable_whitespace {
}

package main;
my $url = 'http://www.boyscouts.org/';
my $local = 'Rank';
my $ns = 'Scout';
my $value = 'eagle scout';
my $document = qq[<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<bar>
  <foo xmlns:Scout="$url"
   Role="manager" $ns:$local="$value">
  </foo>
</bar>];

my $SAX = XML::Xerces::SAXParser->new();
my $DOCUMENT_HANDLER = MyDocumentHandler->new();
my $ERROR_HANDLER = XML::Xerces::PerlErrorHandler->new();
$SAX->setDocumentHandler($DOCUMENT_HANDLER);
$SAX->setErrorHandler($ERROR_HANDLER);

# test getLength
my $is = XML::Xerces::MemBufInputSource->new($document);
$DOCUMENT_HANDLER->{test} = '';
$SAX->parse($is);
result($DOCUMENT_HANDLER->{test} == 3);
$DOCUMENT_HANDLER->{test} = '';

# we want to avoid a bunch of warnings about redefining
# the start_element method, so we turn off warnings
$^W = 0;

# test getName
*MyDocumentHandler::start_element = sub {
  my ($self,$name,$attrs) = @_;
  if ($name eq 'foo') {
    $self->{test} = $attrs->getName(2);
  }
};
$DOCUMENT_HANDLER->{test} = '';
$SAX->parse($is);
result($DOCUMENT_HANDLER->{test} eq "$ns:$local");

# test getValue
*MyDocumentHandler::start_element = sub {
  my ($self,$name,$attrs) = @_;
  if ($name eq 'foo') {
    $self->{test} = $attrs->getValue("$ns:$local");
  }
};
$DOCUMENT_HANDLER->{test} = '';
$SAX->parse($is);
result($DOCUMENT_HANDLER->{test} eq $value);

# test overloaded getValue
*MyDocumentHandler::start_element = sub {
  my ($self,$name,$attrs) = @_;
  if ($name eq 'foo') {
    $self->{test} = $attrs->getValue(2);
  }
};
$DOCUMENT_HANDLER->{test} = '';
$SAX->parse($is);
result($DOCUMENT_HANDLER->{test} eq $value);

# test to_hash()
*MyDocumentHandler::start_element = sub {
  my ($self,$name,$attrs) = @_;
  if ($name eq 'foo') {
    $self->{test} = {$attrs->to_hash()};
  }
};
$DOCUMENT_HANDLER->{test} = '';
$SAX->parse($is);
my $hash_ref = $DOCUMENT_HANDLER->{test};
result(ref($hash_ref) eq 'HASH'
      && keys %{$hash_ref} == 3
      && $hash_ref->{"$ns:$local"} eq $value);

$document = qq[<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<!DOCTYPE bar SYSTEM "foo.dtd" [
<!ELEMENT bar (foo)>
<!ELEMENT foo EMPTY>
<!ATTLIST foo id ID #REQUIRED>
<!ATTLIST foo role CDATA #REQUIRED>
]>
<bar>
  <foo id='baz' role="manager"/>
</bar>];

package MyEntityResolver;
use strict;
use vars qw(@ISA);
@ISA = qw(XML::Xerces::PerlEntityResolver);

sub new {
  return bless {}, shift;
}

sub resolve_entity {
  my ($self,$pub,$sys) = @_;
  return XML::Xerces::MemBufInputSource->new('');
}

package main;
my $is2 = XML::Xerces::MemBufInputSource->new($document);
$SAX->setEntityResolver(MyEntityResolver->new());

# test overloaded getType
*MyDocumentHandler::start_element = sub {
  my ($self,$name,$attrs) = @_;
  if ($name eq 'foo') {
    $self->{test} = $attrs->getType(0);
  }
};
$DOCUMENT_HANDLER->{test} = '';
$SAX->parse($is2);
result($DOCUMENT_HANDLER->{test} eq 'ID');

# test getType
*MyDocumentHandler::start_element = sub {
  my ($self,$name,$attrs) = @_;
  if ($name eq 'foo') {
    $self->{test} = $attrs->getType('id');
  }
};
$DOCUMENT_HANDLER->{test} = '';
$SAX->parse($is2);
result($DOCUMENT_HANDLER->{test} eq 'ID');
