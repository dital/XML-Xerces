#ifndef __PERLCONTENTCALLBACKHANDLER
#define __PERLCONTENTCALLBACKHANDLER

#include "PerlCallbackHandler.hpp"
#include "xercesc/sax2/ContentHandler.hpp"
#include "xercesc/util/XMLString.hpp"

XERCES_CPP_NAMESPACE_USE

class PerlContentCallbackHandler  : public ContentHandler
				 , public PerlCallbackHandler 
{

protected:
//    SV *callbackObj;

public:

    PerlContentCallbackHandler();
    PerlContentCallbackHandler(SV *obj);
    ~PerlContentCallbackHandler();

    int type() {return PERLCALLBACKHANDLER_CONTENT_TYPE;}

	// The ContentHandler interface
    void startElement(const   XMLCh* const    uri,
		      const   XMLCh* const    localname,
		      const   XMLCh* const    qname,
		      const   Attributes&     attrs);
    void characters(const XMLCh* const chars, 
		    const unsigned int length);
    void ignorableWhitespace(const XMLCh* const chars, 
			     const unsigned int length);
    void endElement(const   XMLCh* const    uri,
		    const   XMLCh* const    localname,
		    const   XMLCh* const    qname);
    void resetDocument(void);
    void startDocument();
    void endDocument();
    void processingInstruction (const XMLCh* const target,
				const XMLCh* const data);
    void setDocumentLocator(const Locator* const locator);
    void startPrefixMapping (const XMLCh* const prefix,
			     const XMLCh* const uri);
    void endPrefixMapping (const XMLCh* const prefix);
    void skippedEntity (const XMLCh* const name);
};

#endif /* __PERLCONTENTCALLBACKHANDLER */
