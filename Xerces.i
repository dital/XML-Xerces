%module Xerces
%{
#include "stdio.h"
#include "string.h"
#include "xercesc/sax/InputSource.hpp"
#include "xercesc/sax/SAXException.hpp"
#include "xercesc/sax/SAXParseException.hpp"
#include "xercesc/sax/Locator.hpp"
#include "xercesc/sax/HandlerBase.hpp"
#include "xercesc/sax2/Attributes.hpp"
#include "xercesc/sax2/ContentHandler.hpp"
#include "xercesc/sax2/LexicalHandler.hpp"
#include "xercesc/sax2/DefaultHandler.hpp"
#include "xercesc/sax2/SAX2XMLReader.hpp"
#include "xercesc/sax2/XMLReaderFactory.hpp"
#include "xercesc/util/PlatformUtils.hpp"
#include "xercesc/util/TransService.hpp"
#include "xercesc/util/XMLString.hpp"
#include "xercesc/util/XMLUri.hpp"
#include "xercesc/util/QName.hpp"
#include "xercesc/util/HexBin.hpp"
#include "xercesc/util/Base64.hpp"
#include "xercesc/parsers/IDOMParser.hpp"
#include "xercesc/parsers/SAXParser.hpp"
#include "xercesc/idom/IDOM.hpp"
#include "xercesc/framework/LocalFileInputSource.hpp"
#include "xercesc/framework/MemBufInputSource.hpp"
#include "xercesc/framework/StdInInputSource.hpp"
#include "xercesc/framework/URLInputSource.hpp"
#include "xercesc/framework/XMLValidator.hpp"
#include "xercesc/validators/common/Grammar.hpp"

#include "PerlErrorCallbackHandler.hpp"
#include "PerlEntityResolverHandler.i"
#include "PerlDocumentCallbackHandler.hpp"
#include "PerlContentCallbackHandler.hpp"

// we initialize the static UTF-8 transcoding info
// these are used by the typemaps to convert between
// Xerces internal UTF-16 and Perl's internal UTF-8
static XMLCh* UTF8_ENCODING = NULL; 
static XMLTranscoder* UTF8_TRANSCODER  = NULL;

static XMLCh* ISO_8859_1_ENCODING = NULL; 
static XMLTranscoder* ISO_8859_1_TRANSCODER  = NULL;

static bool DEBUG_UTF8_OUT = 0;
static bool DEBUG_UTF8_IN = 0;
%}

bool DEBUG_UTF8_OUT;
bool DEBUG_UTF8_IN;

/**************/
/*            */
/*  TYPEMAPS  */
/*            */
/**************/

%include typemaps.i

/*******************/
/*                 */
/*  INCLUDE FILES  */
/*                 */
/*******************/

%pragma nodefault

// We have to define these in order to get past the occurrence of the
// macro in class declaration line
#define SAX_EXPORT
#define PLATFORM_EXPORT
#define PLATFORM_IMPORT
#define PARSERS_EXPORT
#define CDOM_EXPORT
#define SAX2_EXPORT
#define XMLUTIL_EXPORT
#define PARSERS_EXPORT
#define XMLPARSER_EXPORT
#define VALIDATORS_EXPORT

%{
static char *XML_EXCEPTION = "XML::Xerces::XMLException";
static HV *XML_EXCEPTION_STASH = NULL;

static char *IDOM_EXCEPTION = "XML::Xerces::DOM_DOMException";
static HV *IDOM_EXCEPTION_STASH = NULL;

void
makeXMLException(const XMLException& e){
    SV *tmpsv;
    HV *hash = newHV();
    hv_magic(hash, 
	     (GV *)sv_setref_pv(sv_newmortal(), 
				XML_EXCEPTION, (void *)&e), 
	     'P');
    tmpsv = sv_bless(newRV_noinc((SV *)hash), XML_EXCEPTION_STASH);
    SV *error = ERRSV;
    SvSetSV(error,tmpsv);
    (void)SvUPGRADE(error, SVt_PV);
    Perl_die(Nullch);
}

void
makeIDOMException(const IDOM_DOMException& e){
    SV *tmpsv;
    HV *hash = newHV();
    hv_magic(hash, 
	     (GV *)sv_setref_pv(sv_newmortal(), 
				IDOM_EXCEPTION, (void *)&e), 
	     'P');
    tmpsv = sv_bless(newRV_noinc((SV *)hash), IDOM_EXCEPTION_STASH);
    SV *error = ERRSV;
    SvSetSV(error,tmpsv);
    (void)SvUPGRADE(error, SVt_PV);
    Perl_die(Nullch);
}

%}

/*
 * The generic exception handler
 */
%except(perl5) {
    try {
        $function
    } 
    catch (const XMLException& e)
        {
	    makeXMLException(e);
        }
    catch (...)
        {
            XMLPlatformUtils::Terminate();
            croak("%s", "Handling Unknown exception");
        }
}

// we remove this macro for PlatformUtils and XMLURL
#define MakeXMLException(theType, expKeyword)

/* 
 * NEEDED FOR INITIALIZATION AND TERMINATION 
 */
%rename(operator_assignment) operator=;
%rename(operator_equal_to) operator==;
%rename(operator_not_equal_to) operator!=;

// both of these static variables cause trouble
// the transcoding service is only useful to C++ anyway.
%ignore XMLPlatformUtils::fgTransService;
%ignore XMLPlatformUtils::fgNetAccessor;

%ignore openFile(const XMLCh* const);
%include "xercesc/util/PlatformUtils.hpp"

/*
 * Utility Classes
 */
%rename(XMLURL__constructor__base) XMLURL::XMLURL(const   XMLCh* const, const XMLCh* const);
%rename(XMLURL__constructor__text) XMLURL::XMLURL(const XMLCh* const);
%rename(XMLURL__constructor__copy) XMLURL::XMLURL(const XMLURL&);
%rename(XMLURL__constructor__url_base) XMLURL::XMLURL(const XMLURL&,const XMLCh* const);
%rename(makeRelativeTo__overload__XMLURL) XMLURL::makeRelativeTo(const XMLURL&);
%rename(setURL__overload__string) XMLURL::setURL(const XMLCh* const,const XMLCh* const);
%rename(setURL__overload__XMLURL) XMLURL::setURL(const XMLURL&,const XMLCh* const);
%ignore XMLURL::XMLURL(const XMLURL&,const char* const);
%ignore XMLURL::XMLURL(const char* const);
%ignore XMLURL::XMLURL(const XMLCh* const, const char* const);
%include "xercesc/util/XMLURL.hpp"

%rename(XMLUri__constructor__uri) XMLUri::XMLUri(const XMLCh* const);
%include "xercesc/util/XMLUri.hpp"
%ignore getPrefix() const;
%ignore getLocalPart() const;
%ignore getURI() const;
%ignore getRawName() const;
%include "xercesc/util/QName.hpp"

// although not really necessary for Perl, why not?
%include "xercesc/util/HexBin.hpp"
%include "xercesc/util/Base64.hpp"

// do we need these Unicode string constants?
// %include "xercesc/util/XMLUni.hpp"

// does anyone want to use this class for formatting Unicode?
// %include "xercesc/framework/XMLFormatter.hpp"


// Perl has no need for these methods
// %include "xercesc/util/XMLStringTokenizer.hpp"

// this macro will get redefined and swig 1.3.8 thinks that's an error
#undef MakeXMLException
%include "xercesc/util/XMLExceptMsgs.hpp"
%include "xercesc/util/XMLException.hpp"

// in case someone wants to re-use validators
%include "xercesc/framework/XMLValidator.hpp"

// I will wait until someone asks for these scanner classes
// %include "xercesc/framework/XMLAttDef.hpp"
// %include "xercesc/framework/XMLAttDefList.hpp"
// %include "xercesc/framework/XMLAttr.hpp"
// %include "xercesc/framework/XMLContentModel.hpp"
// %include "xercesc/framework/XMLElementDecl.hpp"
// %include "xercesc/framework/XMLEntityDecl.hpp"
// %include "xercesc/framework/XMLNotationDecl.hpp"
// %include "xercesc/framework/XMLEntityHandler.hpp"
// %include "xercesc/framework/XMLErrorCodes.hpp"
// %include "xercesc/framework/XMLValidityCodes.hpp"
// %include "xercesc/framework/XMLDocumentHandler.hpp"

/* 
 * FOR SAX 1.0 API 
 */
%include "xercesc/sax/SAXException.hpp"
%include "xercesc/sax/SAXParseException.hpp"
%include "xercesc/sax/ErrorHandler.hpp"
%include "xercesc/sax/DTDHandler.hpp"
%include "xercesc/sax/DocumentHandler.hpp"
%include "xercesc/sax/EntityResolver.hpp"
%rename(getType__overload__index) AttributeList::getType(const unsigned int) const;
%ignore AttributeList::getValue(const XMLCh* const) const;
%rename(getValue__overload__index) AttributeList::getValue(const unsigned int) const;
%include "xercesc/sax/AttributeList.hpp"
%include "xercesc/sax/HandlerBase.hpp"
%include "xercesc/sax/Locator.hpp"

/* 
 * FOR SAX 2.0 API 
 */
%rename(getType__overload__qname) Attributes::getType(const XMLCh* const) const;
%rename(getType__overload__index) Attributes::getType(const unsigned int) const;
%rename(getValue__overload__qname) Attributes::getValue(const XMLCh* const) const;
%rename(getValue__overload__index) Attributes::getValue(const unsigned int) const;
%rename(getIndex__overload__qname) Attributes::getIndex(const XMLCh* const) const;
%include "xercesc/sax2/Attributes.hpp"
%include "xercesc/sax2/ContentHandler.hpp"
%include "xercesc/sax2/LexicalHandler.hpp"
%include "xercesc/sax2/DefaultHandler.hpp"
// the overloaded factory method is useless for perl
%ignore createXMLReader(const XMLCh*);
%include "xercesc/sax2/XMLReaderFactory.hpp"

/* 
 * FOR ERROR HANDLING and other callbacks  
 */
%include "PerlErrorCallbackHandler.swig.hpp"
%include "PerlDocumentCallbackHandler.swig.hpp"
%include "PerlContentCallbackHandler.swig.hpp"
%include "PerlEntityResolverHandler.swig.hpp" 

/* 
 * THE NEW DOM IMPLEMENATION 
 */

// the IDOM classes gets a special exception handler
%except(perl5) {
    try {
        $function
    } 
    catch (const XMLException& e)
        {
	    makeXMLException(e);
        }
    catch (const IDOM_DOMException& e)
	{
	    makeIDOMException(e);
	}
    catch (...)
        {
            XMLPlatformUtils::Terminate();
            croak("%s", "Handling Unknown exception");
        }
}

%rename(DOM_Node) IDOM_Node;
%rename(DOM_Attr) IDOM_Attr;
%rename(DOM_CharacterData) IDOM_CharacterData;
%rename(DOM_Text) IDOM_Text;
%rename(DOM_CDATASection) IDOM_CDATASection;
%rename(DOM_Comment) IDOM_Comment;
%rename(DOM_Document) IDOM_Document;
%rename(DOM_DocumentFragment) IDOM_DocumentFragment;
%rename(DOM_DocumentType) IDOM_DocumentType;
%rename(DOM_DOMException) IDOM_DOMException;
%rename(DOM_DOMImplementation) IDOM_DOMImplementation;
%rename(DOM_Element) IDOM_Element;
%rename(DOM_Entity) IDOM_Entity;
%rename(DOM_EntityReference) IDOM_EntityReference;
%rename(DOM_NamedNodeMap) IDOM_NamedNodeMap;
%rename(DOM_NodeFilter) IDOM_NodeFilter;
%rename(DOM_NodeIterator) IDOM_NodeIterator;
%rename(DOM_NodeList) IDOM_NodeList;
%rename(DOM_Notation) IDOM_Notation;
%rename(DOM_ProcessingInstruction) IDOM_ProcessingInstruction;
%rename(DOM_Range) IDOM_Range;
%rename(DOM_RangeException) IDOM_RangeException;
%rename(DOM_TreeWalker) IDOM_TreeWalker;

%include "xercesc/idom/IDOM_Node.hpp"
%include "xercesc/idom/IDOM_Attr.hpp"
%include "xercesc/idom/IDOM_CharacterData.hpp"
%include "xercesc/idom/IDOM_Text.hpp"
%include "xercesc/idom/IDOM_CDATASection.hpp"
%include "xercesc/idom/IDOM_Comment.hpp"
%include "xercesc/idom/IDOM_Document.hpp"
%include "xercesc/idom/IDOM_DocumentFragment.hpp"
%include "xercesc/idom/IDOM_DocumentType.hpp"
%include "xercesc/idom/IDOM_DOMException.hpp"
%include "xercesc/idom/IDOM_DOMImplementation.hpp"
%include "xercesc/idom/IDOM_Element.hpp"
%include "xercesc/idom/IDOM_Entity.hpp"
%include "xercesc/idom/IDOM_EntityReference.hpp"
%include "xercesc/idom/IDOM_NamedNodeMap.hpp"
%include "xercesc/idom/IDOM_NodeFilter.hpp"
%include "xercesc/idom/IDOM_NodeIterator.hpp"
%include "xercesc/idom/IDOM_NodeList.hpp"
%include "xercesc/idom/IDOM_Notation.hpp"
%include "xercesc/idom/IDOM_ProcessingInstruction.hpp"
%include "xercesc/idom/IDOM_Range.hpp"
%include "xercesc/idom/IDOM_RangeException.hpp"
%include "xercesc/idom/IDOM_TreeWalker.hpp"

/* 
 * INPUT SOURCES 
 *
 */
// we return to our previously scheduled handler
%except(perl5) {
    try {
        $function
    } 
    catch (const XMLException& e)
        {
	    makeXMLException(e);
        }
    catch (...)
        {
            XMLPlatformUtils::Terminate();
            croak("%s", "Handling Unknown exception");
        }
}
%include "xercesc/sax/InputSource.hpp"

%ignore MemBufInputSource(const XMLByte* const, const unsigned int, const XMLCh* const,const bool);
%include "xercesc/framework/MemBufInputSource.hpp"
%include "xercesc/framework/StdInInputSource.hpp"

%rename(LocalFileInputSource__constructor__base) LocalFileInputSource(const XMLCh* const,const XMLCh* const);
%include "xercesc/framework/LocalFileInputSource.hpp"

%rename(URLInputSource__constructor__pub) URLInputSource(const XMLCh* const,const char* const,const char* const);
%rename(URLInputSource__constructor__sys) URLInputSource(const XMLCh* const,const char* const);
%ignore URLInputSource(const XMLCh* const,const XMLCh* const, const XMLCh* const);
%ignore URLInputSource(const XMLCh* const,const XMLCh* const);
%include "xercesc/framework/URLInputSource.hpp"

/* 
 * PARSERS (PRETTY IMPORTANT) 
 *
 */
// scan token helper class for progressive parsing
// has assignment operator and needs private header
%include "xercesc/framework/XMLPScanToken.hpp"

// Overloaded methods
%rename(parse__overload__is) parse(const InputSource&, const bool);
%ignore parse(const XMLCh* const,const bool);
%rename(parseFirst__overload__is) parseFirst(const InputSource&, XMLPScanToken &, const bool);
%ignore parseFirst(const XMLCh *const ,XMLPScanToken &,const bool );

/*
 * methods not needed by the public Parser interfaces
 *
 *   this is probably because I'm not using AdvDocHandlers and things
 *   that want to control the parsing process, but until someone asks
 *   for them, I'm going to leave them out.
 */

// XMLEntityHandler interface
%ignore endInputSource;
%ignore expandSystemId;
%ignore resetEntities;
%ignore resolveEntity;
%ignore startInputSource;

// XMLDocumentHandler interface.
%ignore docCharacters;
%ignore docComment;
%ignore docPI;
%ignore endDocument;
%ignore endElement;
%ignore endEntityReference;
%ignore ignorableWhitespace;
%ignore resetDocument;
%ignore startDocument;
%ignore startElement;
%ignore startEntityReference;
%ignore XMLDecl;

// depricated methods - don't ask me to include these
%ignore getDoValidation;
%ignore setDoValidation;
%ignore attDef;
%ignore doctypeComment;
%ignore doctypeDecl;
%ignore doctypePI;
%ignore doctypeWhitespace;
%ignore elementDecl;
%ignore endAttList;
%ignore endIntSubset;
%ignore endExtSubset;
%ignore entityDecl;
%ignore resetDocType;
%ignore notationDecl;
%ignore startAttList;
%ignore startIntSubset;
%ignore startExtSubset;
%ignore TextDecl;

// %include "xercesc/sax/Parser.hpp"
%include "xercesc/sax2/SAX2XMLReader.hpp"
%include "xercesc/parsers/SAXParser.hpp"

%rename(DOMParser) IDOMParser;
%include "xercesc/parsers/IDOMParser.hpp"

%include "xercesc/validators/common/Grammar.hpp"

/* %pragma(perl5) include="Xerces-extra.pm" */
%pragma(perl5) code="package XML::Xerces; 
$VERSION = q[1.7.0_0];";
