# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl domTest.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Carp;
# use blib;
use XML::Xerces;

use lib 't';
use TestUtils qw(result error $PERSONAL_NO_XMLDECL $DOM $PERSONAL_NO_XMLDECL_FILE_NAME);
use vars qw($i $loaded);
use strict;

$loaded = 1;
$i = 1;
result($loaded);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
my $is = eval {XML::Xerces::LocalFileInputSource->new($PERSONAL_NO_XMLDECL_FILE_NAME)};
error($@) if $@;

eval {$DOM->parse($is)};
error($@) if $@;

my $doc = eval{create_doc()};
error($@) if $@;

my $serialize = $doc->serialize;
result($serialize eq $PERSONAL_NO_XMLDECL);


sub create_doc {
  my $impl = XML::Xerces::DOM_DOMImplementation::getImplementation();
  my $dt = eval{$impl->createDocumentType('personnel', '', 'personal.dtd')};
  error($@) if $@;
  my $doc = eval{$impl->createDocument('personnel', 'personnel',$dt)};
  error($@) if $@;

  my($top, $person, $name, $family, $given, $email, $link, $text, $comment);
  $top = $doc->getDocumentElement();
  $comment = $doc->createComment(' @version: ');
  $doc->insertBefore($comment,$top);
      $text = $doc->createTextNode("\n\n  ");
    $top->appendChild($text);
      $person = $doc->createElement('person');
      $person->setAttribute('id','Big.Boss');
  	$text = $doc->createTextNode("\n    ");
      $person->appendChild($text);
  	$name = $doc->createElement('name');
  	  $family = $doc->createElement('family');
  	    $text = $doc->createTextNode('Boss');
  	  $family->appendChild($text);
  	$name->appendChild($family);
  	  $text = $doc->createTextNode(' ');
  	$name->appendChild($text);
  	  $given = $doc->createElement('given');
  	    $text = $doc->createTextNode('Big');
  	  $given->appendChild($text);
  	$name->appendChild($given);
      $person->appendChild($name);
  	$text = $doc->createTextNode("\n    ");
      $person->appendChild($text);
  	$email = $doc->createElement('email');
  	  $text = $doc->createTextNode('chief@foo.com');
  	$email->appendChild($text);
      $person->appendChild($email);
  	$text = $doc->createTextNode("\n    ");
      $person->appendChild($text);
  	$link = $doc->createElement('link');
  	$link->setAttribute('subordinates','one.worker two.worker three.worker four.worker five.worker');
      $person->appendChild($link);
  	$text = $doc->createTextNode("\n  ");
      $person->appendChild($text);
    $top->appendChild($person);
  
    for my $first_name ( qw(one two three four five) ) {
  	$text = $doc->createTextNode("\n\n  ");
      $top->appendChild($text);
      $top->appendChild( get_worker($doc, $first_name) );
    }
  
      $text = $doc->createTextNode("\n\n");
    $top->appendChild($text);
  return $doc;
}

sub get_worker {
  my($doc, $first_name) = @_;

  my($person, $name, $family, $given, $email, $link, $text);

  $person = $doc->createElement('person');
    $text = $doc->createTextNode("\n    ");
  $person->appendChild($text);
  $person->setAttribute('id',"$first_name.worker");
    $name = $doc->createElement('name');
      $family = $doc->createElement('family');
        $text = $doc->createTextNode('Worker');
      $family->appendChild($text);
    $name->appendChild($family);
      $text = $doc->createTextNode(' ');
    $name->appendChild($text);
      $given = $doc->createElement('given');
        $text = $doc->createTextNode("\u$first_name");
      $given->appendChild($text);
    $name->appendChild($given);
  $person->appendChild($name);
    $text = $doc->createTextNode("\n    ");
  $person->appendChild($text);
    $email = $doc->createElement('email');
      $text = $doc->createTextNode("$first_name\@foo.com");
    $email->appendChild($text);
  $person->appendChild($email);
    $text = $doc->createTextNode("\n    ");
  $person->appendChild($text);
    $link = $doc->createElement('link');
    $link->setAttribute('manager','Big.Boss');
  $person->appendChild($link);
    $text = $doc->createTextNode("\n  ");
  $person->appendChild($text);

  return $person;
}
