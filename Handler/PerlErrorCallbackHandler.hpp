#ifndef __PERLERRORCALLBACKHANDLER
#define __PERLERRORCALLBACKHANDLER

#include "PerlCallbackHandler.hpp"
#include "xercesc/sax/ErrorHandler.hpp"
class PerlErrorCallbackHandler : public ErrorHandler
			       , public PerlCallbackHandler 
{

protected:
//    SV *callbackObj;

public:

    PerlErrorCallbackHandler() {};
    PerlErrorCallbackHandler(SV *obj) : PerlCallbackHandler(obj) {};
    ~PerlErrorCallbackHandler() {};

    SV* set_callback_obj(SV*);

	// the ErrorHandler interface
    void warning(const SAXParseException& exception);
    void error(const SAXParseException& exception);
    void fatalError(const SAXParseException& exception);
    void resetErrors(void);
};

#endif /* __PERLERRORCALLBACKHANDLER */
