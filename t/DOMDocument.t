# Before `make install' is performed this script should be runnable
# with `make test'. After `make install' it should work as `perl
# DOMDocument.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

END {ok(0) unless $loaded;}

use Carp;

# use blib;
use utf8;
use XML::Xerces;
use Test::More tests => 35125;
use Config;

use lib 't';
use vars qw($loaded);
use strict;

$loaded = 1;
ok($loaded, "module loaded");

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# Create a couple of identical test documents
my $document = q[<?xml version="1.0" encoding="UTF-8"?>
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

my $DOM1 = new XML::Xerces::XercesDOMParser;
my $ERROR_HANDLER = XML::Xerces::PerlErrorHandler->new();
$DOM1->setErrorHandler($ERROR_HANDLER);
$DOM1->parse(XML::Xerces::MemBufInputSource->new($document));

my $DOM2 = new XML::Xerces::XercesDOMParser;
$DOM2->setErrorHandler($ERROR_HANDLER);
$DOM2->parse(XML::Xerces::MemBufInputSource->new($document, 'foo'));

my $doc1 = $DOM1->getDocument();
my $doc2 = $DOM2->getDocument();

my $root1 = $doc1->getDocumentElement();
my @persons1 = $doc1->getElementsByTagName('person');
my @names1 = $doc1->getElementsByTagName('name');
my $root2 = $doc2->getDocumentElement();
my @persons2 = $doc2->getElementsByTagName('person');
my @names2 = $doc1->getElementsByTagName('name');

# importing a child from a different document
eval {
  my $copy = $doc1->importNode($persons1[0],0);
  $root1->appendChild($copy);
};
ok(!$@ &&
       scalar @persons1 < scalar ($root1->getElementsByTagName('person'))
      );

# check that creating an element with an illegal charater
eval {
  my $el = $doc1->createElement('?');
};
ok($@
       && $@->{code} == $XML::Xerces::DOMException::INVALID_CHARACTER_ERR
      );

# check that an element can't start with a digit
eval {
  my $el = $doc1->createElement('9');
};
ok($@
       && $@->{code} == $XML::Xerces::DOMException::INVALID_CHARACTER_ERR
      );

# check that getElementById() doesn't segfault on undef ID
eval {
  $doc1->getElementById(undef);
};
ok($@);

# check that an element can have a digit if a valid character comes first
eval {
  $DOM1->parse('t/letter.xml');
};
if ($@) {
  if (ref($@)) {
    if ($@->isa('XML::Xerces::XMLException')) {
      die "Couldn't open letter.xml: ", $@->getMessage();
    } elsif ($@->isa('XML::Xerces::DOMException')) {
      die "Couldn't open letter.xml: msg=<$@->{msg}>, code=$@->{code}";
    }
  }
}

$doc1 = $DOM1->getDocument();
my ($digit_node) = $doc1->getElementsByTagName('digit');
my @digits;
foreach my $range_node ($digit_node->getElementsByTagName('range')) {
  my $low = hex($range_node->getAttribute('low'));
  my $high = hex($range_node->getAttribute('high'));
  push(@digits,$low..$high);
}
foreach my $single_node ($digit_node->getElementsByTagName('single')) {
  my $value = hex($single_node->getAttribute('value'));
  push(@digits,$value);
}
@digits = map {chr($_)} @digits;
foreach my $char (@digits) {
  eval {
    my $el = $doc1->createElement("_$char");
  };
  if ($@) {
    if (ref $@) {
      print STDERR "Error code: $@->{code}\n";
    } else {
      print STDERR $@;
    }
  }
  ok(!$@) || printf("char: <0x%.4X>\n",ord($char));
}

my ($extender_node) = $doc1->getElementsByTagName('extender');
my @extenders;
foreach my $range_node ($extender_node->getElementsByTagName('range')) {
  my $low = hex($range_node->getAttribute('low'));
  my $high = hex($range_node->getAttribute('high'));
  push(@extenders,$low..$high);
}
foreach my $single_node ($extender_node->getElementsByTagName('single')) {
  my $value = hex($single_node->getAttribute('value'));
  push(@extenders,$value);
}
@extenders = map {chr($_)} @extenders;
foreach my $char (@extenders) {
  eval {
    my $el = $doc1->createElement("_$char");
  };
  if ($@) {
    if (ref $@) {
      print STDERR "Error code: $@->{code}\n";
    } else {
      print STDERR $@;
    }
  }
  ok(!$@) || printf("char: <0x%.4X>\n",ord($char));
}

my ($combining_char_node) = $doc1->getElementsByTagName('combiningchar');
my @combining_chars;
foreach my $range_node ($combining_char_node->getElementsByTagName('range')) {
  my $low = hex($range_node->getAttribute('low'));
  my $high = hex($range_node->getAttribute('high'));
  push(@combining_chars,$low..$high);
}
foreach my $single_node ($combining_char_node->getElementsByTagName('single')) {
  my $value = hex($single_node->getAttribute('value'));
  push(@combining_chars,$value);
}
@combining_chars = map {chr($_)} @combining_chars;
foreach my $char (@combining_chars) {
  eval {
    my $el = $doc1->createElement("_$char");
  };
  if ($@) {
    if (ref $@) {
      print STDERR "Error code: $@->{code}\n";
    } else {
      print STDERR $@;
    }
  }
  ok(!$@) || printf("char: <0x%.4X>\n",ord($char));
}

my ($letter_node) = $doc1->getElementsByTagName('letter');
my @letters;
foreach my $range_node ($letter_node->getElementsByTagName('range')) {
  my $low = hex($range_node->getAttribute('low'));
  my $high = hex($range_node->getAttribute('high'));
  push(@letters,$low..$high);
}
foreach my $single_node ($letter_node->getElementsByTagName('single')) {
  my $value = hex($single_node->getAttribute('value'));
  push(@letters,$value);
}
@letters = map {chr($_)} @letters;
# $XML::Xerces::DEBUG_UTF8_IN = 1;
# $XML::Xerces::DEBUG_UTF8_OUT = 1;
foreach my $char (@letters) {
  eval {
    my $el = $doc1->createElement("$char");
  };
  if ($@) {
    if (ref $@) {
      print STDERR "Error code: $@->{code}\n";
    } else {
      print STDERR $@;
    }
  }
  ok(!$@) || printf("char: <0x%.4X>\n",ord($char));
}

my ($ideograph_node) = $doc1->getElementsByTagName('ideographic');
my @ideographs;
foreach my $range_node ($ideograph_node->getElementsByTagName('range')) {
  my $low = hex($range_node->getAttribute('low'));
  my $high = hex($range_node->getAttribute('high'));
  push(@ideographs,$low..$high);
}
foreach my $single_node ($ideograph_node->getElementsByTagName('single')) {
  my $value = hex($single_node->getAttribute('value'));
  push(@ideographs,$value);
}
@ideographs = map {chr($_)} @ideographs;
# $XML::Xerces::DEBUG_UTF8_IN = 1;
# $XML::Xerces::DEBUG_UTF8_OUT = 1;
foreach my $char (@ideographs) {
  eval {
    my $el = $doc1->createElement("$char");
  };
  if ($@) {
    if (ref $@) {
      print STDERR "Error code: $@->{code}\n";
    } else {
      print STDERR $@;
    }
  }
  ok(!$@) || printf("char: <0x%.4X>\n",ord($char));
}
$XML::Xerces::DEBUG_UTF8_IN = 0;
$XML::Xerces::DEBUG_UTF8_OUT = 0;

# check that an element can start with an underscore
eval {
  my $el = $doc1->createElement('_');
};
ok(!$@);

# check that an element can start with an colon
eval {
  my $el = $doc1->createElement(':');
};
ok(!$@);
