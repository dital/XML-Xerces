package TestUtils;
use XML::Xerces;
use strict;
use vars qw($VERSION
	    @ISA
	    @EXPORT
	    @EXPORT_OK
	    $CATALOG
	    $DOM
	    $PERSONAL
	    $PUBLIC_RESOLVER_FILE_NAME
	    $SYSTEM_RESOLVER_FILE_NAME
	    $PERSONAL_SCHEMA_FILE_NAME
	    $SCHEMA_FILE_NAME
	    $SAMPLE_DIR
	    $PERSONAL_FILE_NAME
	    $PERSONAL_DTD_NAME
	    $PERSONAL_NO_DOCTYPE
	    $PERSONAL_NO_DOCTYPE_FILE_NAME
		$PERSONAL_NO_XMLDECL_FILE_NAME
		$PERSONAL_NO_XMLDECL
	   );
use Carp;
use Cwd;
require Exporter;

@ISA = qw(Exporter);

@EXPORT_OK = qw(result
		is_object
		error
		$DOM
		$CATALOG
		$PERSONAL_FILE_NAME
		$PUBLIC_RESOLVER_FILE_NAME
		$SYSTEM_RESOLVER_FILE_NAME
		$SCHEMA_FILE_NAME
		$PERSONAL_SCHEMA_FILE_NAME
		$PERSONAL_DTD_NAME
		$PERSONAL_NO_DOCTYPE_FILE_NAME
		$PERSONAL_NO_DOCTYPE
		$PERSONAL_NO_XMLDECL_FILE_NAME
		$PERSONAL_NO_XMLDECL
		$SAMPLE_DIR
		$PERSONAL);

BEGIN {
  # turn off annoying warnings
  $SIG{__WARN__} = 'IGNORE';

  $DOM = new XML::Xerces::DOMParser;

  my $ERROR_HANDLER = XML::Xerces::PerlErrorHandler->new();
  $DOM->setErrorHandler($ERROR_HANDLER);

  my $cwd = cwd();
  $cwd =~ s|/t/?$||;
  $SAMPLE_DIR = "$cwd/samples";
  $PERSONAL_FILE_NAME = "$SAMPLE_DIR/personal.xml";
  $PERSONAL_NO_DOCTYPE_FILE_NAME = "$SAMPLE_DIR/personal-no-doctype.xml";
  $PERSONAL_NO_XMLDECL_FILE_NAME = "$SAMPLE_DIR/personal-no-xmldecl.xml";

  $PERSONAL_DTD_NAME = $PERSONAL_FILE_NAME;
  $PERSONAL_DTD_NAME =~ s/\.xml/\.dtd/;
  $PERSONAL_SCHEMA_FILE_NAME = $PERSONAL_FILE_NAME;
  $PERSONAL_SCHEMA_FILE_NAME =~ s/\.xml/-schema.xml/;
  $SCHEMA_FILE_NAME = $PERSONAL_FILE_NAME;
  $SCHEMA_FILE_NAME =~ s/\.xml/.xsd/;
  $CATALOG = $PERSONAL_FILE_NAME;
  $CATALOG =~ s/personal/catalog/;
  $PUBLIC_RESOLVER_FILE_NAME = $PERSONAL_FILE_NAME;
  $PUBLIC_RESOLVER_FILE_NAME =~ s/personal/public/;
  $SYSTEM_RESOLVER_FILE_NAME = $PUBLIC_RESOLVER_FILE_NAME;
  $PUBLIC_RESOLVER_FILE_NAME =~ s/public/system/;
  open(PERSONAL, $PERSONAL_FILE_NAME)
    or die "Couldn't open $PERSONAL_FILE_NAME for reading";
  $/ = undef;
  $PERSONAL = <PERSONAL>;
  close PERSONAL;
  open(PERSONAL, $PERSONAL_NO_DOCTYPE_FILE_NAME)
    or die "Couldn't open $PERSONAL_NO_DOCTYPE_FILE_NAME for reading";
  $/ = undef;
  $PERSONAL_NO_DOCTYPE = <PERSONAL>;
  close PERSONAL;
  open(PERSONAL, $PERSONAL_NO_XMLDECL_FILE_NAME)
    or die "Couldn't open $PERSONAL_NO_XMLDECL_FILE_NAME for reading";
  $/ = undef;
  $PERSONAL_NO_XMLDECL = <PERSONAL>;
  close PERSONAL;
}

sub is_object {
  my ($obj) = @_;
  my $ref = ref($obj);
  return $ref
    && $ref ne 'ARRAY'
    && $ref ne 'SCALAR'
    && $ref ne 'HASH'
    && $ref ne 'CODE'
    && $ref ne 'GLOB'
    && $ref ne 'REF';
}

sub result {
  my ($cond,$fail) = @_;
  $fail = 0 unless defined $fail;
  my $rc = ($cond xor $fail);
  print STDOUT "not " if not $rc;
  print STDOUT "ok ", $main::i;
  if ($fail and $rc) {
    print STDERR " Failed test $main::i as expected, no worries";
  }
  print STDOUT "\n";
  $main::i++;
  return $rc;
}

sub error {
  my $error = shift;
  print STDERR "Error in eval: ";
  if (ref $error) {
    print STDERR $error->getMessage();
  } else {
    print STDERR $error;
  }
}
