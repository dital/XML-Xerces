#ifdef __cplusplus
/* Needed on some windows machines---since MS plays funny
   games with the header files under C++ */
#include <math.h>
#include <stdlib.h>
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* Get rid of free and malloc defined by perl */
#undef free
#undef malloc

#include <string.h>
#ifdef __cplusplus
}
#endif

#if !defined(PERL_REVISION) || ((PERL_REVISION >= 5) && ((PERL_VERSION < 5) || ((PERL_VERSION == 5) && (PERL_SUBVERSION < 50))))
#ifndef PL_sv_yes
#define PL_sv_yes sv_yes
#endif
#ifndef PL_sv_undef
#define PL_sv_undef sv_undef
#endif
#ifndef PL_na
#define PL_na na
#endif
#endif

#include "xercesc/sax/EntityResolver.hpp"
#include "xercesc/util/XMLString.hpp"

class InputSource;
class PerlEntityResolverHandler: public EntityResolver {

private:
    SV *callbackObj;

public:

    PerlEntityResolverHandler();
    ~PerlEntityResolverHandler();

    SV* set_callback_obj(SV*);

	// The EntityResolver interface
    InputSource* resolveEntity (const XMLCh* const publicId, 
				const XMLCh* const systemId);

};

