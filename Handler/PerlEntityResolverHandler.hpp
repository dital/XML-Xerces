#ifndef __PERLENTITYRESOLVERHANDLER
#define __PERLENTITYRESOLVERHANDLER

#include "PerlCallbackHandler.hpp"
#include "xercesc/sax/EntityResolver.hpp"
#include "xercesc/sax/InputSource.hpp"
#include "xercesc/util/XMLString.hpp"

XERCES_CPP_NAMESPACE_USE

class PerlEntityResolverHandler: public EntityResolver
			       , public PerlCallbackHandler
 {

protected:

public:

    PerlEntityResolverHandler();
    PerlEntityResolverHandler(SV *obj);
    ~PerlEntityResolverHandler();

    int type() {return PERLCALLBACKHANDLER_ENTITY_TYPE;}

	// The EntityResolver interface
    InputSource* resolveEntity (const XMLCh* const publicId, 
				const XMLCh* const systemId);

};

#endif /* __PERLENTITYRESOLVERHANDLER */
