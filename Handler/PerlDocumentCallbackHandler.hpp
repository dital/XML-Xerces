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
#define PL_sv_yes PL_sv_yes
#endif
#ifndef PL_sv_undef
#define PL_sv_undef PL_sv_undef
#endif
#ifndef PL_na
#define PL_na PL_na
#endif
#endif

#include "xercesc/sax/DocumentHandler.hpp"
#include "xercesc/util/XMLString.hpp"
class PerlDocumentCallbackHandler : public DocumentHandler {

private:
    SV *callbackObj;

public:

    PerlDocumentCallbackHandler();
    ~PerlDocumentCallbackHandler();

    void set_callback_obj(SV*);

	// The DocumentHandler interface
    void startElement(const XMLCh* const name, 
		      AttributeList& attributes);
    void characters(const XMLCh* const chars, 
		       const unsigned int length);
    void ignorableWhitespace(const XMLCh* const chars, 
				const unsigned int length);
    void endElement(const XMLCh* const name);
    void resetDocument(void);
    void startDocument();
    void endDocument();
    void processingInstruction (const XMLCh* const target,
				const XMLCh* const data);
    void setDocumentLocator(const Locator* const locator);

};

