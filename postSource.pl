#!/usr/bin/perl
use lib '.';
use SWIG qw(remove_method skip_to_closing_brace fix_method);

use strict;

my $file = shift @ARGV;
my $PRINTED = 0;
my $temp_file = "$file.$$";

open(FILE, $file)
  or die "Couldn't open $file for reading";
open(TEMP, ">$temp_file")
  or die "Couldn't open $temp_file for writing";

FILE: while(<FILE>) {

  substitute_line($_);

  # need to cast this properly
  if (/XS\(_wrap_XMLValidator_checkContent/) {
    fix_method_source(\*FILE,
		      \*TEMP,
		      'arg0->checkContent',
		      "            result = (int )arg0->checkContent(arg1,(QName **const)arg2,arg3);\n",
		      0
		     );
    next FILE;
  }

  # we need to move the new SWIG_TypeCheck() *after* the perl
  # header includes, because we now use sv_derived_from()
  if (!$PRINTED && /\#ifdef\s+PERL_OBJECT/) {
    $PRINTED = 1;
    print TEMP <<'EOT';
/* Check the typename */
SWIGRUNTIME(swig_type_info *) 
SWIG_TypeCheck(SV *sv, swig_type_info *ty)
{
  swig_type_info *s;
  if (!ty) return 0;        /* Void pointer */
  s = ty->next;             /* First element always just a name */
  while (s) {
    if (sv_derived_from(sv,(char*)s->name)) {
      if (s == ty->next) return s;
      /* Move s to the top of the linked list */
      s->prev->next = s->next;
      if (s->next) {
	s->next->prev = s->prev;
      }
      /* Insert s as second element in the list */
      s->next = ty->next;
      if (ty->next) ty->next->prev = s;
      ty->next = s;
      return s;
    }
    s = s->next;
  }
  return 0;
}

EOT
  }
  # now we substitute the line in SWIG_ConvertPTR()that 
  # calls SWIG_TypeCheck()
  if(/tc = SWIG_TypeCheck\(_c,_t\)/) {
    print TEMP<<"EOT";
    tc = SWIG_TypeCheck(sv,_t);
EOT
    next;
  }

  print TEMP;
}

close FILE;
close TEMP;

open(TEMP, "$temp_file")
  or die "Couldn't open $temp_file for reading";
open(FILE, ">$file")
  or die "Couldn't open $file for writing";

# put Perl in paragraph mode so that we read in entire blocks
# separated by blank lines
$/ = '';
$PRINTED = 0;
while(<TEMP>) {
  # we cut out the first occurrence of the SWIG_TypeCheck
  # and print everything else
  if (!$PRINTED && /SWIG_TypeCheck\(char \*c, swig_type_info \*ty\)/) {
    $PRINTED = 1;
    next;
  }
  print FILE;
}
close FILE;
close TEMP;

unlink $temp_file;

sub substitute_line {

  # change the name of SWIG's IDOM types to DOM
#  $_[0] =~ s/(?<=\"XML::Xerces::)IDOM/DOM/g;

  # we remove the RCS keyword from perl5.swg
  $_[0] = '' if $_[0] =~ /\$Header:/;

}

# we always want to substitute every line so we default the argument
sub fix_method_source {
  fix_method(@_,\&substitute_line);
}
