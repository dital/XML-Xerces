#include <stdlib.h>
#include "PerlDocumentCallbackHandler.hpp"

SV*
PerlDocumentCallbackHandler::set_callback_obj(SV* object) {
    SV *oldRef = &PL_sv_undef;	// default to 'undef'
    if (callbackObj != NULL) {
	oldRef = callbackObj;
	SvREFCNT_dec(oldRef);
    }
    SvREFCNT_inc(object);
    callbackObj = object;
    return oldRef;
}

void
PerlDocumentCallbackHandler::startElement(const XMLCh* const name, 
				  AttributeList& attributes) {
    if (!callbackObj) return;

    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
	// first put the callback object on the stack
    XPUSHs(callbackObj);

        // the next argument is the element name
    char *cptr = XMLString::transcode(name);
    SV *string = sv_newmortal();
    sv_setpv(string, (char *)cptr);
    XPUSHs(string);

        // next is the attribute list
    char *class_name = "XML::Xerces::AttributeList";
    XPUSHs(sv_setref_pv(sv_newmortal(), 
			class_name, 
			(void *)&attributes));

    PUTBACK;

    perl_call_method("start_element", G_DISCARD);

	// transcode mallocs this and leaves it up to us to free the memory
    delete [] cptr;

    FREETMPS;
    LEAVE;
}

void
PerlDocumentCallbackHandler::endElement(const XMLCh* const name)
{
    if (!callbackObj) return;

    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
	// first put the callback object on the stack
    XPUSHs(callbackObj);

        // the next argument is the element name
    char *cptr = XMLString::transcode(name);
    SV *string = sv_newmortal();
    sv_setpv(string, (char *)cptr);
    XPUSHs(string);

    PUTBACK;

    perl_call_method("end_element", G_DISCARD);

	// transcode mallocs this and leaves it up to us to free the memory
    delete [] cptr;

    FREETMPS;
    LEAVE;
}

void
PerlDocumentCallbackHandler::characters(const XMLCh* const chars, 
				const unsigned int length)
{
    if (!callbackObj) return;

    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
	// first put the callback object on the stack
    XPUSHs(callbackObj);

        // the next argument is the element name
    char *cptr = XMLString::transcode(chars);
    SV *string = sv_newmortal();
    sv_setpv(string, (char *)cptr);
    XPUSHs(string);

        // next is the length
    XPUSHs(sv_2mortal(newSViv(length)));

    PUTBACK;

    perl_call_method("characters", G_DISCARD);

	// transcode mallocs this and leaves it up to us to free the memory
    delete [] cptr;

    FREETMPS;
    LEAVE;
}
void
PerlDocumentCallbackHandler::ignorableWhitespace(const XMLCh* const chars, 
						 const unsigned int length)
{
    if (!callbackObj) return;

    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
	// first put the callback object on the stack
    XPUSHs(callbackObj);

        // the next argument is the element name
    char *cptr = XMLString::transcode(chars);
    SV *string = sv_newmortal();
    sv_setpv(string, (char *)cptr);
    XPUSHs(string);

        // next is the length
    XPUSHs(sv_2mortal(newSViv(length)));

    PUTBACK;

    perl_call_method("ignorable_whitespace", G_DISCARD);

	// transcode mallocs this and leaves it up to us to free the memory
    delete [] cptr;

    FREETMPS;
    LEAVE;
}

void
PerlDocumentCallbackHandler::resetDocument(void)
{
    return;
    if (!callbackObj) return;

    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
	// first put the callback object on the stack
    XPUSHs(callbackObj);

    PUTBACK;

    perl_call_method("reset_document", G_DISCARD);

    FREETMPS;
    LEAVE;
}

void
PerlDocumentCallbackHandler::startDocument(void)
{
    if (!callbackObj) return;

    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
	// first put the callback object on the stack
    XPUSHs(callbackObj);

    PUTBACK;

    perl_call_method("start_document", G_DISCARD);

    FREETMPS;
    LEAVE;
}

void
PerlDocumentCallbackHandler::endDocument(void)
{
    if (!callbackObj) return;

    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
	// first put the callback object on the stack
    XPUSHs(callbackObj);

    PUTBACK;

    perl_call_method("end_document", G_DISCARD);

    FREETMPS;
    LEAVE;
}


void
PerlDocumentCallbackHandler::processingInstruction(const XMLCh* const target,
						   const XMLCh* const data)
{
    if (!callbackObj) return;

    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
	// first put the callback object on the stack
    XPUSHs(callbackObj);

        // the next argument is the target
    char *cptr1 = XMLString::transcode(target);
    SV *string1 = sv_newmortal();
    sv_setpv(string1, (char *)cptr1);
    XPUSHs(string1);

        // the next argument is the data
    char *cptr2 = XMLString::transcode(data);
    SV *string2 = sv_newmortal();
    sv_setpv(string2, (char *)cptr2);
    XPUSHs(string2);

    PUTBACK;

    perl_call_method("processing_instruction", G_DISCARD);

	// transcode mallocs this and leaves it up to us to free the memory
    delete [] cptr1;
    delete [] cptr2;

    FREETMPS;
    LEAVE;
}

void
PerlDocumentCallbackHandler::setDocumentLocator(const Locator* const locator)
{
    if (!callbackObj) return;

    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
	// first put the callback object on the stack
    XPUSHs(callbackObj);

        // next is the attribute list
    char *class_name = "XML::Xerces::Locator";
    XPUSHs(sv_setref_pv(sv_newmortal(), 
			class_name, 
			(void *)locator));

    PUTBACK;

    perl_call_method("set_document_locator", G_DISCARD);

    FREETMPS;
    LEAVE;
}

