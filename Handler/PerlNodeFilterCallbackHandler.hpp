#ifndef __PERLNODEFILTERCALLBACKHANDLER
#define __PERLNODEFILTERCALLBACKHANDLER

#include "PerlCallbackHandler.hpp"
#include "xercesc/dom/DOMNodeFilter.hpp"

XERCES_CPP_NAMESPACE_USE

class PerlNodeFilterCallbackHandler : public DOMNodeFilter
//				    , public  PerlCallbackHandler
{

protected:
    SV *callbackObj;

public:

    PerlNodeFilterCallbackHandler();
    PerlNodeFilterCallbackHandler(SV *obj);
    ~PerlNodeFilterCallbackHandler();

    SV* set_callback_obj(SV*);

	// The NodeFilter interface
    short acceptNode (const DOMNode* node) const;
};

#endif __PERLNODEFILTERCALLBACKHANDLER
