#ifndef __PERLDOCUMENTCALLBACKHANDLER
#define __PERLDOCUMENTCALLBACKHANDLER

#include "PerlCallbackHandler.hpp"
#include "xercesc/sax/DocumentHandler.hpp"
#include "xercesc/util/XMLString.hpp"
class PerlDocumentCallbackHandler : public DocumentHandler
				  , public  PerlCallbackHandler 
{

protected:
//    SV *callbackObj;

public:

    PerlDocumentCallbackHandler() {};
    PerlDocumentCallbackHandler(SV *obj) : PerlCallbackHandler(obj){};
    ~PerlDocumentCallbackHandler() {};

    SV* set_callback_obj(SV*);

	// The DocumentHandler interface
    void startElement(const XMLCh* const name, 
		      AttributeList& attributes);
    void characters(const XMLCh* const chars, 
		       const unsigned int length);
    void ignorableWhitespace(const XMLCh* const chars, 
				const unsigned int length);
    void endElement(const XMLCh* const name);
    void resetDocument(void);
    void startDocument();
    void endDocument();
    void processingInstruction (const XMLCh* const target,
				const XMLCh* const data);
    void setDocumentLocator(const Locator* const locator);

};

#endif /*  __PERLDOCUMENTCALLBACKHANDLER */
