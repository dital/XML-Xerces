#!/usr/bin/perl
use lib '.';
use strict;
use SWIG qw(remove_method skip_to_closing_brace fix_method);

my($progname) = $0 =~ m"\/([^/]*)";

my @domnode_list_methods = qw(DOMDocument::getElementsByTagName
			    DOMDocument::getElementsByTagNameNS
			    DOMElement::getElementsByTagName
			    DOMElement::getElementsByTagNameNS
			    DOMNode::getChildNodes
			    );

my @domnode_map_methods = qw(DOMDocumentType::getEntities
			    DOMDocumentType::getNotations
			    DOMNode::getAttributes
			    );

my @domcopy_methods = qw(DOMXMLDecl
			  DOMAttr
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
      unless (grep {$_ eq $CURR_CLASS} qw(XercesDOMParser
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
      if ($CURR_CLASS eq 'DOMDocument') {
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

    # we remove all the enums inherited through DOMNode
    next if /^*[_A-Z]+_NODE =/ && !/DOMNode/;

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
     }{return \$result unless UNIVERSAL::isa(\$result,'XML::Xerces')}x;

    #######################################################################
    #
    # Perl API specific changes
    #

    #   DOMNodeList: automatically convert to perl list
    #      if called in a list context
    if (grep {/$CURR_CLASS/} @domnode_list_methods) {
      if (my ($sub) = /^sub\s+([\w_]+)/) {
	$sub = "$ {CURR_CLASS}::$sub";
	if (grep {/$sub$/} @domnode_list_methods) {
	  my $fix = <<'EOT';
    unless (defined $result) {
      return () if wantarray;
      return undef; # if *not* wantarray
    }
    return $result->to_list() if wantarray;
    $DOMNodeList::OWNER{$result} = 1; 
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

    #   DOMNamedNodeMap: automatically convert to perl hash
    #      if called in a list context
    if (grep {/$CURR_CLASS/} @domnode_map_methods) {
      if (my ($sub) = /^sub\s+([\w_]+)/) {
	$sub = "$ {CURR_CLASS}::$sub";
	if (grep {/$sub$/} @domnode_map_methods) {
	  my $fix = <<'EOT';
    unless (defined $result) {
      return () if wantarray;
      return undef; # if *not* wantarray
    }
    return $result->to_hash() if wantarray;
    $DOMNamedNodeMap::OWNER{$result} = 1;
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


    # handle SWIG bug
    if ($CURR_CLASS eq 'DOMNode') {
      if (/^\*([a-z]\w+)/) {
	print TEMP <<"EOT";
sub $1 {
    my \@args = \@_;
    if (\$args[0]->isa('XML::Xerces::DOMDocument')) {
      \$args[0] = \$args[0]->toDOMNode();
    }
    my \$result = XML::Xercesc::DOMNode_$1(\@args);
    return \$result unless UNIVERSAL::isa(\$result,'XML::Xerces');
    my \%resulthash;
    tie \%resulthash, ref(\$result), \$result;
    return bless \\\%resulthash, ref(\$result);
}
EOT
	next;
      }
      if (/^sub\s+[a-z]/) {
	my $fix = <<'EOT';
    if ($args[0]->isa('XML::Xerces::DOMDocument')) {
      $args[0] = $args[0]->toDOMNode();
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

    if ($CURR_CLASS eq 'DOMWriter') {
      if (/^\*writeNode/) {
	print TEMP <<'EOT';
sub writeNode {
    my @args = @_;
    if ($args[2]->isa('XML::Xerces::DOMDocument')) {
      $args[2] = $args[2]->toDOMNode();
    }
    my $result = XML::Xercesc::DOMWriter_writeNode(@args);
    return $result unless UNIVERSAL::isa($result,'XML::Xerces');
    my %resulthash;
    tie %resulthash, ref($result), $result;
    return bless \%resulthash, ref($result);
}
EOT
	next;
      }
      if (/^\*writeToString/) {
	print TEMP <<'EOT';
sub writeToString {
    my @args = @_;
    if ($args[1]->isa('XML::Xerces::DOMDocument')) {
      $args[1] = $args[1]->toDOMNode();
    }
    my $result = XML::Xercesc::DOMWriter_writeToString(@args);
    return $result unless UNIVERSAL::isa($result,'XML::Xerces');
    my %resulthash;
    tie %resulthash, ref($result), $result;
    return bless \%resulthash, ref($result);
}
EOT
	next;
      }
    }

    # we need to fix setAttribute() so that undefined values don't
    # cause a core dump
    if ($CURR_CLASS =~ /DOMElement/) {
      if (/XML::Xercesc::DOMElement_setAttribute;/) {
	print TEMP <<"EOT";
sub setAttribute {
    my (\$self,\$attr,\$val) = \@_;
    return unless defined \$attr and defined \$val;
    my \$result = XML::Xercesc::DOMElement_setAttribute(\@_);
    return \$result unless ref(\$result) =~ m[XML::Xerces];
    \$XML::Xerces::DOMAttr::OWNER{\$result} = 1; 
    my %resulthash;
    tie %resulthash, ref(\$result), \$result;
    return bless \\\%resulthash, ref(\$result);
}
EOT
        next;
      }
    }

    if ($CURR_CLASS =~ /DOMDOMException/) {
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

    if ($CURR_CLASS eq 'DOMDocumentTraversal') {
      if (/^sub\s+createTreeWalker/) {
	my $fix = <<'EOT';
    my ($self,$root,$what,$filter,$expand) = @_;
    my $callback = $XML::Xerces::DOMTreeWalker::OWNER{$self}->{__NODE_FILTER};
    if (defined $callback) {
      $callback->set_callback_obj($filter);
    } else {
      $callback = XML::Xerces::PerlNodeFilterCallbackHandler->new($filter);
      $XML::Xerces::DOMTreeWalker::OWNER{$self}->{__NODE_FILTER} = $callback;
    }
    my @args = ($self,$root,$what,$callback,$expand);
    if ($args[0]->isa('XML::Xerces::DOMDocument')) {
      $args[0] = $args[0]->toDOMDocumentTraversal();
    }
EOT
	fix_method(\*FILE,
		   \*TEMP,
		   qr/my \@args/,
		   $fix,
		   0);
	next;
      }
    }

    if ($CURR_CLASS eq 'DOMDocumentTraversal') {
      if (/^sub\s+createNodeIterator/) {
	my $fix = <<'EOT';
    my ($self,$root,$what,$filter,$expand) = @_;
    my $callback = $XML::Xerces::DOMNodeIterator::OWNER{$self}->{__NODE_FILTER};
    if (defined $callback) {
      $callback->set_callback_obj($filter);
    } else {
      $callback = XML::Xerces::PerlNodeFilterCallbackHandler->new($filter);
      $XML::Xerces::DOMNodeIterator::OWNER{$self}->{__NODE_FILTER} = $callback;
    }
    my @args = ($self,$root,$what,$callback,$expand);
    if ($args[0]->isa('XML::Xerces::DOMDocument')) {
      $args[0] = $args[0]->toDOMDocumentTraversal();
    }
EOT
	fix_method(\*FILE,
		   \*TEMP,
		   qr/my \@args/,
		   $fix,
		   0);
	next;
      }
    }

    if ($CURR_CLASS eq 'DOMWriter') {
      if (/^sub\s+createNodeIterator/) {
	my $fix = <<'EOT';
EOT
	fix_method(\*FILE,
		   \*TEMP,
		   qr/my \@args/,
		   $fix,
		   0);
	next;
      }
    }

    # fix the issue that deleting a parser deletes the document
    if (/\*XML::Xercesc::AbstractDOMParser_getDocument/) {
      print TEMP <<'EOT';
# hold a reference to the parser internally, so that the
# document can exist after the parser has gone out of scope
sub getDocument {
  my ($self) = @_;
  my $result = XML::Xercesc::AbstractDOMParser_getDocument($self);
  $XML::Xerces::DOMDocument::OWNER{$result}->{__PARSER} = $self;
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

