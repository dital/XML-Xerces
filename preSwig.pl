#!/usr/local/bin/perl

use strict;
use SWIG qw(skip_to_closing_brace);
use Getopt::Long;
use File::Basename;

my %OPTIONS;
my $rc = GetOptions(\%OPTIONS,
		   'directory=s');

my $USAGE = qq[USAGE: $0: --directory file];

die "No input file provided\n$USAGE"
  unless scalar @ARGV;

die $USAGE unless $rc;

my $file = shift @ARGV;

die "File: $file does not exist"
  unless -f $file;

open(IN,$file) or die "Couldn't open $file for reading";

my $path;
($file,$path) = fileparse($file);

$path =~ s|^.*/include/||;

my $outdir = $OPTIONS{directory};

mkdir($outdir) unless -d $outdir;
$outdir = "$outdir/$path";
mkdir($outdir) unless -d $outdir;

my $outfile = "$outdir/$file";

open(OUT,">$outfile") or die "Couldn't open $outfile for writing";

my $in_class;
my $seen_class = 0;
while (<IN>) {
  if (/^class/ && !/;\s*$/) {
    $in_class = 1;
  }
  if ($in_class && /\{\s*$/) {
    $seen_class = 1;
    # we found the class definition
    print OUT;
    skip_to_closing_brace(\*IN,\&substitute_line,\*OUT);
#    print OUT "\n#endif";
    $in_class = 0;
    next;
  }
  if ($in_class && /;\s*$/) {
    $in_class = 0;
  }
  print OUT 
    if $in_class or not $seen_class;
}
print OUT "\n#endif";
close(IN);
close(OUT);

sub substitute_line {
#   if ($_[0] =~ /operator/) {
#     $_[0] =~ s/operator\s*=\s*\(/operator_assignment\(/;
#     $_[0] =~ s/operator\s*!=\s*\(/operator_not_equal_to\(/;
#     $_[0] =~ s/operator\s*==\s*\(/operator_equal_to\(/;
#   }
}
