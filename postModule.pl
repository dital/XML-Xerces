#!/usr/bin/perl
use lib '.';
use strict;
use SWIG qw(remove_method skip_to_closing_brace fix_method);

my($progname) = $0 =~ m"\/([^/]*)";

my @dom_node_list_methods = qw(DOM_Document::getElementsByTagName
			    DOM_Document::getElementsByTagNameNS
			    DOM_Element::getElementsByTagName
			    DOM_Element::getElementsByTagNameNS
			    DOM_Node::getChildNodes
			    );

my @dom_node_map_methods = qw(DOM_DocumentType::getEntities
			    DOM_DocumentType::getNotations
			    DOM_Node::getAttributes
			    );

my @dom_copy_methods = qw(DOM_XMLDecl
			  DOM_Attr
			 );

my @dom_node_methods = qw(DOM_Node::new
			DOM_Node::getParentNode
			DOM_Node::getFirstChild
			DOM_Node::getLastChild
			DOM_Node::getPreviousSibling
			DOM_Node::getNextSibling
			DOM_Node::cloneNode
			DOM_Node::insertBefore
			DOM_Node::replaceChild
			DOM_Node::removeChild
			DOM_Node::appendChild
			DOM_Document::importNode
			DOM_Entity::getFirstChild
			DOM_Entity::getLastChild
			DOM_Entity::getPreviousSibling
			DOM_Entity::getNextSibling
			DOM_NamedNodeMap::setNamedItem
			DOM_NamedNodeMap::getNamedItem
			DOM_NamedNodeMap::removedNamedItem
			DOM_NamedNodeMap::setNamedItemNS
			DOM_NamedNodeMap::getNamedItemNS
			DOM_NamedNodeMap::removedNamedItemNS
			DOM_NamedNodeMap::item
			DOM_NodeList::item
			DOM_NodeIterator::nextNode
			DOM_NodeIterator::previousNode
			DOM_Range::getStartContainer
			DOM_Range::getEndContainer
			DOM_Range::getCommonAncestorContainer
			DOM_TreeWalker::getCurrentNode
			DOM_TreeWalker::getParentNode
			DOM_TreeWalker::getFirstChild
			DOM_TreeWalker::getLastChild
			DOM_TreeWalker::getPreviousSibling
			DOM_TreeWalker::getNextSibling
			DOM_TreeWalker::getPreviousNode
			DOM_TreeWalker::getNextNode
		       );

my $num = 0;
++$num while -e "$progname.$num.tmp";

for my $file (@ARGV) {
  next unless open FILE, $file;

  open TEMP, ">$progname.$num.tmp";

  my $CURR_CLASS = '';
  while(<FILE>) {
    # we turn the DOM into the DOM
#     s/(?<!Xercesc::)IDOM/DOM/;
#     s/(?<=Xercesc::new_)DOM/IDOM/;

    if (/^package/) {
      ($CURR_CLASS) = m/package\s+XML::Xerces::([\w_]+);/;
      print TEMP;
      if ($CURR_CLASS eq 'DOM_Node') {
	print TEMP <<'TEXT';
use overload
    "==" => sub { $_[0]->operator_equal_to($_[1])},
    "!=" => sub { $_[0]->operator_not_equal_to($_[1])},
    "fallback" => 1;
*operator_not_equal_to = *XML::Xercesc::DOM_Node_operator_not_equal_to;
*operator_equal_to = *XML::Xercesc::DOM_Node_operator_equal_to;

TEXT
      }
      next;
    }
    # for some reason (I don't want to figure out) SWIG puts a bunch of
    # methods directly in the XML::Xerces namespace that don't belong there
    # and are duplicated within their proper classes, so we delete them
    if (/FUNCTION WRAPPERS/) {
      while (<FILE>) {
	next unless /\#\#\#\#\#\#\#\#\#\#\#\#\#/;
	last;
      }
    }

    # we're only keeping DESTROY for the parsers until we know better
    # we get core dumps if it's defined on some classes
    if (/sub DESTROY/) {
      unless (grep {$_ eq $CURR_CLASS} qw(DOMParser
					  SAXParser
					  SAX2XMLReader))
      {
	remove_method(\*FILE);
      } else {
	fix_method(\*FILE,
		   \*TEMP,
		   qr/my \$self = tied\(\%\{\$_\[0\]\}\);/,
		   "    return unless defined \$self;\n",
		   1);
      }
      next;
    }

    # we remove all the enums inherited through DOM_Node and DOM_Node
    next if /^*[_A-Z]+_NODE =/ && !/DOM_Node/;

    # now we set these aliases correctly
    s/\*XML::Xerces::/*XML::Xercesc::/;

    #######################################################################
    #
    # MUNG MODULE for XMLCh support
    #
    #    CHANGE "$args[0] = tied(%{$args[0]})"
    #    TO     "$args[0] = tied(%{$args[0]}) || $args[0]"
    #    then we wrap it in a defined $args[0] to remove the irritating warning
    if (m{\$args\[0\]\s+=\s+tied\(\%\{\$args\[0\]\}\)}) {
      print TEMP <<'EOT';
       if (defined $args[0]) {
	 $args[0] = tied(%{$args[0]}) || $args[0];
       }
EOT
      next;
    }


    #   CHANGE "return undef if (!defined($result))"
    #   TO     "return $result unless ref($result) =~ m[XML::Xerces]"
    # split on multiple lines to be readable, using s{}{}x
    s{
      return\s*undef\s*if\s*\(\!defined\(\$result\)\)
     }{return \$result unless ref(\$result) =~ m[XML::Xerces]}x;

    #######################################################################
    #
    # Perl API specific changes
    #

    #   DOM_NodeList: automatically convert to perl list
    #      if called in a list context
    if (grep {/$CURR_CLASS/} @dom_node_list_methods) {
      if (my ($sub) = /^sub\s+([\w_]+)/) {
	$sub = "$ {CURR_CLASS}::$sub";
	if (grep {/$sub$/} @dom_node_list_methods) {
	  my $fix = <<'EOT';
    unless (defined $result) {
      return () if wantarray;
      return undef; # if *not* wantarray
    }
    return $result->to_list() if wantarray;
    $DOM_NodeList::OWNER{$result} = 1; 
EOT
	  fix_method(\*FILE,
		     \*TEMP,
		     qr/return undef/,
		     $fix
		    );
	  next;
	}
      }
    }

    #   DOM_NamedNodeMap: automatically convert to perl hash
    #      if called in a list context
    if (grep {/$CURR_CLASS/} @dom_node_map_methods) {
      if (my ($sub) = /^sub\s+([\w_]+)/) {
	$sub = "$ {CURR_CLASS}::$sub";
	if (grep {/$sub$/} @dom_node_map_methods) {
	  my $fix = <<'EOT';
    unless (defined $result) {
      return () if wantarray;
      return undef; # if *not* wantarray
    }
    return $result->to_hash() if wantarray;
    $DOM_NamedNodeMap::OWNER{$result} = 1;
EOT
	  fix_method(\*FILE,
		     \*TEMP,
		     qr/return undef/,
		     $fix,
		     );
	  next;
	}
      }
    }

    #   DOM_Node: automatically convert to base class
#     if (grep {/$CURR_CLASS/} @dom_node_methods) {
#       if (my ($sub) = /^sub\s+([\w_]+)/) {
# 	$sub = "$ {CURR_CLASS}::$sub";
# 	if (grep {/$sub$/} @dom_node_methods) {
# 	  my $fix = <<'EOT';
#     # automatically convert to base class
#     $result = $result->actual_cast();
# EOT
# 	  fix_method(\*FILE,
# 		     \*TEMP,
# 		     qr/return undef/,
# 		     $fix,
# 		     1);
# 	  next;
# 	}
#       }
#     }

    #   MemBufInputSource: new has *optional* SYSTEM ID
    if ($CURR_CLASS eq 'MemBufInputSource') {
      if (/^sub\s+new/) {
	my $fix = <<'EOT';
    # SYSTEM ID is *optional*
    if (scalar @args == 1) {
      push(@args,'FAKE_SYSTEM_ID');
    }
EOT
	fix_method(\*FILE,
		   \*TEMP,
		   qr/my \@args/,
		   $fix,
		   1);
	next;
      }
    }

    # we need to fix setAttribute() so that undefined values don't
    # cause a core dump
    if ($CURR_CLASS =~ /DOM_Element/) {
      if (/XML::Xercesc::DOM_Element_setAttribute;/) {
	print TEMP <<"EOT";
sub setAttribute {
    my (\$self,\$attr,\$val) = \@_;
    return unless defined \$attr and defined \$val;
    my \$result = XML::Xercesc::DOM_Element_setAttribute(\@_);
    return \$result unless ref(\$result) =~ m[XML::Xerces];
    \$XML::Xerces::DOM_Attr::OWNER{\$result} = 1; 
    my %resulthash;
    tie %resulthash, ref(\$result), \$result;
    return bless \\\%resulthash, ref(\$result);
}
EOT
        next;
      }
    }

    ######################################################################
    #
    # Method Overloads

    # don't print out SWIG's default overloaded methods, we'll make our own
    next if /XML::Xerces.*__overload__/;

    if ($CURR_CLASS =~ /(DOMParser|SAXParser)/) {
      my $parser = $1;
      if (/XML::Xercesc::${parser}_parse;/) {
	print TEMP <<"EOT";
sub parse {
    my \@args = \@_;
    if (ref \$args[1]) {
      XML::Xercesc::${parser}_parse__overload__is(\@args);
    } else {
      XML::Xercesc::${parser}_parse(\@args);
    }
}
EOT
        next;
      } elsif (/XML::Xercesc::${parser}_parseFirst/) {
	print TEMP <<"EOT";
sub parseFirst {
    my \@args = \@_;
    if (ref \$args[1]) {
      XML::Xercesc::${parser}_parseFirst__overload__is(\@args);
    } else {
      XML::Xercesc::${parser}_parseFirst(\@args);
    }
}
EOT
        next;
      }
    }

    if ($CURR_CLASS =~ /Attributes/) {
      if (/XML::Xercesc::Attributes_getType;/) {
	print TEMP <<'EOT';
sub getType {
    my @args = @_;
    if (scalar @args == 2) {
      if ($args[1] =~ /^\d+$/) {
        return XML::Xercesc::Attributes_getType__overload__index(@args);
      } else {
        return XML::Xercesc::Attributes_getType__overload__qname(@args);
      }
    } else {
      return XML::Xercesc::Attributes_getType(@args);
    }
}
EOT
        next;
      } elsif (/XML::Xercesc::Attributes_getValue;/) {
	print TEMP <<'EOT';
sub getValue {
    my @args = @_;
    if (scalar @args == 2) {
      if ($args[1] =~ /^\d+$/) {
        return XML::Xercesc::Attributes_getValue__overload__index(@args);
      } else {
        return XML::Xercesc::Attributes_getValue__overload__qname(@args);
      }
    } else {
      return XML::Xercesc::Attributes_getValue(@args);
    }
}
EOT
        next;
      } elsif (/XML::Xercesc::Attributes_getIndex;/) {
	print TEMP <<'EOT';
sub getIndex {
    my @args = @_;
    if (scalar @args == 2) {
      return XML::Xercesc::Attributes_getIndex__overload__qname(@args);
    } else {
      return XML::Xercesc::Attributes_getIndex(@args);
    }
}
EOT
        next;
      }
    }

    if ($CURR_CLASS =~ /AttributeList/) {
      if (/XML::Xercesc::AttributeList_getType;/) {
	print TEMP <<'EOT';
sub getType {
    my @args = @_;
    if ($args[1] =~ /^\d+$/) {
      return XML::Xercesc::AttributeList_getType__overload__index(@args);
    } else {
      return XML::Xercesc::AttributeList_getType(@args);
    }
}
EOT
        next;
      } elsif (/XML::Xercesc::AttributeList_getValue;/) {
	print TEMP <<'EOT';
sub getValue {
    my @args = @_;
    if ($args[1] =~ /^\d+$/) {
      return XML::Xercesc::AttributeList_getValue__overload__index(@args);
    } else {
      return XML::Xercesc::AttributeList_getValue(@args);
    }
}
EOT
        next;
      }
    }

    if ($CURR_CLASS =~ /URLInputSource/) {
      if (/^sub.*__constructor__/) {
	remove_method(\*FILE);
	next;
      } elsif (/^sub\s+new/) {
	my $subst_func = sub {$_[0] = '' if $_[0] =~ /tied/;};
	my $new = <<'EOT';
    if (ref $args[0]) {
      $args[0] = tied(%{$args[0]});
      $self = XML::Xercesc::new_URLInputSource(@args);
    } elsif (scalar @args == 2) {
      $self = XML::Xercesc::new_URLInputSource__constructor__sys(@args);
    } else {
      $self = XML::Xercesc::new_URLInputSource__constructor__pub(@args);
    }
EOT
	fix_method(\*FILE,
		   \*TEMP,
		   qr/\$self = XML::Xercesc::new_/,
		   $new,
		   0,
		   $subst_func,
		  );
	next;
      }
    }

    if ($CURR_CLASS =~ /XMLUri/) {
      if (/^sub.*__constructor__/) {
	remove_method(\*FILE);
	next;
      } elsif (/^sub\s+new/) {
	my $subst_func = sub {$_[0] = '' if $_[0] =~ /tied/;};
	my $new = <<'EOT';
    if (scalar @args == 1) {
      $self = XML::Xercesc::new_XMLUri__constructor__uri(@args);
    } else {
      $args[0] = tied(%{$args[0]});
      $self = XML::Xercesc::new_XMLUri(@args);
    }
EOT
	fix_method(\*FILE,
		   \*TEMP,
		   qr/\$self = XML::Xercesc::new_/,
		   $new,
		   0,
		   $subst_func,
		  );
	next;
      }
    }

    if (grep {/$CURR_CLASS/} @dom_copy_methods) {
      if (/^sub.*__constructor__/) {
	remove_method(\*FILE);
	next;
      } elsif (/^sub\s+new/) {
	my $new = <<"EOT";
    if (ref \$pkg) {
      \$self = XML::Xercesc::new_${CURR_CLASS}__constructor__copy(\$pkg);
      \$pkg = ref \$pkg;
    } else {
      \$self = XML::Xercesc::new_${CURR_CLASS}();
    }
EOT
	fix_method(\*FILE,
		   \*TEMP,
		   qr/\$self = XML::Xercesc::new_/,
		   $new);
	next;
      }
    }

    if ($CURR_CLASS =~ /LocalFileInputSource/) {
      # this line assumed the first constructor, so we remove it
      if (/^sub.*__constructor__/) {
	remove_method(\*FILE);
	next;
      } elsif (/^sub\s+new/) {
	my $new = <<'EOT';
    if (scalar @args == 1) {
      $self = XML::Xercesc::new_LocalFileInputSource(@args);
    } else {
      $self = XML::Xercesc::new_LocalFileInputSource__constructor__base(@args);
    }
EOT
	fix_method(\*FILE,
		   \*TEMP,
		   qr/\$self = XML::Xercesc::new_/,
		   $new);
	next;
      }
    }

    if (/XML::Xerces::XMLReaderFactory_createXMLReader/) {
	print TEMP <<'EOT';
sub createXMLReader {
    my @args = @_;
    if (scalar @args == 2) {
      XML::Xercesc::XMLReaderFactory_createXMLReader__overload__1(@args);
    } else {
      XML::Xercesc::XMLReaderFactory_createXMLReader(@args);
    }
}
EOT
      # we don't print out the function
      next;
    }

    if ($CURR_CLASS =~ /XMLURL/) {
      if (/^sub.*__constructor__/) {
	remove_method(\*FILE);
	next;
      } elsif (/^sub\s+new/) {
	my $new = <<'EOT';
    if (ref($args[0])) {
      if (scalar @args == 1) {
        $self = XML::Xercesc::new_XMLURL__constructor__copy(@args);
      } else {
        $self = XML::Xercesc::new_XMLURL__constructor__url_base(@args);
      }
    } elsif (! scalar @args) {
      $self = XML::Xercesc::new_XMLURL();
    } elsif (scalar @args == 1) {
      $self = XML::Xercesc::new_XMLURL__constructor__text(@args);
    } else {
      $self = XML::Xercesc::new_XMLURL__constructor__base(@args);
    }
EOT
	fix_method(\*FILE,
		   \*TEMP,
		   qr/\$self = XML::Xercesc::new_/,
		   $new,
		   0,
		  );
	next;
      }

      if (/XML::Xercesc::XMLURL_makeRelativeTo/) {
	print TEMP <<'EOT';
sub makeRelativeTo {
    my @args = @_;
    if (ref($args[1])) {
      XML::Xercesc::XMLURL_makeRelativeTo__overload__XMLURL(@args);
    } else {
      XML::Xercesc::XMLURL_makeRelativeTo(@args);
    }
}
EOT
        # we don't print out the function
        next;
      } elsif (/XML::Xercesc::XMLURL_setURL/) {
	print TEMP <<'EOT';
sub setURL {
    my @args = @_;
    if (scalar @args == 2) {
      XML::Xercesc::XMLURL_setURL(@args);
    } elsif (ref($args[1])) {
      XML::Xercesc::XMLURL_setURL__overload__XMLURL(@args);
    } else {
      XML::Xercesc::XMLURL_setURL__overload__string(@args);
    }
}
EOT
        # we don't print out the function
        next;
      }
    }

    ######################################################################
    #
    # Callback registration

    # fix a scoping bug for setErrorHandler. If we don't maintain an
    # internal reference to the error handler perl object it will
    # get destroyed if it goes out of scope. Then if an error occurs
    # perl will dump core
    #
    # look for: *setErrorHandler = *XML::Xercesc::*_setErrorHandler;
    if (/\*XML::Xercesc::(\w+)_setErrorHandler/) {
      my $class = $1;
      print TEMP <<"EOT";
sub setErrorHandler {
  my (\$self,\$handler) = \@_;
  my \$callback = XML::Xerces::PerlErrorCallbackHandler->new();
  \$callback->set_callback_obj(\$handler);
  XML::Xercesc::$ {class}_setErrorHandler(\$self,\$callback);
  \$self{__ERROR_HANDLER} = \$callback;
}
EOT
      # we don't print out the function
      next;
    }

    # this same bug is likely to affect setEntityResolver() as well
    # look for: *setEntityResolver = *XML::Xercesc::*_setEntityResolver;
    if (/\*XML::Xercesc::(\w+)_setEntityResolver/) {
      my $class = $1;
      print TEMP <<"EOT";
sub setEntityResolver {
  my (\$self,\$handler) = \@_;
  my \$callback = XML::Xerces::PerlEntityResolverHandler->new();
  \$callback->set_callback_obj(\$handler);
  XML::Xercesc::$ {class}_setEntityResolver(\$self,\$callback);
  \$self{__ENTITY_RESOLVER} = \$callback;
}
EOT
      # we don't print out the function
      next;
    }
    # look for: *setDocumentHandler = *XML::Xercesc::SAXParser_setDocumentHandler;
    if (/SAXParser_setDocumentHandler/) {
      print TEMP <<'EOT';
sub setDocumentHandler {
  my ($self,$handler) = @_;
  my $callback = XML::Xerces::PerlDocumentCallbackHandler->new();
  $callback->set_callback_obj($handler);
  XML::Xercesc::SAXParser_setDocumentHandler($self,$callback);
  $self{__DOCUMENT_HANDLER} = $callback;
}
EOT
      # we don't print out the function
      next;
    }
    # this same bug is likely to affect setContentHandler() as well
    # look for: *setContentHandler = *XML::Xercesc::SAX2XMLReader_setContentHandler;
    if (/SAX2XMLReader_setContentHandler/) {
      print TEMP <<'EOT';
sub setContentHandler {
  my ($self,$handler) = @_;
  my $callback = XML::Xerces::PerlContentCallbackHandler->new();
  $callback->set_callback_obj($handler);
  XML::Xercesc::SAX2XMLReader_setContentHandler($self,$callback);
  # maintain an internal reference
  $self{__CONTENT_HANDLER} = $callback;
}
EOT
      # we don't print out the function
      next;
    }

    print TEMP;
  }

my $extra = <<'EXTRA';
############# Class : XML::Xerces::PerlContentHandler ##############
package XML::Xerces::PerlContentHandler;
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
@ISA = qw();
sub new {
  my $class = shift;
  return bless {}, $class;
}

sub resolve_entity {
  return undef;
}


############# Class : XML::Xerces::PerlErrorHandler ##############
package XML::Xerces::PerlErrorHandler;
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
  warn(<<EOT);
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
  die(<<EOT);
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
  die(<<EOT);
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
    if ($node->getNodeType == $XML::Xerces::DOM_Node::ENTITY_NODE) {
      push(@list, $node->to_hash());
    } else {
      push(@list, $node->getNodeName());
      push(@list,$node->getNodeValue());
    }
  }
  return @list;
}

package XML::Xerces::DOM_Node;

sub quote_content {
  my ($self,$node_value) = @_;

  $node_value =~ s/&/&amp;/g;
  $node_value =~ s/</&lt;/g;
  $node_value =~ s/>/&gt;/g;
  $node_value =~ s/\"/&quot;/g;
  $node_value =~ s/\'/&apos;/g;

  return $node_value;
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
      $attribute = $attributes->item($ix);
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

package XML::Xerces::DOM_Node;
sub isNull {
  warn("using DOM_Node::isNULL() is depricated");
  return 0;
}

sub actual_cast {
  warn("using DOM_Node::actual_cast() is depricated");
  return $_[0];
}

package XML::Xerces::DOM_Document;
sub createDocument {
  warn("using DOM_Document::createDocument() is depricated");
  return undef;
}

package XML::Xerces::DOMParser;
sub setToCreateXMLDeclTypeNode {
  warn("using DOMParser::setToCreateXMLDeclTypeNode() is depricated");
}

package XML::Xerces;
#
# NOTICE: We are automatically calling XMLPlatformUtils::Initialize()
#   when the module is loaded. Do not call it on your own.
#
#
XML::Xerces::XMLPlatformUtils::Initialize();

1;
EXTRA
  close(FILE);
  print TEMP $extra;
  close(TEMP);

  rename "$progname.$num.tmp", $file;
}

