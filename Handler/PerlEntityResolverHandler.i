#include <iostream.h>
#include "xercesc/sax/InputSource.hpp"
#include "PerlEntityResolverHandler.hpp"

PerlEntityResolverHandler::PerlEntityResolverHandler() {
    callbackObj = NULL;
}

PerlEntityResolverHandler::~PerlEntityResolverHandler() {
    if (callbackObj) {
	SvREFCNT_dec(callbackObj); 
	callbackObj = NULL;
    }
}

SV*
PerlEntityResolverHandler::set_callback_obj(SV* object) {
    SV *oldRef = &PL_sv_undef;	// default to 'undef'
    if (callbackObj != NULL) {
	oldRef = callbackObj;
	SvREFCNT_dec(oldRef);
    }
    SvREFCNT_inc(object);
    callbackObj = object;
    return oldRef;
}

InputSource *
PerlEntityResolverHandler::resolveEntity (const XMLCh* const publicId, 
				      const XMLCh* const systemId)
{
    if (!callbackObj) {
        croak("\nresolveEntity: no EntityResolver set\n");
	return NULL;
    }

    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
	// first put the callback object on the stack
    XPUSHs(callbackObj);

        // the next argument is the publicId
    char *cptr1 = XMLString::transcode(publicId);
    SV *string1 = sv_newmortal();
    sv_setpv(string1, (char *)cptr1);
    XPUSHs(string1);

        // the next argument is the systemId
    char *cptr2 = XMLString::transcode(systemId);
    SV *string2 = sv_newmortal();
    sv_setpv(string2, (char *)cptr2);
    XPUSHs(string2);

    PUTBACK;

    int count = perl_call_method("resolve_entity", G_SCALAR);

    SPAGAIN ;

    if (count != 1)
	croak("EntityResolver did not retury any object\n") ;

    SV* source_sv = POPs;
    InputSource *source;
    if (!sv_derived_from(source_sv,"XML::Xerces::InputSource")) {
	croak("EntityResolver did not retury an InputSource\n") ;
    }

    if (SWIG_ConvertPtr(source_sv,(void **) &source, SWIGTYPE_p_InputSource) < 0) {
        croak("EntityResolver did not retury an InputSource. Expected %s", SWIGTYPE_p_InputSource->name);
    }
    PUTBACK ;
    FREETMPS;
    LEAVE;
    return source;
}
