#ifndef __PERLENTITYRESOLVERHANDLER
#define __PERLENTITYRESOLVERHANDLER

#include "PerlCallbackHandler.hpp"
#include "xercesc/sax/EntityResolver.hpp"
#include "xercesc/util/XMLString.hpp"

class InputSource;
class PerlEntityResolverHandler: public EntityResolver
			       , public  PerlCallbackHandler
 {

protected:
//    SV *callbackObj;

public:

    PerlEntityResolverHandler() {};
    PerlEntityResolverHandler(SV *obj) : PerlCallbackHandler(obj) {};
    ~PerlEntityResolverHandler() {};

    SV* set_callback_obj(SV*);

	// The EntityResolver interface
    InputSource* resolveEntity (const XMLCh* const publicId, 
				const XMLCh* const systemId);

};

#endif /* __PERLENTITYRESOLVERHANDLER */
