%module "XML::Xerces"
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
#include "xercesc/parsers/AbstractDOMParser.hpp"
#include "xercesc/parsers/XercesDOMParser.hpp"
#include "xercesc/parsers/SAXParser.hpp"
#include "xercesc/dom/DOM.hpp"
#include "xercesc/framework/LocalFileInputSource.hpp"
#include "xercesc/framework/MemBufInputSource.hpp"
#include "xercesc/framework/StdInInputSource.hpp"
#include "xercesc/framework/URLInputSource.hpp"
#include "xercesc/util/NameIdPool.hpp"
#include "xercesc/util/XMLEnumerator.hpp"
#include "xercesc/framework/XMLValidator.hpp"
#include "xercesc/validators/common/Grammar.hpp"
#include "xercesc/validators/DTD/DTDAttDef.hpp"
#include "xercesc/validators/DTD/DTDAttDefList.hpp"
#include "xercesc/validators/DTD/DTDGrammar.hpp"
#include "xercesc/validators/DTD/DTDValidator.hpp"
#include "xercesc/validators/schema/SchemaGrammar.hpp"
#include "xercesc/validators/schema/SchemaValidator.hpp"
#include "xercesc/validators/schema/SchemaAttDefList.hpp"
#include "xercesc/validators/schema/SchemaAttDef.hpp"
#include "xercesc/framework/XMLFormatter.hpp"
#include "xercesc/framework/MemBufFormatTarget.hpp"
#include "xercesc/framework/LocalFileFormatTarget.hpp"
#include "xercesc/framework/StdOutFormatTarget.hpp"

#include "PerlCallbackHandler.hpp"
#include "PerlErrorCallbackHandler.hpp"
#include "PerlDocumentCallbackHandler.hpp"
#include "PerlContentCallbackHandler.hpp"

#include "PerlEntityResolverHandler.i"
#include "PerlNodeFilterCallbackHandler.i"

XERCES_CPP_NAMESPACE_USE

// we initialize the static UTF-8 transcoding info
// these are used by the typemaps to convert between
// Xerces internal UTF-16 and Perl's internal UTF-8
static XMLCh* UTF8_ENCODING = NULL; 
static XMLTranscoder* UTF8_TRANSCODER  = NULL;

static XMLCh* ISO_8859_1_ENCODING = NULL; 
static XMLTranscoder* ISO_8859_1_TRANSCODER  = NULL;

static bool DEBUG_UTF8_OUT = 0;
static bool DEBUG_UTF8_IN = 0;

static char debug_char[2048];
static XMLCh debug_xml[2048];

char*
debugPrint(const XMLCh* str){
    return (char*)XMLString::transcode(str);
}

// These exception creation methods make the Xerces.C code *much* smaller
void
makeXMLException(const XMLException& e){
    SV *tmpsv;
    HV *hash = newHV();
    char *XML_EXCEPTION = "XML::Xerces::XMLException";
    HV *XML_EXCEPTION_STASH = gv_stashpv(XML_EXCEPTION, FALSE);
    hv_magic(hash, 
	     (GV *)sv_setref_pv(sv_newmortal(), 
				XML_EXCEPTION, (void *)&e), 
	     'P');
    tmpsv = sv_bless(newRV_noinc((SV *)hash), XML_EXCEPTION_STASH);
    SV *error = ERRSV;
    SvSetSV(error,tmpsv);
    (void)SvUPGRADE(error, SVt_PV);
    croak(Nullch);
}

void
makeDOMException(const DOMException& e){
    SV *tmpsv;
    HV *hash = newHV();
    char *DOM_EXCEPTION = "XML::Xerces::DOMException";
    HV *DOM_EXCEPTION_STASH = gv_stashpv(DOM_EXCEPTION, FALSE);
    hv_magic(hash, 
	     (GV *)sv_setref_pv(sv_newmortal(), 
				DOM_EXCEPTION, (void *)&e), 
	     'P');
    tmpsv = sv_bless(newRV_noinc((SV *)hash), DOM_EXCEPTION_STASH);
    SV *error = ERRSV;
    SvSetSV(error,tmpsv);
    (void)SvUPGRADE(error, SVt_PV);
    croak(Nullch);
}

void
makeSAXNotRecognizedException(const SAXNotRecognizedException& e){
    SV *tmpsv;
    HV *hash = newHV();
    char *SAX_NOT_RECOGNIZED_EXCEPTION = "XML::Xerces::SAXNotRecognizedException";
    HV *SAX_NOT_RECOGNIZED_EXCEPTION_STASH = gv_stashpv(SAX_NOT_RECOGNIZED_EXCEPTION, FALSE);
    hv_magic(hash, 
	     (GV *)sv_setref_pv(sv_newmortal(), 
				SAX_NOT_RECOGNIZED_EXCEPTION, (void *)&e), 
	     'P');
    tmpsv = sv_bless(newRV_noinc((SV *)hash), SAX_NOT_RECOGNIZED_EXCEPTION_STASH);
    SV *error = ERRSV;
    SvSetSV(error,tmpsv);
    (void)SvUPGRADE(error, SVt_PV);
    croak(Nullch);
}

void
makeSAXNotSupportedException(const SAXNotSupportedException& e){
    SV *tmpsv;
    HV *hash = newHV();
    char *SAX_NOT_SUPPORTED_EXCEPTION = "XML::Xerces::SAXNotSupportedException";
    HV *SAX_NOT_SUPPORTED_EXCEPTION_STASH = gv_stashpv(SAX_NOT_SUPPORTED_EXCEPTION, FALSE);
    hv_magic(hash, 
	     (GV *)sv_setref_pv(sv_newmortal(), 
				SAX_NOT_SUPPORTED_EXCEPTION, (void *)&e), 
	     'P');
    tmpsv = sv_bless(newRV_noinc((SV *)hash), SAX_NOT_SUPPORTED_EXCEPTION_STASH);
    SV *error = ERRSV;
    SvSetSV(error,tmpsv);
    (void)SvUPGRADE(error, SVt_PV);
    croak(Nullch);
}

%}

// These get wrapped by SWIG so that we can modify them within Perl
bool DEBUG_UTF8_OUT;
bool DEBUG_UTF8_IN;

/**************/
/*            */
/*  TYPEMAPS  */
/*            */
/**************/

%include typemaps.i

/*****************************/
/*                           */
/*  Platforms and Compilers  */
/*                           */
/*****************************/

#ifdef XML_LINUX
%import "xercesc/util/Platforms/Linux/LinuxDefs.hpp"
#endif

#ifdef XML_MACOSX
%import "xercesc/util/Platforms/MacOS/MacOSDefs.hpp"
#endif

#ifdef XML_GCC
%import "xercesc/util/Compilers/GCCDefs.hpp" 
#endif

%import "xercesc/util/XercesDefs.hpp"

/*
 * The generic exception handler
 */
%exception {
    try {
        $action
    } 
    catch (const XMLException& e)
        {
	    makeXMLException(e);
        }
    catch (...)
        {
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

/*
 * Utility Classes
 */

// both of these static variables cause trouble
// the transcoding service is only useful to C++ anyway.
%ignore XERCES_CPP_NAMESPACE::XMLPlatformUtils::fgTransService;
%ignore XERCES_CPP_NAMESPACE::XMLPlatformUtils::fgNetAccessor;

// these are other static variables that are useless to Perl
%ignore XERCES_CPP_NAMESPACE::XMLPlatformUtils::fgUserPanicHandler;
%ignore XERCES_CPP_NAMESPACE::XMLPlatformUtils::fgDefaultPanicHandler;
%ignore XERCES_CPP_NAMESPACE::XMLPlatformUtils::fgMemoryManager;

// here are some methods that cause trouble that are useless
%ignore XERCES_CPP_NAMESPACE::XMLPlatformUtils::isAnySlash;
%ignore openFile(const XMLCh* const);

%include "xercesc/util/PlatformUtils.hpp"
%ignore operator new;
%ignore operator delete;
%import "xercesc/util/XMemory.hpp"


// XERCES_CPP_NAMESPACE_BEGIN
// 
// class XMLTransService;
// class MemoryManager;
// 
// class XMLPlatformUtils {
//   void Initialize();
//   void Terminate();
//   static MemoryManager* fgMemoryManager;
//   static XMLTransService* fgTransService;
// };
// XERCES_CPP_NAMESPACE_END


%rename(XMLURL__constructor__base) XMLURL::XMLURL(const   XMLCh* const, 
						  const XMLCh* const);
/*

%rename(XMLURL__constructor__text) XMLURL::XMLURL(const XMLCh* const);
%rename(XMLURL__constructor__copy) XMLURL::XMLURL(const XMLURL&);
%rename(XMLURL__constructor__url_base) XMLURL::XMLURL(const XMLURL&,
						      const XMLCh* const);
%rename(makeRelativeTo__overload__XMLURL) XMLURL::makeRelativeTo(const XMLURL&);
%rename(setURL__overload__string) XMLURL::setURL(const XMLCh* const,
						 const XMLCh* const);
%rename(setURL__overload__XMLURL) XMLURL::setURL(const XMLURL&,
						 const XMLCh* const);
*/

%ignore XMLURL(const XMLURL&,const char* const);
%ignore XMLURL(const char* const);
%ignore XMLURL(const XMLCh* const, const char* const);
%include "xercesc/util/XMLURL.hpp"

// %rename(XMLUri__constructor__uri) XMLUri::XMLUri(const XMLCh* const);
%include "xercesc/util/XMLUri.hpp"

// I want to add these eventually, but for now, I want to eliminate
// the warnings

%ignore QName(const XMLCh *const,const XMLCh *const,const unsigned int);
%ignore QName(const XMLCh *const ,const unsigned int);
%ignore QName(const QName *const );
%ignore XERCES_CPP_NAMESPACE::QName::setName(const XMLCh *const,const unsigned int);

%ignore XERCES_CPP_NAMESPACE::Base64::decode(const XMLCh *const ,unsigned int *);

%ignore XERCES_CPP_NAMESPACE::XMLValidator::emitError(const XMLValid::Codes,const XMLCh *const,
				const XMLCh *const,const XMLCh *const,
				const XMLCh *const );

// These are just char* versions and should be ignored
%ignore XERCES_CPP_NAMESPACE::XMLValidator::emitError(const XMLValid::Codes, const char *const,
				const char *const, const char *const,
				const char *const );
%ignore XERCES_CPP_NAMESPACE::SAXException::SAXException(const char *const );
%ignore XERCES_CPP_NAMESPACE::SAXNotSupportedException::SAXNotSupportedException(const char *const);
%ignore XERCES_CPP_NAMESPACE::SAXNotRecognizedException::SAXNotRecognizedException(const char *const);
%ignore XERCES_CPP_NAMESPACE::DOMBuilder::parseURI(const char *const ,const bool );
%ignore XERCES_CPP_NAMESPACE::SAXParser::setExternalSchemaLocation(const char *const );
%ignore XERCES_CPP_NAMESPACE::SAXParser::setExternalNoNamespaceSchemaLocation(const char *const );


// %ignore SAXException::SAXException(const XMLCh *const );
// %ignore SAXException::SAXException(const SAXException &);
// %ignore SAXNotSupportedException::SAXNotSupportedException(const XMLCh *const);
// %ignore SAXNotSupportedException::SAXNotSupportedException(const SAXException&);
// %ignore SAXNotRecognizedException::SAXNotRecognizedException(const XMLCh *const);
// %ignore SAXNotRecognizedException::SAXNotRecognizedException(const SAXException&);
// 
// %ignore SAXParseException::SAXParseException(const XMLCh *const ,
// 					     const XMLCh *const ,
// 					     const XMLCh *const ,
// 					     XMLSSize_t const ,
// 					     XMLSSize_t const );
// %ignore SAXParseException::SAXParseException(const SAXParseException &);
// 
// %ignore DOMDocument::createElementNS(const XMLCh *,const XMLCh *,const int,
// 				     const int);
// 
// %ignore DOMException::DOMException(short ,const XMLCh *);
// %ignore DOMException::DOMException(const DOMException &);
// 
// %ignore DOMImplementation::createDocument();
// 
// %ignore DOMRangeException::DOMRangeException(RangeExceptionCode,
// 					       const XMLCh *);
// %ignore DOMRangeException::DOMRangeException(const DOMRangeException&);
// 
// %ignore XMLPScanToken::XMLPScanToken(const XMLPScanToken&);
// 
// %ignore SAX2XMLReader::parse(const XMLCh *const );
// 
// %ignore SAXParser::getDocumentHandler() const;
// %ignore SAXParser::getEntityResolver() const;
// %ignore SAXParser::getErrorHandler() const;
// 
// %ignore Grammar::getElemDecl(const unsigned int ) const;
// %ignore Grammar::putElemDecl(XMLElementDecl *const ) const;
// %ignore Grammar::getElemDecl(const unsigned int ,const XMLCh *const ,const XMLCh *const ,unsigned int );
// %ignore Grammar::getElemDecl(const unsigned int );
// %ignore Grammar::getNotationDecl(const XMLCh *const );
// 
// %ignore DOMDocument::createElementNS(const XMLCh *,const XMLCh *,
// 				     XMLSSize_t const ,XMLSSize_t const );
// %ignore DOMImplementation::createDocument();
// %ignore DOMRangeException::DOMRangeException(RangeExceptionCode ,
// 					     const XMLCh *);
// %ignore DOMRangeException::DOMRangeException(const DOMRangeException &);
// %ignore DOMBuilder::getErrorHandler() const;
// %ignore DOMBuilder::getErrorHandler();
// %ignore DOMBuilder::getEntityResolver();
// %ignore DOMBuilder::getFilter();


// These are just const versions of the others, and should be ignored
%ignore XERCES_CPP_NAMESPACE::QName::getPrefix() const;
%ignore XERCES_CPP_NAMESPACE::QName::getLocalPart() const;
%ignore XERCES_CPP_NAMESPACE::QName::getURI() const;
%ignore XERCES_CPP_NAMESPACE::QName::getRawName() const;
%include "xercesc/util/QName.hpp"

// although not really necessary for Perl, why not?
%include "xercesc/util/HexBin.hpp"
%include "xercesc/util/Base64.hpp"

// Perl has no need for these methods
// %include "xercesc/util/XMLStringTokenizer.hpp"

// this macro will get redefined and swig 1.3.8 thinks that's an error
#undef MakeXMLException
%include "xercesc/util/XMLExceptMsgs.hpp"
%include "xercesc/util/XMLException.hpp"

%ignore getNotationDecl(const XMLCh* const) const;
%ignore getEntityDecl(const XMLCh* const) const;
%ignore getEntityDeclPool() const;
%ignore getElemDecl(const unsigned int) const;
%ignore getElemDecl(const unsigned int,
		    const XMLCh* const,
		    const XMLCh* const,
		    unsigned int) const;



%ignore getContentSpec() const;
%ignore getAttDef(const XMLCh* const) const;
%ignore getBaseName() const;
%ignore getElementName() const;
%rename(ignore_me_for_now) XERCES_CPP_NAMESPACE::DTDEntityDecl(const XMLCh* const, 
							       const XMLCh, 
							       const bool,
							       const bool);
%ignore findAttDef(const unsigned long,
		   const XMLCh* const) const;
%ignore findAttDef(const XMLCh* const,
		   const XMLCh* const) const;
%rename(ignore_me_for_now) findAttDef(const unsigned long,
				      const XMLCh* const);
%ignore XERCES_CPP_NAMESPACE::SchemaElementDecl::getAttDef(const XMLCh* const, const int) const;
%ignore XERCES_CPP_NAMESPACE::SchemaElementDecl::getAttWildCard() const;

//
// For the schema enumeration support
//

// for now this have no methods we need, and are only imported
%import "xercesc/framework/XMLAttr.hpp"
%import "xercesc/framework/XMLContentModel.hpp"

// these have getter methods and must be included
%include "xercesc/framework/XMLElementDecl.hpp"
%include "xercesc/framework/XMLEntityDecl.hpp"
%include "xercesc/framework/XMLNotationDecl.hpp"
%include "xercesc/framework/XMLAttDefList.hpp"
%include "xercesc/framework/XMLAttDef.hpp"
%include "xercesc/framework/XMLValidator.hpp"
%include "xercesc/validators/common/Grammar.hpp"

// these are needed for both the DTD and Schema templates
%import "xercesc/util/XMLEnumerator.hpp"

// these are needed for the DTD templates
%import "xercesc/util/NameIdPool.hpp"

%include "xercesc/validators/DTD/DTDElementDecl.hpp"
%template()  XERCES_CPP_NAMESPACE::XMLEnumerator<DTDElementDecl>;
%template()  XERCES_CPP_NAMESPACE::NameIdPool<DTDElementDecl>;
%template(DTDElementDeclEnumerator)  XERCES_CPP_NAMESPACE::NameIdPoolEnumerator<DTDElementDecl>;

%include "xercesc/validators/DTD/DTDEntityDecl.hpp"
%template()  XERCES_CPP_NAMESPACE::XMLEnumerator<DTDEntityDecl>;
%template()  XERCES_CPP_NAMESPACE::NameIdPool<DTDEntityDecl>;
%template(DTDEntityDeclEnumerator)  XERCES_CPP_NAMESPACE::NameIdPoolEnumerator<DTDEntityDecl>;

%include "xercesc/validators/DTD/DTDAttDefList.hpp"
%include "xercesc/validators/DTD/DTDAttDef.hpp"
%include "xercesc/validators/DTD/DTDGrammar.hpp"
%include "xercesc/validators/DTD/DTDValidator.hpp"

// these are needed for the templates for schema
%import "xercesc/util/RefHash3KeysIdPool.hpp"

%include "xercesc/validators/schema/SchemaElementDecl.hpp"
%template()  XERCES_CPP_NAMESPACE::XMLEnumerator<SchemaElementDecl>;
%template()  XERCES_CPP_NAMESPACE::RefHash3KeysTableBucketElem<SchemaElementDecl>;
%template()  XERCES_CPP_NAMESPACE::RefHash3KeysIdPool<SchemaElementDecl>;
%template(SchemaElementDeclEnumerator)  XERCES_CPP_NAMESPACE::RefHash3KeysIdPoolEnumerator<SchemaElementDecl>;

%include "xercesc/validators/schema/SchemaGrammar.hpp"
%include "xercesc/validators/schema/SchemaValidator.hpp"
%include "xercesc/validators/schema/SchemaAttDefList.hpp"
%include "xercesc/validators/schema/SchemaAttDef.hpp"

// I will wait until someone asks for these scanner classes
// %include "xercesc/framework/XMLErrorCodes.hpp"
// %include "xercesc/framework/XMLValidityCodes.hpp"
// %include "xercesc/framework/XMLDocumentHandler.hpp"
// %import "xercesc/framework/XMLEntityHandler.hpp"

/* 
 * FOR SAX 1.0 API 
 */

%include "xercesc/sax/SAXException.hpp"
%include "xercesc/sax/SAXParseException.hpp"
%include "xercesc/sax/ErrorHandler.hpp"
%include "xercesc/sax/DTDHandler.hpp"
%include "xercesc/sax/DocumentHandler.hpp"
%include "xercesc/sax/EntityResolver.hpp"

%rename(getType__overload__name) XERCES_CPP_NAMESPACE::AttributeList::getType(const XMLCh* const) const;
%rename(getValue__overload__name) XERCES_CPP_NAMESPACE::AttributeList::getValue(const XMLCh* const) const;
//%ignore XERCES_CPP_NAMESPACE::AttributeList::getValue(const char* const) const;

%include "xercesc/sax/AttributeList.hpp"

%include "xercesc/sax/HandlerBase.hpp"
%include "xercesc/sax/Locator.hpp"

/* 
 * FOR SAX 2.0 API 
 */
%rename(getType__overload__name) XERCES_CPP_NAMESPACE::Attributes::getType(const XMLCh* const) const;
%rename(getValue__overload__name) XERCES_CPP_NAMESPACE::Attributes::getValue(const XMLCh* const) const;

%include "xercesc/sax2/Attributes.hpp"
%include "xercesc/sax2/ContentHandler.hpp"
%include "xercesc/sax2/LexicalHandler.hpp"
%include "xercesc/sax2/DeclHandler.hpp"
%include "xercesc/sax2/DefaultHandler.hpp"

/* 
 * INPUT SOURCES 
 *
 */
%include "xercesc/sax/InputSource.hpp"

%ignore MemBufInputSource(const XMLByte* const, const unsigned int, const char* const,
			  const bool, MemoryManager* const);
%include "xercesc/framework/MemBufInputSource.hpp"
%include "xercesc/framework/StdInInputSource.hpp"

// %rename(LocalFileInputSource__constructor__base) LocalFileInputSource(const XMLCh* const,const XMLCh* const);
%include "xercesc/framework/LocalFileInputSource.hpp"

// %rename(URLInputSource__constructor__pub) URLInputSource(const XMLCh* const,const XMLCh* const,const XMLCh* const);
// %rename(URLInputSource__constructor__sys) URLInputSource(const XMLCh* const,const XMLCh* const);
%ignore URLInputSource(const XMLCh* const,const char* const, const char* const);
%ignore URLInputSource(const XMLCh* const,const char* const);
%include "xercesc/framework/URLInputSource.hpp"

%ignore XMLFormatter::XMLFormatter(char const *const,XMLFormatTarget *const,
				   EscapeFlags const,UnRepFlags const);
%ignore operator <<;

//
// Format Targets for DOMWriter
//
%include "xercesc/framework/XMLFormatter.hpp"
%include "xercesc/framework/MemBufFormatTarget.hpp"
%include "xercesc/framework/LocalFileFormatTarget.hpp"
%include "xercesc/framework/StdOutFormatTarget.hpp"

// ensure that Perl treats these variables as constants
%immutable fgAnyString;
%immutable fgAttListString;
%immutable fgCommentString;
%immutable fgCDATAString;
%immutable fgDefaultString;
%immutable fgDocTypeString;
%immutable fgEBCDICEncodingString;
%immutable fgElemString;
%immutable fgEmptyString;
%immutable fgEncodingString;
%immutable fgEntitString;
%immutable fgEntityString;
%immutable fgEntitiesString;
%immutable fgEnumerationString;
%immutable fgExceptDomain;
%immutable fgFixedString;
%immutable fgIBM037EncodingString;
%immutable fgIBM037EncodingString2;
%immutable fgIBM1140EncodingString;
%immutable fgIBM1140EncodingString2;
%immutable fgIBM1140EncodingString3;
%immutable fgIBM1140EncodingString4;
%immutable fgIESString;
%immutable fgIDString;
%immutable fgIDRefString;
%immutable fgIDRefsString;
%immutable fgImpliedString;
%immutable fgIgnoreString;
%immutable fgIncludeString;
%immutable fgISO88591EncodingString;
%immutable fgISO88591EncodingString2;
%immutable fgISO88591EncodingString3;
%immutable fgISO88591EncodingString4;
%immutable fgISO88591EncodingString5;
%immutable fgISO88591EncodingString6;
%immutable fgISO88591EncodingString7;
%immutable fgISO88591EncodingString8;
%immutable fgISO88591EncodingString9;
%immutable fgISO88591EncodingString10;
%immutable fgISO88591EncodingString11;
%immutable fgISO88591EncodingString12;
%immutable fgLocalHostString;
%immutable fgNoString;
%immutable fgNotationString;
%immutable fgNDATAString;
%immutable fgNmTokenString;
%immutable fgNmTokensString;
%immutable fgPCDATAString;
%immutable fgPIString;
%immutable fgPubIDString;
%immutable fgRefString;
%immutable fgRequiredString;
%immutable fgStandaloneString;
%immutable fgVersion1_0;
%immutable fgVersion1_1;
%immutable fgSysIDString;
%immutable fgUnknownURIName;
%immutable fgUCS4EncodingString;
%immutable fgUCS4EncodingString2;
%immutable fgUCS4EncodingString3;
%immutable fgUCS4BEncodingString;
%immutable fgUCS4BEncodingString2;
%immutable fgUCS4LEncodingString;
%immutable fgUCS4LEncodingString2;
%immutable fgUSASCIIEncodingString;
%immutable fgUSASCIIEncodingString2;
%immutable fgUSASCIIEncodingString3;
%immutable fgUSASCIIEncodingString4;
%immutable fgUTF8EncodingString;
%immutable fgUTF8EncodingString2;
%immutable fgUTF16EncodingString;
%immutable fgUTF16EncodingString2;
%immutable fgUTF16EncodingString3;
%immutable fgUTF16EncodingString4;
%immutable fgUTF16EncodingString5;
%immutable fgUTF16BEncodingString;
%immutable fgUTF16BEncodingString2;
%immutable fgUTF16LEncodingString;
%immutable fgUTF16LEncodingString2;
%immutable fgVersionString;
%immutable fgValidityDomain;
%immutable fgWin1252EncodingString;
%immutable fgXMLChEncodingString;
%immutable fgXMLDOMMsgDomain;
%immutable fgXMLString;
%immutable fgXMLStringSpace;
%immutable fgXMLStringHTab;
%immutable fgXMLStringCR;
%immutable fgXMLStringLF;
%immutable fgXMLStringSpaceU;
%immutable fgXMLStringHTabU;
%immutable fgXMLStringCRU;
%immutable fgXMLStringLFU;
%immutable fgXMLDeclString;
%immutable fgXMLDeclStringSpace;
%immutable fgXMLDeclStringHTab;
%immutable fgXMLDeclStringLF;
%immutable fgXMLDeclStringCR;
%immutable fgXMLDeclStringSpaceU;
%immutable fgXMLDeclStringHTabU;
%immutable fgXMLDeclStringLFU;
%immutable fgXMLDeclStringCRU;
%immutable fgXMLNSString;
%immutable fgXMLNSColonString;
%immutable fgXMLNSURIName;
%immutable fgXMLErrDomain;
%immutable fgXMLURIName;
%immutable fgYesString;
%immutable fgZeroLenString;
%immutable fgDTDEntityString;
%immutable fgAmp;
%immutable fgLT;
%immutable fgGT;
%immutable fgQuot;
%immutable fgApos;
%immutable fgWFXMLScanner;
%immutable fgIGXMLScanner;
%immutable fgSGXMLScanner;
%immutable fgDGXMLScanner;
%immutable fgArrayIndexOutOfBoundsException_Name;
%immutable fgEmptyStackException_Name;
%immutable fgIllegalArgumentException_Name;
%immutable fgInvalidCastException_Name;
%immutable fgIOException_Name;
%immutable fgNoSuchElementException_Name;
%immutable fgNullPointerException_Name;
%immutable fgXMLPlatformUtilsException_Name;
%immutable fgRuntimeException_Name;
%immutable fgTranscodingException_Name;
%immutable fgUnexpectedEOFException_Name;
%immutable fgUnsupportedEncodingException_Name;
%immutable fgUTFDataFormatException_Name;
%immutable fgNetAccessorException_Name;
%immutable fgMalformedURLException_Name;
%immutable fgNumberFormatException_Name;
%immutable fgParseException_Name;
%immutable fgInvalidDatatypeFacetException_Name;
%immutable fgInvalidDatatypeValueException_Name;
%immutable fgSchemaDateTimeException_Name;
%immutable fgXPathException_Name;
%immutable fgNegINFString;
%immutable fgNegZeroString;
%immutable fgPosZeroString;
%immutable fgPosINFString;
%immutable fgNaNString;
%immutable fgEString;
%immutable fgZeroString;
%immutable fgNullString;
%immutable fgXercesDynamic;
%immutable fgXercesSchema;
%immutable fgXercesSchemaFullChecking;
%immutable fgXercesSchemaExternalSchemaLocation;
%immutable fgXercesSchemaExternalNoNameSpaceSchemaLocation;
%immutable fgXercesSecurityManager;
%immutable fgXercesLoadExternalDTD;
%immutable fgXercesContinueAfterFatalError;
%immutable fgXercesValidationErrorAsFatal;
%immutable fgXercesUserAdoptsDOMDocument;
%immutable fgXercesCacheGrammarFromParse;
%immutable fgXercesUseCachedGrammarInParse;
%immutable fgXercesScannerName;
%immutable fgXercesCalculateSrcOfs;
%immutable fgXercesStandardUriConformant;
%immutable fgSAX2CoreValidation;
%immutable fgSAX2CoreNameSpaces;
%immutable fgSAX2CoreNameSpacePrefixes;
%immutable fgDOMCanonicalForm;
%immutable fgDOMCDATASections;
%immutable fgDOMComments;
%immutable fgDOMCharsetOverridesXMLEncoding;
%immutable fgDOMDatatypeNormalization;
%immutable fgDOMEntities;
%immutable fgDOMInfoset;
%immutable fgDOMNamespaces;
%immutable fgDOMNamespaceDeclarations;
%immutable fgDOMSupportedMediatypesOnly;
%immutable fgDOMValidateIfSchema;
%immutable fgDOMValidation;
%immutable fgDOMWhitespaceInElementContent;
%immutable fgDOMWRTCanonicalForm;
%immutable fgDOMWRTDiscardDefaultContent;
%immutable fgDOMWRTEntities;
%immutable fgDOMWRTFormatPrettyPrint;
%immutable fgDOMWRTNormalizeCharacters;
%immutable fgDOMWRTSplitCdataSections;
%immutable fgDOMWRTValidation;
%immutable fgDOMWRTWhitespaceInElementContent;
%immutable fgDOMWRTBOM;
%immutable fgXercescDefaultLocale;


// Unicode string constants for XML Formatter
%include "xercesc/util/XMLUni.hpp"

//
// XMLScanner support
//

// ignore the constructors for now
%ignore XERCES_CPP_NAMESPACE::XMLScanner::XMLScanner;

// ignore all versions of the following for now
%ignore XERCES_CPP_NAMESPACE::XMLScanner::emitError;
%ignore XERCES_CPP_NAMESPACE::XMLScanner::getURIText;
%ignore XERCES_CPP_NAMESPACE::XMLScanner::scanDocument;
%ignore XERCES_CPP_NAMESPACE::XMLScanner::scanFirst;
%ignore XERCES_CPP_NAMESPACE::XMLScanner::setExternalNoNamespaceSchemaLocation;
%ignore XERCES_CPP_NAMESPACE::XMLScanner::setExternalSchemaLocation;

// ignore these specific ones for now
%ignore XERCES_CPP_NAMESPACE::XMLScanner::getDocHandler() const;
%ignore XERCES_CPP_NAMESPACE::XMLScanner::getDocHandler();
%ignore XERCES_CPP_NAMESPACE::XMLScanner::getDocTypeHandler() const;
%ignore XERCES_CPP_NAMESPACE::XMLScanner::getDocTypeHandler();
%ignore XERCES_CPP_NAMESPACE::XMLScanner::getDoNamespaces() const;
%ignore XERCES_CPP_NAMESPACE::XMLScanner::getValidationScheme() const;
%ignore XERCES_CPP_NAMESPACE::XMLScanner::getDoSchema() const;
%ignore XERCES_CPP_NAMESPACE::XMLScanner::getValidationSchemaFullChecking() const;
%ignore XERCES_CPP_NAMESPACE::XMLScanner::getEntityHandler() const;
%ignore XERCES_CPP_NAMESPACE::XMLScanner::getEntityHandler();
%ignore XERCES_CPP_NAMESPACE::XMLScanner::getErrorReporter() const;
%ignore XERCES_CPP_NAMESPACE::XMLScanner::getErrorReporter();
%ignore XERCES_CPP_NAMESPACE::XMLScanner::getErrorHandler() const;
%ignore XERCES_CPP_NAMESPACE::XMLScanner::getErrorHandler();
%ignore XERCES_CPP_NAMESPACE::XMLScanner::getExitOnFirstFatal() const;
%ignore XERCES_CPP_NAMESPACE::XMLScanner::getValidationConstraintFatal() const;
%ignore XERCES_CPP_NAMESPACE::XMLScanner::getIDRefList();
%ignore XERCES_CPP_NAMESPACE::XMLScanner::getIDRefList() const;
%ignore XERCES_CPP_NAMESPACE::XMLScanner::getInException() const;
%ignore XERCES_CPP_NAMESPACE::XMLScanner::getLastExtLocation    (XMLCh* const, const unsigned int,
					   XMLCh* const, const unsigned int,
					   unsigned int&, unsigned int&);
%ignore XERCES_CPP_NAMESPACE::XMLScanner::getLocator() const;
%ignore XERCES_CPP_NAMESPACE::XMLScanner::getStandalone() const;
%ignore XERCES_CPP_NAMESPACE::XMLScanner::getValidator() const;
%ignore XERCES_CPP_NAMESPACE::XMLScanner::getValidator();
%ignore XERCES_CPP_NAMESPACE::XMLScanner::getErrorCount();
%ignore XERCES_CPP_NAMESPACE::XMLScanner::getEntityDecl(const XMLCh* const) const;
%ignore XERCES_CPP_NAMESPACE::XMLScanner::getEntityEnumerator() const;
%ignore XERCES_CPP_NAMESPACE::XMLScanner::getEntityDeclPool();
%ignore XERCES_CPP_NAMESPACE::XMLScanner::getEntityDeclPool() const;
%ignore XERCES_CPP_NAMESPACE::XMLScanner::getURIStringPool() const;
%ignore XERCES_CPP_NAMESPACE::XMLScanner::getURIStringPool();
%ignore XERCES_CPP_NAMESPACE::XMLScanner::getHasNoDTD() const;
%ignore XERCES_CPP_NAMESPACE::XMLScanner::getExternalSchemaLocation() const;
%ignore XERCES_CPP_NAMESPACE::XMLScanner::getExternalNoNamespaceSchemaLocation() const;

%include "xercesc/internal/XMLScanner.hpp"

/* 
 * PARSERS (PRETTY IMPORTANT) 
 *
 */
// scan token helper class for progressive parsing
%include "xercesc/framework/XMLPScanToken.hpp"

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

// These are char* versions of XMLCh* methods, and should be ignored
%ignore XERCES_CPP_NAMESPACE::SAX2XMLReader::parse(const char *const );
%ignore XERCES_CPP_NAMESPACE::AbstractDOMParser::setExternalSchemaLocation(const char* const);
%ignore XERCES_CPP_NAMESPACE::AbstractDOMParser::setExternalNoNamespaceSchemaLocation(const char* const);
%ignore parse(const char* const, const bool);
%ignore parseFirst(const char *const,XMLPScanToken&,const bool);

// These are just const versions of the others, and should be ignored
%ignore XERCES_CPP_NAMESPACE::XercesDOMParser::getErrorHandler() const;
%ignore XERCES_CPP_NAMESPACE::XercesDOMParser::getEntityResolver() const;

// Overloaded methods

// %rename(parse__overload__is) parse(const InputSource&, const bool);
// %rename(parseFirst__overload__is) parseFirst(const InputSource&, 
// 					     XMLPScanToken &, const bool);

//
// The abstract base classes for Parsers
// 
%include "xercesc/sax/Parser.hpp"
%include "xercesc/framework/XMLDocumentHandler.hpp"
%include "xercesc/framework/XMLErrorReporter.hpp"
%include "xercesc/framework/XMLEntityHandler.hpp"
%include "xercesc/validators/DTD/DocTypeHandler.hpp"

//
// define the exceptions for SAX2XMLReader
//
%define SAXEXCEPTION(method)
%exception method {
    try {
        $action
    } 
    catch (const XMLException& e)
        {
	    makeXMLException(e);
        }
    catch (const SAXNotSupportedException& e)
	{
	    makeSAXNotSupportedException(e);
	}
    catch (const SAXNotRecognizedException& e)
	{
	    makeSAXNotRecognizedException(e);
	}
    catch (...)
        {
            croak("%s", "Handling Unknown exception");
        }
}
%enddef

SAXEXCEPTION(XERCES_CPP_NAMESPACE::SAX2XMLReader::getFeature)
SAXEXCEPTION(XERCES_CPP_NAMESPACE::SAX2XMLReader::setFeature)
SAXEXCEPTION(XERCES_CPP_NAMESPACE::SAX2XMLReader::setProperty)
SAXEXCEPTION(XERCES_CPP_NAMESPACE::SAX2XMLReader::getProperty)

//
// The Parsers classes
// 

// the overloaded factory method is useless for perl
%ignore createXMLReader(const XMLCh*);
%include "xercesc/sax2/SAX2XMLReader.hpp"
%include "xercesc/sax2/XMLReaderFactory.hpp"

%ignore XERCES_CPP_NAMESPACE::SAXParser::getErrorHandler() const;
%ignore XERCES_CPP_NAMESPACE::SAXParser::getEntityResolver() const;
%ignore XERCES_CPP_NAMESPACE::SAXParser::getDocumentHandler() const;
%include "xercesc/parsers/SAXParser.hpp"

/* 
 * DOM
 */

// the DOM classes gets a special exception handler
%exception {
    try {
        $action
    } 
    catch (const XMLException& e)
        {
	    makeXMLException(e);
        }
    catch (const DOMException& e)
	{
	    makeDOMException(e);
	}
    catch (...)
        {
            croak("%s", "Handling Unknown exception");
        }
}

// Introduced in DOM Level 1
%include "xercesc/dom/DOMException.hpp"

// Introduced in DOM Level 2
%include "xercesc/dom/DOMDocumentRange.hpp"
%include "xercesc/dom/DOMDocumentTraversal.hpp"
%include "xercesc/dom/DOMNodeFilter.hpp"
%include "xercesc/dom/DOMNodeIterator.hpp"
%include "xercesc/dom/DOMRange.hpp"
%include "xercesc/dom/DOMRangeException.hpp"
%include "xercesc/dom/DOMTreeWalker.hpp"

%ignore XERCES_CPP_NAMESPACE::DOMImplementation::loadDOMExceptionMsg;

// Introduced in DOM Level 1
%include "xercesc/dom/DOMNode.hpp"
%include "xercesc/dom/DOMAttr.hpp"
%include "xercesc/dom/DOMCharacterData.hpp"
%include "xercesc/dom/DOMText.hpp"
%include "xercesc/dom/DOMCDATASection.hpp"
%include "xercesc/dom/DOMComment.hpp"
%include "xercesc/dom/DOMDocument.hpp"
%include "xercesc/dom/DOMDocumentFragment.hpp"
%include "xercesc/dom/DOMDocumentType.hpp"
%include "xercesc/dom/DOMImplementationLS.hpp"
%include "xercesc/dom/DOMImplementation.hpp"
%include "xercesc/dom/DOMElement.hpp"
%include "xercesc/dom/DOMEntity.hpp"
%include "xercesc/dom/DOMEntityReference.hpp"
%include "xercesc/dom/DOMNamedNodeMap.hpp"
%include "xercesc/dom/DOMNodeList.hpp"
%include "xercesc/dom/DOMNotation.hpp"
%include "xercesc/dom/DOMProcessingInstruction.hpp"

%ignore XERCES_CPP_NAMESPACE::DOMBuilder::getErrorHandler() const;
%ignore XERCES_CPP_NAMESPACE::DOMBuilder::getEntityResolver() const;
%ignore XERCES_CPP_NAMESPACE::DOMBuilder::getFilter() const;

// Introduced in DOM Level 3
// Experimental - subject to change
%include "xercesc/dom/DOMBuilder.hpp"
%include "xercesc/dom/DOMImplementationLS.hpp"
%include "xercesc/dom/DOMImplementationRegistry.hpp"
%include "xercesc/dom/DOMImplementationSource.hpp"
%include "xercesc/dom/DOMInputSource.hpp"
%include "xercesc/dom/DOMLocator.hpp"
%include "xercesc/dom/DOMWriter.hpp"
%include "xercesc/dom/DOMWriterFilter.hpp"

%include "xercesc/parsers/AbstractDOMParser.hpp"
%include "xercesc/parsers/XercesDOMParser.hpp"

%extend XERCES_CPP_NAMESPACE::DOMDocument {
   DOMNode * toDOMNode() {
     return (DOMNode*) self;
   }
   DOMDocumentTraversal * toDOMDocumentTraversal() {
     return (DOMDocumentTraversal*) self;
   }
};

%extend XERCES_CPP_NAMESPACE::DOMNode {
   bool operator==(const DOMNode *other) {
       return self->isSameNode(other);
   }
   bool operator!=(const DOMNode *other) {
       return !self->isSameNode(other);
   }
};

/* 
 * FOR ERROR HANDLING and other callbacks - this needs to be at the very end
 *   so that SWIG can wrap the superclass methods properly
 */

// %rename(PerlErrorCallbackHandler__constructor__arg) PerlErrorCallbackHandler::PerlErrorCallbackHandler(SV*);
// %rename(PerlNodeFilterCallbackHandler__constructor__arg) PerlNodeFilterCallbackHandler::PerlNodeFilterCallbackHandler(SV*);
// %rename(PerlContentCallbackHandler__constructor__arg) PerlContentCallbackHandler::PerlContentCallbackHandler(SV*);
// %rename(PerlDocumentCallbackHandler__constructor__arg) PerlDocumentCallbackHandler::PerlDocumentCallbackHandler(SV*);
// %rename(PerlEntityResolverHandler__constructor__arg) PerlEntityResolverHandler::PerlEntityResolverHandler(SV*);

%ignore PerlErrorCallbackHandler::warning(const SAXParseException&);
%ignore PerlErrorCallbackHandler::error(const SAXParseException&);
%ignore PerlErrorCallbackHandler::fatalError(const SAXParseException&);

%include "PerlCallbackHandler.hpp"
%include "PerlErrorCallbackHandler.hpp"
%include "PerlDocumentCallbackHandler.hpp"
%include "PerlContentCallbackHandler.hpp"

%ignore PerlEntityResolverHandler::resolveEntity (const XMLCh* const, 
						 const XMLCh* const);
%include "PerlEntityResolverHandler.hpp"

%ignore PerlNodeFilterCallbackHandler::acceptNode (const DOMNode*) const;
%include "PerlNodeFilterCallbackHandler.hpp"

/* 
 * Include extra verbatim C code in the initialization function
 */
%init {
    // we create the global transcoder for UTF-8 to UTF-16
    XMLTransService::Codes failReason;
    XMLPlatformUtils::Initialize(); // first we must create the transservice
    UTF8_ENCODING = XMLString::transcode("UTF-8");
    UTF8_TRANSCODER =
      XMLPlatformUtils::fgTransService->makeNewTranscoderFor(UTF8_ENCODING,
                                                             failReason,
                                                             1024,
							     XMLPlatformUtils::fgMemoryManager);
    if (! UTF8_TRANSCODER) {
	croak("ERROR: XML::Xerces: INIT: Could not create UTF-8 transcoder");
    }


    ISO_8859_1_ENCODING = XMLString::transcode("ISO-8859-1");
    ISO_8859_1_TRANSCODER =
      XMLPlatformUtils::fgTransService->makeNewTranscoderFor(ISO_8859_1_ENCODING,
                                                             failReason,
                                                             1024,
							     XMLPlatformUtils::fgMemoryManager);
    if (! ISO_8859_1_TRANSCODER) {
	croak("ERROR: XML::Xerces: INIT: Could not create ISO-8859-1 transcoder");
    }

}

/* 
 * Include extra verbatim Perl code
 */
%pragma(perl5) include="Xerces-extra.pm"

/* 
 * Include extra verbatim Perl code immediately after Module header
 */
%pragma(perl5) code="package XML::Xerces; 
use vars qw($VERSION @EXPORT);"
