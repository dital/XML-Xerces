# Before `make install' is performed this script should be runnable
# with `make test'. After `make install' it should work as `perl
# XMLUri.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..15\n"; }
END {print "not ok 1\n" unless $loaded;}
use Carp;
# use blib;
use XML::Xerces;

use lib 't';
use TestUtils qw(result is_object $DOM $PERSONAL_FILE_NAME);
use vars qw($i $loaded);
use strict;

$loaded = 1;
$i = 1;
result($loaded);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
my $scheme = 'http';
my $host = 'www.openinformatics.com';
my $path = '/samples/personal.pl';
my $port = '2727';
my $query = 'additem=yes';

# test the overloaded constructor
my $uri;
eval {
  $uri = XML::Xerces::XMLUri->new("$scheme://$host:$port");
};
if ($@) {
  die $@->getMessage()
    if ref($@);
  die $@;
}
result($uri
      && is_object($uri)
      && $uri->isa('XML::Xerces::XMLUri'));

# test the constructor
my $uri2;
eval {
  $uri2 = XML::Xerces::XMLUri->new($uri,"$path?$query");
};
if ($@) {
  die $@->getMessage()
    if ref($@);
  die $@;
}
result($uri2
      && is_object($uri2)
      && $uri2->isa('XML::Xerces::XMLUri'));

result($uri2->getScheme() eq $scheme);
$scheme = 'ftp';
$uri2->setScheme($scheme);
result($uri2->getScheme() eq $scheme);

result($uri2->getHost() eq $host);
$host = 'www.openscience.org';
$uri2->setHost($host);
result($uri2->getHost() eq $host);

result($uri2->getPath() eq $path);
$path = '/test.pl';
$uri2->setPath($path);
result($uri2->getPath() eq $path);

result($uri2->getPort() eq $port);
$port = '4747';
$uri2->setPort($port);
result($uri2->getPort() eq $port);

result($uri2->getQueryString() eq $query);
$query = 'test=foo';
$uri2->setQueryString($query);
result($uri2->getQueryString() eq $query);

$scheme = 'mailto';
my $user = 'jasons';
eval {
  $uri2 = XML::Xerces::XMLUri->new("$scheme://$user\@$host");
};
if ($@) {
  die $@->getMessage()
    if ref($@);
  die $@;
}
result($uri2->getUserInfo() eq $user);

$user = 'bob';
$uri2->setUserInfo($user);
result($uri2->getUserInfo() eq $user);
