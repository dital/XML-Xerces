#include "PerlNodeFilterCallbackHandler.hpp"

PerlNodeFilterCallbackHandler::PerlNodeFilterCallbackHandler()
{
    callbackObj = NULL;
}

PerlNodeFilterCallbackHandler::~PerlNodeFilterCallbackHandler()
{
    if (callbackObj != NULL) {
	SvREFCNT_dec(callbackObj);
	callbackObj = NULL;
    }
}

PerlNodeFilterCallbackHandler::PerlNodeFilterCallbackHandler(SV *obj)
{
    set_callback_obj(obj);
}

SV*
PerlNodeFilterCallbackHandler::set_callback_obj(SV* object) {
    SV *oldRef = &PL_sv_undef;	// default to 'undef'
    if (callbackObj != NULL) {
	oldRef = callbackObj;
#if defined(PERL_VERSION) && PERL_VERSION >= 8
//	SvREFCNT_dec(oldRef);
#endif
    }
    SvREFCNT_inc(object);
    callbackObj = object;
    return oldRef;
}

short
PerlNodeFilterCallbackHandler::acceptNode (const DOMNode* node) const
{
    if (!callbackObj) {
        croak("\nacceptNode: no NodeFilter set\n");
	return 0;
    }

    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
	// first put the callback object on the stack
    XPUSHs(callbackObj);

        // the only argument is the node
    swig_type_info *ty = SWIG_TypeDynamicCast(SWIGTYPE_p_XERCES_CPP_NAMESPACE__DOMNode, (void **) &node);
    SV* node_sv = sv_newmortal();
    SWIG_MakePtr(node_sv, (void *) node, ty,0);
    XPUSHs(node_sv);

    PUTBACK;

    int count = perl_call_method("acceptNode", G_SCALAR);

    SPAGAIN ;

    if (count != 1)
	croak("NodeFilter did not return an answer\n") ;

    short accept = POPi;

    PUTBACK ;
    FREETMPS;
    LEAVE;
    return accept;
}
