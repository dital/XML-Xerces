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

my %VARS;

my $num = 0;
++$num while -e "$progname.$num.tmp";

for my $file (@ARGV) {
  next unless open FILE, $file;

  open TEMP, ">$progname.$num.tmp";

  my $CURR_CLASS = '';
  while(<FILE>) {

    if (/^package/) {
      ($CURR_CLASS) = m/package\s+XML::Xerces::([\w_]+);/;
      print TEMP;
      unless ($CURR_CLASS ne 'XML::Xerces'
	      and $CURR_CLASS ne 'XML::Xercesc'
	      and exists $VARS{$CURR_CLASS}) {
	$VARS{$CURR_CLASS}++;
	print TEMP 'use vars qw(@ISA %OWNER %ITERATORS %BLESSEDMEMBERS);', "\n";
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
      if ($CURR_CLASS eq 'DOM_Document') {
	print TEMP <<'EOT';
sub DESTROY {
    my $self = shift;
    # we remove an reference to the Parser that created us
    if (exists $OWNER{$self}->{__PARSER}) {
        undef $OWNER{$self}->{__PARSER};
    }
}
EOT
      }
      next;
    }

    # we remove all the enums inherited through DOM_Node
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
    my $self;
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
    my $self;
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
    my \$self;
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
    my $self;
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

    if ($CURR_CLASS =~ /(Perl(\w+)Handler)/) {
      my $class = $1;
      # this line assumed the first constructor, so we remove it
      if (/^sub.*__constructor__/) {
	remove_method(\*FILE);
	next;
      } elsif (/^sub\s+new/) {
	my $new = <<"EOT";
    my \$self;
    if (scalar \@args == 1) {
      \$self = XML::Xercesc::new_$ {class}__constructor__arg(\@args);
    } else {
      \$self = XML::Xercesc::new_$ {class}();
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
    my $self;
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

    if ($CURR_CLASS =~ /DOM_DOMException/) {
      if (/^sub\s+new/) {
	# add the reverse name lookup for the error codes
	print TEMP <<'EOT';
use vars qw(@CODES $INDEX_SIZE_ERR
	    $DOMSTRING_SIZE_ERR
	    $HIERARCHY_REQUEST_ERR
	    $WRONG_DOCUMENT_ERR
	    $INVALID_CHARACTER_ERR
	    $NO_DATA_ALLOWED_ERR
	    $NO_MODIFICATION_ALLOWED_ERR
	    $NOT_FOUND_ERR
	    $NOT_SUPPORTED_ERR
	    $INUSE_ATTRIBUTE_ERR
	    $INVALID_STATE_ERR
	    $SYNTAX_ERR
	    $INVALID_MODIFICATION_ERR
	    $NAMESPACE_ERR
	    $INVALID_ACCESS_ERR);

$CODES[$INDEX_SIZE_ERR] = 'INDEX_SIZE_ERR';
$CODES[$DOMSTRING_SIZE_ERR] = 'DOMSTRING_SIZE_ERR';
$CODES[$HIERARCHY_REQUEST_ERR] = 'HIERARCHY_REQUEST_ERR';
$CODES[$WRONG_DOCUMENT_ERR] = 'WRONG_DOCUMENT_ERR';
$CODES[$INVALID_CHARACTER_ERR] = 'INVALID_CHARACTER_ERR';
$CODES[$NO_DATA_ALLOWED_ERR] = 'NO_DATA_ALLOWED_ERR';
$CODES[$NO_MODIFICATION_ALLOWED_ERR] = 'NO_MODIFICATION_ALLOWED_ERR';
$CODES[$NOT_FOUND_ERR] = 'NOT_FOUND_ERR';
$CODES[$NOT_SUPPORTED_ERR] = 'NOT_SUPPORTED_ERR';
$CODES[$INUSE_ATTRIBUTE_ERR] = 'INUSE_ATTRIBUTE_ERR';
$CODES[$INVALID_STATE_ERR] = 'INVALID_STATE_ERR';
$CODES[$SYNTAX_ERR] = 'SYNTAX_ERR';
$CODES[$INVALID_MODIFICATION_ERR] = 'INVALID_MODIFICATION_ERR';
$CODES[$NAMESPACE_ERR] = 'NAMESPACE_ERR';
$CODES[$INVALID_ACCESS_ERR] = 'INVALID_ACCESS_ERR';
EOT
      }
    }

    ######################################################################
    #
    # Callback registration

    # fix a scoping bug for setErrorHandler. If we don't maintain an
    # internal reference to the error handler perl object it will
    # get destroyed if it goes out of scope. Then if an error occurs
    # perl will dump core

    # look for: *setErrorHandler = *XML::Xercesc::*_setErrorHandler;
    if (/\*XML::Xercesc::(\w+)_setErrorHandler/) {
      my $class = $1;
      print TEMP <<"EOT";
sub setErrorHandler {
  my (\$self,\$handler) = \@_;
  my \$retval;
  my \$callback = \$XML::Xerces::$ {class}::OWNER{\$self}->{__ERROR_HANDLER};
  if (defined \$callback) {
    \$retval = \$callback->set_callback_obj(\$handler);
  } else {
    \$callback = XML::Xerces::PerlErrorCallbackHandler->new(\$handler);
    \$XML::Xerces::$ {class}::OWNER{\$self}->{__ERROR_HANDLER} = \$callback;
  }
  XML::Xercesc::$ {class}_setErrorHandler(\$self,\$callback);
  return \$retval;
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
  my \$callback = \$XML::Xerces::$ {class}::OWNER{\$self}->{__ENTITY_RESOLVER};
  if (defined \$callback) {
    \$callback->set_callback_obj(\$handler);
  } else {
    \$callback = XML::Xerces::PerlEntityResolverHandler->new(\$handler);
    \$XML::Xerces::$ {class}::OWNER{\$self}->{__ENTITY_RESOLVER} = \$callback;
  }
  return XML::Xercesc::$ {class}_setEntityResolver(\$self,\$callback);
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
  my $callback = $XML::Xerces::SAXParser::OWNER{$self}->{__DOCUMENT_HANDLER};
  if (defined $callback) {
    $callback->set_callback_obj($handler);
  } else {
    $callback = XML::Xerces::PerlDocumentCallbackHandler->new($handler);
    $XML::Xerces::SAXParser::OWNER{$self}->{__DOCUMENT_HANDLER} = $callback;
  }
  return XML::Xercesc::SAXParser_setDocumentHandler($self,$callback);
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
  my $callback = $XML::Xerces::SAX2XMLReader::OWNER{$self}->{__CONTENT_HANDLER};
  if (defined $callback) {
    $callback->set_callback_obj($handler);
  } else {
    $callback = XML::Xerces::PerlContentCallbackHandler->new($handler);
    $XML::Xerces::SAX2XMLReader::OWNER{$self}->{__CONTENT_HANDLER} = $callback;
  }
  return XML::Xercesc::SAX2XMLReader_setContentHandler($self,$callback);
}
EOT
      # we don't print out the function
      next;
    }

    if ($CURR_CLASS eq 'DOM_Document') {
      if (/^sub\s+createTreeWalker/) {
	my $fix = <<'EOT';
    my ($self,$root,$what,$filter,$expand) = @_;
    my $callback = $XML::Xerces::DOM_TreeWalker::OWNER{$self}->{__NODE_FILTER};
    if (defined $callback) {
      $callback->set_callback_obj($filter);
    } else {
      $callback = XML::Xerces::PerlNodeFilterCallbackHandler->new($filter);
      $XML::Xerces::DOM_TreeWalker::OWNER{$self}->{__NODE_FILTER} = $callback;
    }
    my @args = ($self,$root,$what,$callback,$expand);
EOT
	fix_method(\*FILE,
		   \*TEMP,
		   qr/my \@args/,
		   $fix,
		   0);
	next;
      }
    }

    if ($CURR_CLASS eq 'DOM_Document') {
      if (/^sub\s+createNodeIterator/) {
	my $fix = <<'EOT';
    my ($self,$root,$what,$filter,$expand) = @_;
    my $callback = $XML::Xerces::DOM_NodeIterator::OWNER{$self}->{__NODE_FILTER};
    if (defined $callback) {
      $callback->set_callback_obj($filter);
    } else {
      $callback = XML::Xerces::PerlNodeFilterCallbackHandler->new($filter);
      $XML::Xerces::DOM_NodeIterator::OWNER{$self}->{__NODE_FILTER} = $callback;
    }
    my @args = ($self,$root,$what,$callback,$expand);
EOT
	fix_method(\*FILE,
		   \*TEMP,
		   qr/my \@args/,
		   $fix,
		   0);
	next;
      }
    }

    # look for: *getDocument = *XML::Xercesc::*_getDocument;
    if (/\*XML::Xercesc::DOMParser_getDocument/) {
      print TEMP <<'EOT';
# hold a reference to the parser internally, so that the
# document can exist after the parser has gone out of scope
sub getDocument {
  my ($self) = @_;
  my $result = XML::Xercesc::DOMParser_getDocument($self);
  $XML::Xerces::DOM_Document::OWNER{$result}->{__PARSER} = $self;
  return $result;
}
EOT
      # we don't print out the function
      next;
    }

    print TEMP;
  }
  close(FILE);
  close(TEMP);

  rename "$progname.$num.tmp", $file;
}

