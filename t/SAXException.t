# Before `make install' is performed this script should be runnable
# with `make test'. After `make install' it should work as `perl
# DOMException.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..6\n"; }
END {print "not ok 1\n" unless $loaded;}
use Carp;

# use blib;
use XML::Xerces;
use Config;

use lib 't';
use TestUtils qw(result is_object $PERSONAL_FILE_NAME);
use vars qw($i $loaded);
use strict;

$loaded = 1;
$i = 1;
result($loaded);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# test that we get an SAXNotRecognizedException
my $parser = XML::Xerces::XMLReaderFactory::createXMLReader();
eval {
  $parser->setFeature("http://xml.org/sax/features/foospaces", 0);
};
my $error = $@;
result($error && 
       is_object($error) &&
       $error->isa('XML::Xerces::SAXNotRecognizedException') &&
       $error->getMessage()
      );

eval {
  $parser->getFeature('http://xml.org/sax/features/foospaces');
};
$error = $@;
result($error &&
       is_object($error) &&
       $error->isa('XML::Xerces::SAXNotRecognizedException') &&
       $error->getMessage()
      );

eval {
  $parser->getProperty('http://xml.org/sax/features/foospaces');
};
$error = $@;
result($error &&
       is_object($error) &&
       $error->isa('XML::Xerces::SAXNotRecognizedException') &&
       $error->getMessage()
      );

eval {
  $parser->setProperty('http://xml.org/sax/features/foospaces', $parser);
};
$error = $@;
result($error &&
       is_object($error) &&
       $error->isa('XML::Xerces::SAXNotRecognizedException') &&
       $error->getMessage()
      );

# test that modifying a feature during a parse raises a not supported exception
package MyHandler;
use strict;
use vars qw(@ISA);
@ISA = qw(XML::Xerces::PerlContentHandler);

sub start_element {
  my ($self,$name,$attrs) = @_;
  $parser->setProperty('http://xml.org/sax/features/namespaces', $parser);
  print STDERR "Got it!!";
}
sub end_element {
}
sub characters {
}
sub ignorable_whitespace {
}

package main;
my $handler = MyHandler->new();
$parser->setContentHandler($handler);
eval {
  $parser->parse(XML::Xerces::LocalFileInputSource->new($PERSONAL_FILE_NAME));
};
$error = $@;
result($error &&
       is_object($error) &&
       $error->isa('XML::Xerces::SAXNotSupportedException') &&
       $error->getMessage()
      );

# print STDERR "MessageNS = $messageNS\n";
# print STDERR "MessageNR = $messageNR\n";
# print STDERR "Error = $error\n";
# print STDERR "Eval = $@\n";
