#ifndef __PERLNODEFILTERCALLBACKHANDLER
#define __PERLNODEFILTERCALLBACKHANDLER

#include "PerlCallbackHandler.hpp"
#include "xercesc/idom/IDOM_NodeFilter.hpp"
class PerlNodeFilterCallbackHandler : public IDOM_NodeFilter
				    , public  PerlCallbackHandler
{

protected:
//    SV *callbackObj;

public:

    PerlNodeFilterCallbackHandler() {};
    PerlNodeFilterCallbackHandler(SV *obj) : PerlCallbackHandler(obj){};
    ~PerlNodeFilterCallbackHandler() {};

    SV* set_callback_obj(SV*);

	// The NodeFilter interface
    short acceptNode (const IDOM_Node* node) const;
};

#endif __PERLNODEFILTERCALLBACKHANDLER
