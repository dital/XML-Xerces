# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl DOM_NodeList.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..10\n"; }
END {print "not ok 1\n" unless $loaded;}
use Carp;
use Cwd;
# use blib;
use XML::Xerces;

use lib 't';
use TestUtils qw(result $DOM $PERSONAL_FILE_NAME is_object);
use vars qw($i $loaded);
use strict;

$loaded = 1;
$i = 1;
result($loaded);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$DOM->parse( new XML::Xerces::LocalFileInputSource($PERSONAL_FILE_NAME) );
my $doc = $DOM->getDocument();

# test automatic conversion to perl list
my @node_list = $doc->getElementsByTagName('person');
result(scalar @node_list == 6);

# test that we can still get a DOM_NodeList object
my $dom_node_list = $doc->getElementsByTagName('person');
result(is_object($dom_node_list) && 
       $dom_node_list->isa('XML::Xerces::DOM_NodeList'));

result($dom_node_list->getLength() == scalar @node_list);

for (my $i=0;$i<scalar @node_list;$i++) {
  result($node_list[$i] == $dom_node_list->item($i));
}
