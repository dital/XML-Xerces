#ifndef __PERLNODEFILTERCALLBACKHANDLER
#define __PERLNODEFILTERCALLBACKHANDLER

#include "PerlCallbackHandler.hpp"
#include "xercesc/dom/DOMNodeFilter.hpp"

XERCES_CPP_NAMESPACE_USE

class PerlNodeFilterCallbackHandler : public DOMNodeFilter
				    , public PerlCallbackHandler
{

protected:

public:

    PerlNodeFilterCallbackHandler();
    PerlNodeFilterCallbackHandler(SV *obj);
    ~PerlNodeFilterCallbackHandler();

    int type() {return PERLCALLBACKHANDLER_NODE_TYPE;}

	// The NodeFilter interface
    short acceptNode (const DOMNode* node) const;
};

#endif /* __PERLNODEFILTERCALLBACKHANDLER */
