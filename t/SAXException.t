# Before `make install' is performed this script should be runnable
# with `make test'. After `make install' it should work as `perl
# DOMException.t'

######################### We start with some black magic to print on failure.

END {ok(0) unless $loaded;}

use Carp;

# use blib;
use XML::Xerces;
use Test::More tests => 6;
use Config;

use lib 't';
use TestUtils qw($PERSONAL_FILE_NAME);
use vars qw($loaded);
use strict;

$loaded = 1;
ok($loaded, "module loaded");

######################### End of black magic.

# test that we get an SAXNotRecognizedException
my $parser = XML::Xerces::XMLReaderFactory::createXMLReader();
eval {
  $parser->setFeature("http://xml.org/sax/features/foospaces", 0);
};
my $error = $@;
ok($error &&
   UNIVERSAL::isa($error,'XML::Xerces::SAXNotRecognizedException') &&
   $error->getMessage()
  );

eval {
  $parser->getFeature('http://xml.org/sax/features/foospaces');
};
$error = $@;
ok($error &&
   UNIVERSAL::isa($error,'XML::Xerces::SAXNotRecognizedException') &&
   $error->getMessage()
  );

eval {
  $parser->getProperty('http://xml.org/sax/features/foospaces');
};
$error = $@;
ok($error &&
   UNIVERSAL::isa($error,'XML::Xerces::SAXNotRecognizedException') &&
   $error->getMessage()
  );

eval {
  $parser->setProperty('http://xml.org/sax/features/foospaces', $parser);
};
$error = $@;
ok($error &&
   UNIVERSAL::isa($error,'XML::Xerces::SAXNotRecognizedException') &&
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
ok($error &&
   UNIVERSAL::isa($error,'XML::Xerces::SAXNotSupportedException') &&
   $error->getMessage()
  );

# print STDERR "MessageNS = $messageNS\n";
# print STDERR "MessageNR = $messageNR\n";
# print STDERR "Error = $error\n";
# print STDERR "Eval = $@\n";
