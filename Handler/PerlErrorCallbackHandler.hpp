#ifndef __PERLERRORCALLBACKHANDLER
#define __PERLERRORCALLBACKHANDLER

#include "PerlCallbackHandler.hpp"
#include "xercesc/sax/ErrorHandler.hpp"

XERCES_CPP_NAMESPACE_USE

class PerlErrorCallbackHandler : public ErrorHandler
			       , public PerlCallbackHandler 
{

protected:

public:

    PerlErrorCallbackHandler();
    PerlErrorCallbackHandler(SV *obj);
    ~PerlErrorCallbackHandler();

    int type() {return PERLCALLBACKHANDLER_ERROR_TYPE;}

	// the ErrorHandler interface
    void warning(const SAXParseException& exception);
    void error(const SAXParseException& exception);
    void fatalError(const SAXParseException& exception);
    void resetErrors();
};

#endif /* __PERLERRORCALLBACKHANDLER */
