#!/usr/bin/perl
use lib '.';
use SWIG qw(remove_method skip_to_closing_brace fix_method);

use strict;

#
# SWIG has now improved to the point that this file is not needed!!!
#

exit(0);

my $file = shift @ARGV;
my $PRINTED = 0;
my $temp_file = "$file.$$";

open(FILE, $file)
  or die "Couldn't open $file for reading";
open(TEMP, ">$temp_file")
  or die "Couldn't open $temp_file for writing";

FILE: while(<FILE>) {

  substitute_line($_);

  print TEMP;
}

close FILE;
close TEMP;

rename $temp_file, $file;

sub substitute_line {

  # we remove the RCS keyword from perl5.swg
  # $_[0] = '' if $_[0] =~ /\$Header:/;

}

# we always want to substitute every line so we default the argument
sub fix_method_source {
  fix_method(@_,\&substitute_line);
}
