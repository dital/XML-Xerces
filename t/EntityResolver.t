# Before `make install' is performed this script should be runnable
# with `make test'. After `make install' it should work as `perl
# EntityResolver.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..9\n"; }
END {print "not ok 1\n" unless $loaded;}
use Carp;
# use blib;
use XML::Xerces;
use Cwd;

use lib 't';
use TestUtils qw(result
		 $PERSONAL_FILE_NAME
		 $PERSONAL_SCHEMA_FILE_NAME
		 $SCHEMA_FILE_NAME
		 $PUBLIC_RESOLVER_FILE_NAME
		 $SYSTEM_RESOLVER_FILE_NAME
		 $PERSONAL_DTD_NAME);
use vars qw($i $loaded $file $test);
use strict;

$loaded = 1;
$i = 1;
result($loaded);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

package MyEntityResolver;
use strict;
use vars qw(@ISA $test);
use TestUtils qw($PERSONAL_DTD_NAME
		 $SCHEMA_FILE_NAME
		 $CATALOG);
@ISA = qw(XML::Xerces::PerlEntityResolver);

sub new {
  return bless {}, shift;
}

sub resolve_entity {
  my ($self,$pub,$sys) = @_;
#  print STDERR "Got PUBLIC: $pub\n";
#  print STDERR "Got SYSTEM: $sys\n";
  $main::test = 1;

  # we parse the example XML Catalog
  my $DOM = XML::Xerces::DOMParser->new();
  my $ERROR_HANDLER = XML::Xerces::PerlErrorHandler->new();
  $DOM->setErrorHandler($ERROR_HANDLER);
  $DOM->parse(XML::Xerces::LocalFileInputSource->new($CATALOG));

  # now retrieve the mappings
  my $doc = $DOM->getDocument();
  my @Maps = $doc->getElementsByTagName('Map');
  my %Maps = map {($_->getAttribute('PublicId'),
		   $_->getAttribute('HRef'))} @Maps;
  my @Remaps = $doc->getElementsByTagName('Remap');
  my %Remaps = map {($_->getAttribute('SystemId'),
		     $_->getAttribute('HRef'))} @Remaps;

  # now check which one we were asked for
  my $href;
  if ($pub) {
    $href = $Maps{$pub};
  } elsif ($sys) {
    $href = $Remaps{$sys};
  } else {
    croak("Neither PublicId or SystemId were defined");
  }
  my $is;
  eval {
    $is = XML::Xerces::LocalFileInputSource->new($href);
  };
  if ($@) {
    print STDERR "Resolver: ", $@->getMessage(), "\n"
      if ref $@;
    print STDERR "Resolver: $@\n";
  }
  return $is;
}

package main;
$test = 0;
my $DOM = XML::Xerces::DOMParser->new();
my $ERROR_HANDLER = XML::Xerces::PerlErrorHandler->new();
$DOM->setErrorHandler($ERROR_HANDLER);

# see if we can create and set an entity resolver
my $ENTITY_RESOLVER = MyEntityResolver->new();
$DOM->setEntityResolver($ENTITY_RESOLVER);
result(1);

# now lets see if the resolver gets invoked
eval {
  $DOM->parse($SYSTEM_RESOLVER_FILE_NAME);
};
if ($@) {
  print STDERR $@->getMessage()
    if ref $@;
  print STDERR $@;
}
result($test);

my $doc;
eval {
  $doc = $DOM->getDocument();
};
if ($@) {
  print STDERR $@->getMessage()
    if ref $@;
  print STDERR $@;
}
result(ref $doc && $doc->isa('XML::Xerces::DOM_Document'));

my $root = $doc->getDocumentElement();
result(ref $root && 
       $root->isa('XML::Xerces::DOM_Element') &&
       $root->getNodeName() eq 'personnel'
      );

$DOM->reset();
$test = 0;
eval {
  $DOM->parse($PUBLIC_RESOLVER_FILE_NAME);
};
if ($@) {
  print STDERR $@->getMessage()
    if ref $@;
  print STDERR $@;
}
result($test);

$doc = $DOM->getDocument();
result(ref $doc && $doc->isa('XML::Xerces::DOM_Document'));

$root = $doc->getDocumentElement();
result(ref $root && 
       $root->isa('XML::Xerces::DOM_Element') &&
       $root->getNodeName() eq 'personnel'
      );

my $document = <<'SCHEMA';
<?xml version="1.0" encoding="ISO-8859-1"?>
<personnel xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	   xsi:noNamespaceSchemaLocation='bar.xsd'>

  <person id="Big.Boss" >
    <name><family>Boss</family> <given>Big</given></name>
    <email>chief@foo.com</email>
    <link subordinates="one.worker two.worker three.worker four.worker five.worker"/>
  </person>

  <person id="one.worker">
    <name><family>Worker</family> <given>One</given></name>
    <email>one@foo.com</email>
    <link manager="Big.Boss"/>
  </person>

  <person id="two.worker">
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
SCHEMA

$DOM->reset();
$DOM->setDoSchema(1);
$DOM->setDoNamespaces(1);
# $DOM->setValidationScheme($XML::Xerces::DOMParser::Val_Always);
eval {
  $DOM->parse(XML::Xerces::MemBufInputSource->new($document));
};
if ($@) {
  die $@->getMessage()
    if ref $@;
  die $@;
}
result(1);
