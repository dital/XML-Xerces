#include "PerlNodeFilterCallbackHandler.hpp"

SV*
PerlNodeFilterCallbackHandler::set_callback_obj(SV* object) {
    SV *oldRef = &PL_sv_undef;	// default to 'undef'
    if (callbackObj != NULL) {
	oldRef = callbackObj;
	SvREFCNT_dec(oldRef);
    }
    SvREFCNT_inc(object);
    callbackObj = object;
    return oldRef;
}

short
PerlNodeFilterCallbackHandler::acceptNode (const IDOM_Node* node) const
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
    swig_type_info *ty = SWIG_TypeDynamicCast(SWIGTYPE_p_IDOM_Node, (void **) &node);
    SV* node_sv = sv_newmortal();
    SWIG_MakePtr(node_sv, (void *) node, ty);
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
