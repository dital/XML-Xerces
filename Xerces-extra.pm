
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
use vars qw(@EXPORT_OK);
@EXPORT_OK = qw(error);
sub error {
  my $error = shift;
  print STDERR "Error in eval: ";
  if (ref $error) {
    if ($error->isa('XML::Xerces::DOM_DOMException')) {
      croak "Message: <", $error->getMessage(), 
	"> Code: ", $XML::Xerces::DOM_DOMException::CODES[$error->getCode];
    } else {
      croak $error->getMessage();
    }
  } else {
    croak $error;
  }
}

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

package XML::Xerces::DOM_NodeList;
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

package XML::Xerces::DOM_NamedNodeMap;
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

package XML::Xerces::DOM_Node;
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

package XML::Xerces::DOM_Entity;
sub to_hash {
  my $self = shift;
  if ($self->hasChildNodes) {
    return ($self->getNodeName(),
            $self->getFirstChild->getNodeValue());
  } else {
    return ($self->getNodeName(), '');
  }
}

package XML::Xerces::DOM_Text;
sub serialize {
  return $_[0]->quote_content($_[0]->getNodeValue);
}

package XML::Xerces::DOM_ProcessingInstruction;
sub serialize {
  my $output .= '<?' . $_[0]->getNodeName;
  if (length(my $str = $_[0]->getNodeValue)) {
    $output .= " $str"; 
  }
  $output .= '?>';
  return $output;
}

package XML::Xerces::DOM_Document;
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

package XML::Xerces::DOM_Element;
sub serialize {
  my ($self,$indent) = @_;
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

package XML::Xerces::DOM_EntityReference;
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

package XML::Xerces::DOM_CDATASection;
sub serialize {
  return '<![CDATA[' . $_[0]->getNodeValue . ']]>';
}

package XML::Xerces::DOM_Comment;
sub serialize {
  return '<!--' . $_[0]->getNodeValue . "-->\n";
}

package XML::Xerces::DOM_DocumentType;
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

package XML::Xerces::DOM_Entity;
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

package XML::Xerces::DOM_DOMException;
sub getMessage {
  return shift->{msg};
}

sub getCode {
  return shift->{code};
}

package XML::Xerces::DOM_Node;
use Carp;
sub isNull {
  carp("using DOM_Node::isNULL() is depricated");
  return 0;
}

sub actual_cast {
  carp("using DOM_Node::actual_cast() is depricated");
  return $_[0];
}

package XML::Xerces::DOM_Document;
use Carp;
sub createDocument {
  carp("using DOM_Document::createDocument() is depricated");
  return undef;
}

package XML::Xerces::DOMParser;
use Carp;
sub setToCreateXMLDeclTypeNode {
  carp("using DOMParser::setToCreateXMLDeclTypeNode() is depricated");
}

package XML::Xerces::DOM_Element;
sub get_text {
  my $node = shift;
  my @nodes = $node->getChildNodes();
  my $text;
  foreach (@nodes) {
    $text .= $_->getNodeValue()
      if $_->isa('XML::Xerces::DOM_Text');
  }
  return $text;
}
