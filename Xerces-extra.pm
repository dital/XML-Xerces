
use strict;

INIT {
  # NOTICE: We are automatically calling XMLPlatformUtils::Initialize()
  #   when the module is loaded. Don't bother calling it on your own.
  #
  #
  XML::Xerces::XMLPlatformUtils::Initialize();
}

END {
  # NOTICE: We are automatically calling XMLPlatformUtils::Terminate()
  #   when the module is unloaded. Don't bother calling it on your own.
  #
  #
  XML::Xerces::XMLPlatformUtils::Terminate();
}

package XML::Xerces;
use Carp;
use vars qw(@EXPORT_OK $VERSION);
@EXPORT_OK = qw(error);
$VERSION = 250.0;

sub error {
  my $error = shift;
  my $context = shift;
  my $msg = "Error in eval: ";
  if (ref $error) {
    if ($error->isa('XML::Xerces::DOMException')) {
      $msg .= "Message: <"
        . $error->getMessage()
	. "> Code: "
        . $XML::Xerces::DOMException::CODES[$error->getCode];
    } else {
      $msg .= $error->getMessage();
    }
  } else {
    $msg .= $error;
  }
  $msg .= ", Context: $context"
    if defined $context;
  croak($msg);
}

package XML::Xerces::DOMException;
use vars qw(@CODES);
@CODES = qw(__NONEXISTENT__
	    INDEX_SIZE_ERR
	    DOMSTRING_SIZE_ERR
	    HIERARCHY_REQUEST_ERR
	    WRONG_DOCUMENT_ERR
	    INVALID_CHARACTER_ERR
	    NO_DATA_ALLOWED_ERR
	    NO_MODIFICATION_ALLOWED_ERR
	    NOT_FOUND_ERR
	    NOT_SUPPORTED_ERR
	    INUSE_ATTRIBUTE_ERR
	    INVALID_STATE_ERR
	    SYNTAX_ERR
	    INVALID_MODIFICATION_ERR
	    NAMESPACE_ERR
	    INVALID_ACCESS_ERR
	   );

############# Class : XML::Xerces::PerlContentHandler ##############
package XML::Xerces::PerlContentHandler;
use vars qw(@ISA);
@ISA = qw();
sub new {
  my $class = shift;
  return bless {}, $class;
}

sub start_element {}
sub end_element {}
sub start_prefix_mapping {}
sub end_prefix_mapping {}
sub skipped_entity {}
sub start_document {}
sub end_document {}
sub reset_document {}
sub characters {}
sub processing_instruction {}
sub set_document_locator {}
sub ignorable_whitespace {}


############# Class : XML::Xerces::PerlDocumentHandler ##############
package XML::Xerces::PerlDocumentHandler;
use vars qw(@ISA);
@ISA = qw();
sub new {
  my $class = shift;
  return bless {}, $class;
}

sub start_element {}
sub end_element {}
sub start_document {}
sub end_document {}
sub reset_document {}
sub characters {}
sub processing_instruction {}
sub set_document_locator {}
sub ignorable_whitespace {}


############# Class : XML::Xerces::PerlEntityResolver ##############
package XML::Xerces::PerlEntityResolver;
use vars qw(@ISA);
@ISA = qw();
sub new {
  my $class = shift;
  return bless {}, $class;
}

sub resolve_entity {
  return undef;
}


############# Class : XML::Xerces::PerlNodeFilter ##############
package XML::Xerces::PerlNodeFilter;
use vars qw(@ISA);
@ISA = qw();
sub new {
  my $class = shift;
  return bless {}, $class;
}

sub acceptNode {
  return undef;
}


############# Class : XML::Xerces::PerlErrorHandler ##############
package XML::Xerces::PerlErrorHandler;
use Carp;
use vars qw(@ISA);
@ISA = qw();
sub new {
  my $class = shift;
  return bless {}, $class;
}

sub warning {
  my $system_id = $_[1]->getSystemId;
  my $line_num = $_[1]->getLineNumber;
  my $col_num = $_[1]->getColumnNumber;
  my $msg = $_[1]->getMessage;
  carp(<<EOT);
WARNING:
FILE:    $system_id
LINE:    $line_num
COLUMN:  $col_num
MESSAGE: $msg
EOT
}

sub error {
  my $system_id = $_[1]->getSystemId;
  my $line_num = $_[1]->getLineNumber;
  my $col_num = $_[1]->getColumnNumber;
  my $msg = $_[1]->getMessage;
  croak(<<EOT);
ERROR:
FILE:    $system_id
LINE:    $line_num
COLUMN:  $col_num
MESSAGE: $msg
EOT
}

sub fatal_error {
  my $system_id = $_[1]->getSystemId;
  my $line_num = $_[1]->getLineNumber;
  my $col_num = $_[1]->getColumnNumber;
  my $msg = $_[1]->getMessage;
  croak(<<EOT);
FATAL ERROR:
FILE:    $system_id
LINE:    $line_num
COLUMN:  $col_num
MESSAGE: $msg
EOT
}


sub reset_errors {}

package XML::Xerces::XMLAttDefList;
#
# This class is both a list and a hash, so at the moment we
# enable users to choose how to access the information. Perhaps
# in the future we will use an order preserving hash like Tie::IxHash.
#

# convert the AttDefList to a perl list
sub to_list {
  my $self = shift;
  my @list;
  if ($self->hasMoreElements()) {
    while ($self->hasMoreElements()) {
      push(@list,$self->nextElement());
    }
  }
  return @list;
}

# convert the AttDefList to a perl hash
sub to_hash {
  my $self = shift;
  my %hash;
  if ($self->hasMoreElements()) {
    while ($self->hasMoreElements()) {
      my $attr = $self->nextElement();
      $hash{$attr->getFullName()} = $attr;
    }
  }
  return %hash;
}

package XML::Xerces::DOMNodeList;
# convert the NodeList to a perl list
sub to_list {
  my $self = shift;
  my @list;
  for (my $i=0;$i<$self->getLength();$i++) {
    push(@list,$self->item($i));
  }
  return @list;
}

package XML::Xerces::Attributes;
sub to_hash {
  my $self = shift;
  my %hash;
  for (my $i=0; $i < $self->getLength(); $i++) {
    my $qname = $self->getQName($i);
    $hash{$qname}->{localName} = $self->getLocalName($i);
    $hash{$qname}->{URI} = $self->getURI($i);
    $hash{$qname}->{value} = $self->getValue($i);
    $hash{$qname}->{type} = $self->getType($i);
  }
  return %hash;
}

package XML::Xerces::AttributeList;
sub to_hash {
  my $self = shift;
  my %hash;
  for (my $i=0;$i<$self->getLength();$i++) {
    $hash{$self->getName($i)} = $self->getValue($i)
  }
  return %hash;
}

package XML::Xerces::DOMNamedNodeMap;
# convert the NamedNodeMap to a perl hash
sub to_hash {
  my $self = shift;
  my @list;
  for (my $i=0;$i<$self->getLength();$i++) {
    my $node = $self->item($i);
    push(@list, $node->to_hash());
  }
  return @list;
}

package XML::Xerces::DOMNode;
sub to_hash {
  my $self = shift;
  return ($self->getNodeName,$self->getNodeValue);
}

sub quote_content {
  my ($self,$node_value) = @_;

  $node_value =~ s/&/&amp;/g;
  $node_value =~ s/</&lt;/g;
  $node_value =~ s/>/&gt;/g;
  $node_value =~ s/\"/&quot;/g;
  $node_value =~ s/\'/&apos;/g;

  return $node_value;
}

package XML::Xerces::DOMEntity;
sub to_hash {
  my $self = shift;
  if ($self->hasChildNodes) {
    return ($self->getNodeName(),
            $self->getFirstChild->getNodeValue());
  } else {
    return ($self->getNodeName(), '');
  }
}

package XML::Xerces::DOMText;
sub serialize {
  return $_[0]->quote_content($_[0]->getNodeValue);
}

package XML::Xerces::DOMProcessingInstruction;
sub serialize {
  my $output .= '<?' . $_[0]->getNodeName;
  if (length(my $str = $_[0]->getNodeValue)) {
    $output .= " $str"; 
  }
  $output .= '?>';
  return $output;
}

package XML::Xerces::DOMDocument;
sub serialize {
  my $output;
  my $indent = 2;
  for(my $child = $_[0]->getFirstChild() ;
     defined $child ;
     $child = $child->getNextSibling())
  {
    $output .= $child->serialize($indent);
  }
  return "$output\n";
}

package XML::Xerces::DOMElement;
sub serialize {
  my ($self,$indent) = @_;
  $indent ||= 0;
  my $output;
  ELEMENT: {
    my $node_name = $self->getNodeName;
    $output .= "<$node_name";

    my $attributes = $self->getAttributes;
    my $attribute_count = $attributes->getLength;

    for(my $ix = 0 ; $ix < $attribute_count ; ++$ix) {
      my $attribute = $attributes->item($ix);
      $output .= ' ' . $attribute->getNodeName . '="' . $self->quote_content($attribute->getNodeValue) . '"';
    }

    my $child = $self->getFirstChild();
    if (!defined $child) {
      $output .= '/>';
      last ELEMENT;
    }

    $output .= '>';
    while (defined $child) {
      $output .= $child->serialize($indent+2);
      $child = $child->getNextSibling();
    }
    $output .= "</$node_name>";
  }
  return $output;
}

package XML::Xerces::DOMEntityReference;
sub serialize {
  my ($self) = @_;
  my $output;
  for(my $child = $self->getFirstChild() ;
     defined $child;
     $child = $child->getNextSibling())
  {
    $output .= $child->serialize();
  }
  return $output;
}

package XML::Xerces::DOMCDATASection;
sub serialize {
  return '<![CDATA[' . $_[0]->getNodeValue . ']]>';
}

package XML::Xerces::DOMComment;
sub serialize {
  return '<!--' . $_[0]->getNodeValue . "-->\n";
}

package XML::Xerces::DOMDocumentType;
sub serialize {
  my $output;
  $output .= '<!DOCTYPE ' . $_[0]->getNodeName;

  my $id;
  if ($id = $_[0]->getPublicId) {
    $output .= qq[ PUBLIC "$id"];
    if ($id = $_[0]->getSystemId) {
      $output .= qq[ "$id"];
    }
  } elsif ($id = $_[0]->getSystemId) {
    $output .= qq[ SYSTEM "$id"];
  }

  if ($id = $_[0]->getInternalSubset) {
    $output .= " [$id]";
  }

  $output .= ">\n";
  return $output;
}

package XML::Xerces::DOMEntity;
sub serialize {
  my $output;
  $output .= '<!ENTITY ' . $_[0]->getNodeName;

  my $id;
  if ($id = $_[0]->getPublicId) { $output .= qq[ PUBLIC "$id"]; }
  if ($id = $_[0]->getSystemId) { $output .= qq[ SYSTEM "$id"]; }
  if ($id = $_[0]->getNotationName) { $output .= qq[ NDATA "$id"]; }

  $output .= '>';
  return $output;
}

package XML::Xerces::DOMException;
sub getMessage {
  return shift->{msg};
}

sub getCode {
  return shift->{code};
}

# in previous versions we needed to define this method
# but it is now obsolete
package XML::Xerces::DOMElement;
sub get_text {
  my $self = shift;
  warn "XML::Xerces::DOMElement::get_text is depricated, use getTextContent instead";
  return $self->getTextContent(@_);
}

package XML::Xerces::XMLCatalogResolver;
use strict;
use Carp;
use vars qw($VERSION
	    @ISA
	    @EXPORT
	    @EXPORT_OK
	   );
require Exporter;

@ISA = qw(Exporter XML::Xerces::PerlEntityResolver);
@EXPORT_OK = qw();

sub new {
  my $pkg = shift;
  my $catalog = shift;
  my $self = bless {}, $pkg;
  $self->catalog($catalog);
  $self->initialize()
    if defined $catalog;
  return $self;
}

sub initialize {
  my $self = shift;
  my $CATALOG = $self->catalog();
  XML::Xerces::error (__PACKAGE__ . ": Must set catalog before calling initialize")
      unless defined $CATALOG;

  my $DOM = XML::Xerces::XercesDOMParser->new();
  my $ERROR_HANDLER = XML::Xerces::PerlErrorHandler->new();
  $DOM->setErrorHandler($ERROR_HANDLER);

  # we parse the example XML Catalog
  eval{$DOM->parse($CATALOG)};
  XML::Xerces::error ($@, __PACKAGE__ . ": Couldn't parse catalog: $CATALOG")
      if $@;

  # now retrieve the mappings and store them
  my $doc = $DOM->getDocument();
  my @maps = $doc->getElementsByTagName('Map');
  my %maps = map {($_->getAttribute('PublicId'),
		   $_->getAttribute('HRef'))} @maps;
  $self->maps(\%maps);
  my @remaps = $doc->getElementsByTagName('Remap');
  my %remaps = map {($_->getAttribute('SystemId'),
		     $_->getAttribute('HRef'))} @remaps;
  $self->remaps(\%remaps);
}

sub catalog {
  my $self = shift;
  if (@_) {
    $self->{__CATALOG} = shift;
  }
  return $self->{__CATALOG};
}

sub maps {
  my $self = shift;
  if (@_) {
    $self->{__MAPS} = shift;
  }
  return $self->{__MAPS};
}

sub remaps {
  my $self = shift;
  if (@_) {
    $self->{__REMAPS} = shift;
  }
  return $self->{__REMAPS};
}

sub resolve_entity {
  my ($self,$pub,$sys) = @_;
#   print STDERR "Got PUBLIC: $pub\n";
#   print STDERR "Got SYSTEM: $sys\n";

  XML::Xerces::error (__PACKAGE__ . ": Must call initialize before using the resolver")
      unless defined $self->maps or defined $self->remaps;

  # now check which one we were asked for
  my $href;
  if ($pub) {
    $href = $self->maps->{$pub};
  }
  if ((not defined $href) and $sys) {
    $href = $self->remaps->{$sys};
  }
  if (not defined $href) {
    croak("could not resolve PUBLIC id:[$pub] or SYSTEM id: [$sys] using catalog: ["
	  . $self->catalog . "]");
  }

  my $is = eval {XML::Xerces::LocalFileInputSource->new($href)};
  error($@,"Couldn't create input source for $href")
      if $@;
  return $is;
}

