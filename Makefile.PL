use ExtUtils::MakeMaker;
use Env qw(XERCES_LIB 
	   XERCES_CONFIG
	   XERCES_INCLUDE
	   XERCESCROOT
	   XERCES_DEVEL
	   SWIG);
use strict;
use vars qw($INCLUDES);
use File::Basename;

eval {
  require 5.6.0;
};
if ($@) {
  die <<ERROR;


    !!!WHOA!!!

You are using an *ancient* version of Perl. Because of the need to
support Unicode, XML::Xerces requires you upgrade to at least
v5.6.0. If you plan on using Unicode in your XML, you should really
upgrade to 5.7.2.

ERROR
}


if (defined $XERCES_LIB || defined $XERCES_INCLUDE) {
  # this is the default, so do nothing
} elsif (defined $XERCESCROOT) {
  # they are instructing us to use the build directories
  $XERCES_INCLUDE = "$XERCESCROOT/include";
  $XERCES_LIB = "$XERCESCROOT/lib";
} 

my $LIBS = '-lpthread';
$INCLUDES = '-I. -IHandler';
if (defined $XERCES_LIB) {
  print STDERR "Using XERCES_LIB = $XERCES_LIB\n";
  $LIBS .= " -L$XERCES_LIB ";
}

if (defined $XERCES_INCLUDE) {
  print STDERR "Using XERCES_INCLUDE = $XERCES_INCLUDE\n";
  $INCLUDES .= " -I$XERCES_INCLUDE";
}

if (!defined $XERCES_LIB && !defined $XERCES_INCLUDE) {
  print STDERR <<EOW;

   WARNING

You have not defined any of the following environment variables:
   XERCESCROOT
   XERCES_LIB
   XERCES_INCLUDE

These instruct me how to locate the Xerces header files, and the
Xerces dynamic library. If they are installed in a standard system
directory, I will located them without those variables.

However, if they have been installed in a non-standard location
(e.g. '/usr/include/xerces'), then I will need help. See the README
for more info.

Proceeding ...
EOW
}

if (0) {
  # for now we will ignore the configuration
my $config_file = 'config.status';
if (defined $XERCES_CONFIG) {
  unless (-f $XERCES_CONFIG) {
  print STDERR <<EOW;

   WARNING

You have defined the XERCES_CONFIG variable, but it does not seem to
point to the $config_file file that was used to build your
Xerces-C. Without that file, I may not be able to properly build the
C++ glue files that come with Xerces.pm.

Proceeding ...
EOW
  }
} elsif (defined $XERCESCROOT) {
  unless (-f "$XERCESCROOT/src/xerces/$config_file") {
  print STDERR <<EOW;

   WARNING

You have defined the XERCESCROOT variable, but I am unable to locate
the $config_file file that was used to build your Xerces-C. Without
that file, I may not be able to properly build the C++ glue files that
come with Xerces.pm.

Proceeding ...
EOW
  }
} else {
  print STDERR <<EOW;

   WARNING

You have not defined any of the following environment variables:
   XERCESCROOT
   XERCES_CONFIG

Without these I cannot find the $config_file file that was used to
build your Xerces-C. Without that file, I may not be able to properly
build the C++ glue files that come with Xerces.pm.

Proceeding ...
EOW
}
}

# We need to know which version of libxerces we are to use. 
# As of Xerces-C 1.5.1, minor version numbers are used
my $XERCES_MAJOR_VERSION = '1.7';
my $XERCES_MINOR_VERSION = '0';
my $XERCES_LIB_VERSION = "$XERCES_MAJOR_VERSION.$XERCES_MINOR_VERSION";
my $XERCES_PERL_VERSION = $XERCES_LIB_VERSION . '_0';
my $XERCES_VERSION = "$XERCES_LIB_VERSION";

# this substitution will yield '1_4' from '1.4' to be used by 'LIBS'
$XERCES_LIB_VERSION =~ s/\./_/g;
my $LIBXERCES = "-lxerces-c$XERCES_LIB_VERSION";
$LIBS .= " $LIBXERCES";

# now we ensure that libxerces is in the library path
# if not we die()
print STDERR "Checking to see if libxerces is in your library path...";
my $lib;
($lib) = MM->new->ExtUtils::Liblist::ext($LIBS);

die <<EOE unless $lib;


    !!!WHOA!!!

I couldn\'t find $LIBXERCES anywhere in your library path. Begging to
differ with perl, this is most assuredly *NOT* harmless. This is a
critical error that will prevent you from running Xerces.pm.

Check your settings of \$XERCES_INCLUDE and \$XERCES_LIB, and rerun
'perl Makefile.PL'

EOE

print STDERR "Success!!\n";

# give some nice feedback for the user
print STDERR "Using Xerces-C version: $XERCES_VERSION\n";

my $HANDLER_LIB = '$(INST_ARCHLIB)/auto/Handler/Handler$(LIB_EXT)';

sub MY_postamble {
qq[

$HANDLER_LIB:
	\$(MAKE) -C Handler static
];

}
*MY::postamble = \&MY_postamble;

my @MACRO;
my @OPTIMIZE;
my $CFLAGS = '-D_REENTRANT';

# we only consider using SWIG if we are a Xerces Developer
if ($XERCES_DEVEL) {
  # replace this with the path to your Unix compatible find application
  my $FIND = 'find';

  # set up the custom headers
  my @handler_headers;
  chomp(@handler_headers = `$FIND Handler -name "*.swig.hpp"`);
  my @pre_swig_headers = qw(
			   );
  my $PRE_SWIG_HEADERS;
  my @PRE_SWIG_HEADERS;
  my $PRIVATE_HEADER_DIR = './Xerces_headers';

  foreach my $header (@pre_swig_headers) {
    my $outfile = "$PRIVATE_HEADER_DIR/$header";
    my $infile = "$XERCES_INCLUDE/$header";
    push(@PRE_SWIG_HEADERS,$outfile);
    $PRE_SWIG_HEADERS .= <<EOT;
$outfile: $infile
	preSwig.pl --directory $PRIVATE_HEADER_DIR $infile

EOT
  }

  sub Xerces_postamble {
    chomp(my @header_files = `$FIND Xerces_headers -name "*.hpp"`);
    push(@header_files,@handler_headers);
    local $" = ' ';
    <<TERMINUS;
$PRE_SWIG_HEADERS

Xerces.C: Xerces.i typemaps.i @PRE_SWIG_HEADERS @header_files postSource.pl 
	\$(SWIG) -DVERSION="$XERCES_PERL_VERSION" \$(INC) -package XML::Xerces -perl5 -c++ -shadow -o Xerces.C Xerces.i
	perl postSource.pl Xerces.C
	perl postModule.pl Xerces.pm


Xerces.pm: Xerces.C postModule.pl
	if [[ postModule.pl -nt Xerces.pm ]] ; then \\
\$(SWIG) -I. \$(INC) -package XML::Xerces -perl5 -c++ -shadow -o foo.C Xerces.i ; \\
rm foo.C ; \\
perl postModule.pl Xerces.pm ; \\
	fi

$HANDLER_LIB:
	\$(MAKE) -C Handler static
TERMINUS
  }

  print STDERR "Welcome Xerces Developer!\n";
  # if we're to use SWIG, we need to know which version is available
  my $swig = $SWIG || 'swig';
  @MACRO = ('macro'       => {
    'SWIG'         => "$swig",
  });

  # we'll assume that we want -g as a default
  @OPTIMIZE = (OPTIMIZE => '-g');

  # we want all warnings
  $CFLAGS .= ' -Wall';
#  print STDERR "Using SWIG version: SWIG_$ {sv_maj}_$ {sv_min}\n";
  *MY::postamble = \&Xerces_postamble;
}

# set up the list of object files to include in Xerces\$(OBJ_EXT)
my $OBJS = 'Xerces$(OBJ_EXT)';

# write the makefile
# see the hints/ directory for architecture specific stuff!
WriteMakefile(
  'AUTHOR'      => 'The Xerces-P developers',
  'ABSTRACT'    => 'Perl Interface for Xerces XML API',
  'CCFLAGS'     => $CFLAGS,
  'PM'          => {
    'Xerces.pm' => '$(INST_LIB)/XML/Xerces.pm',
    'DOMParse/DOMParse.pm' => '$(INST_LIB)/XML/Xerces/DOMParse.pm',
  },
  'INC'         => $INCLUDES,
  'MYEXTLIB'    => $HANDLER_LIB,
  'LIBS'        => [$LIBS],
  'NAME'        => 'XML::Xerces',
  'OBJECT'      => $OBJS,
  'DIR'         => ['DOMParse'],
  'VERSION'     => "$XERCES_PERL_VERSION",
  @OPTIMIZE,
  @MACRO
);

