# Before `make install' is performed this script should be runnable
# with `make test'. After `make install' it should work as `perl
# XMLURL.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..26\n"; }
END {print "not ok 1\n" unless $loaded;}
use Carp;
# use blib;
use XML::Xerces;

use lib 't';
use TestUtils qw(result
		 is_object
		 $DOM $PERSONAL
		 $PERSONAL_FILE_NAME);
use vars qw($i $loaded $error);
use strict;

$loaded = 1;
$i = 1;
result($loaded);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# test the one argument constructor 
my $query = 'foo=bar';
my $URL = "http://www.openinformatics.com/test/samples.pl?$query";
my $xml_url = XML::Xerces::XMLURL->new($URL);
result(is_object($xml_url)
       && $xml_url->isa('XML::Xerces::XMLURL')
      );

# test the supported protocols
foreach my $proto (qw(ftp file http)) {
  $URL = "$proto://www.openinformatics.com/test/samples.pl?$query";
  eval {
    $xml_url = XML::Xerces::XMLURL->new($URL);
  };
  if ($@) {
    die $@->getMessage()
      if ref($@);
    die $@;
  }
  result(is_object($xml_url)
	 && $xml_url->isa('XML::Xerces::XMLURL')
	)
}
# test the copy constructor
my $xml_url2;
eval {
  $xml_url2 = XML::Xerces::XMLURL->new($xml_url);
};
if ($@) {
  die $@->getMessage()
    if ref($@);
  die $@;
}
result(is_object($xml_url)
       && $xml_url->isa('XML::Xerces::XMLURL')
      );

# test getQuery
result($xml_url->getQuery() eq $query);

# test the equality operator
result($xml_url == $xml_url2);

# test the two argument constructor 
my $host = 'www.openinformatics.com';
my $proto = 'ftp';
my $port = '2727';
my $user = 'me';
my $password = 'metoo';
my $base = "$proto://$user:$password\@$host:$port/";
my $path = '/test/samples.html';
my $fragment = 'foo';
my $xml_url3;
eval {
  $xml_url3 = XML::Xerces::XMLURL->new($base, "$path#$fragment");
};
if ($@) {
  die $@->getMessage()
    if ref($@);
  die $@;
}
result(is_object($xml_url)
       && $xml_url->isa('XML::Xerces::XMLURL')
      );

# test getFragment
result($xml_url3->getFragment() eq $fragment);

# test getPath
result($xml_url3->getPath() eq $path);

# test getURLText
$URL = $base;
$URL =~ s|/$||;
$URL .= "$path#$fragment";
result($xml_url3->getURLText() eq $URL);

# test getPortNum
result($xml_url3->getPortNum() eq $port);

# test getHost
result($xml_url3->getHost() eq $host);

# test getUser
result($xml_url3->getUser() eq $user);

# test getPassword
result($xml_url3->getPassword() eq $password);

# test getProtocolName
result($xml_url3->getProtocolName() eq $proto);

# test the inequality operator
result($xml_url3 != $xml_url2);

# test the assignment operator
$xml_url3 = $xml_url2;
result($xml_url3 == $xml_url2);

# test setURL with a text string
$xml_url3->setURL($URL);
result($xml_url3->getURLText() eq $URL);

# test isRelative
eval {
  $xml_url2 = XML::Xerces::XMLURL->new($path);
};
if ($@) {
  die $@->getMessage()
    if ref($@);
  die $@;
}
result(!$xml_url3->isRelative());
result($xml_url2->isRelative());

# test makeRelativeTo
$xml_url3 = $xml_url2;
$xml_url2->makeRelativeTo($base);
result(!$xml_url2->isRelative());

#test overloaded makeRelativeTo
eval {
  $xml_url = XML::Xerces::XMLURL->new($base);
};
if ($@) {
  die $@->getMessage()
    if ref($@);
  die $@;
}
$xml_url3->makeRelativeTo($xml_url);
result(!$xml_url3->isRelative());

# test overloaded setURL with XMLURL for base
$xml_url2->setURL($xml_url,"$path#$fragment");
result($xml_url2->getURLText() eq $URL);

# test overloaded setURL with string for base
$xml_url3->setURL($base,"$path#$fragment");
result($xml_url3->getURLText() eq $URL);
