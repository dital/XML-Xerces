#include <stdlib.h>
#include "PerlErrorCallbackHandler.hpp"

PerlErrorCallbackHandler::PerlErrorCallbackHandler() {
    callbackObj = NULL;
//    printf("in error: constructor");
}

PerlErrorCallbackHandler::~PerlErrorCallbackHandler() {
    if (callbackObj) {
	SvREFCNT_dec(callbackObj); 
    }
//    printf("in error: destructor");
}

void
PerlErrorCallbackHandler::set_callback_obj(SV* object) {
    if (callbackObj) {
	SvREFCNT_dec(callbackObj); 
//	printf("decrementing callbackObj: set_callback");
    }
    SvREFCNT_inc(object);
    callbackObj = object;
//    printf("in error: set_callback");
}

void
PerlErrorCallbackHandler::warning(const SAXParseException& exception) {

//    printf("in error: warning"); 
    if (!callbackObj) return;

    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);

	// first put the callback object on the stack
    XPUSHs(callbackObj);

	// then put the exception on the stack
    char *class_name = "XML::Xerces::SAXParseException";
    XPUSHs(sv_setref_pv(sv_newmortal(), 
			class_name, 
			(void *)&exception));

    PUTBACK;

    perl_call_method("warning", G_VOID);

    FREETMPS;
    LEAVE;
}

void
PerlErrorCallbackHandler::error(const SAXParseException& exception) {

//    printf("in error: error"); 
    if (!callbackObj) return;

    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
	// first put the callback object on the stack
    XPUSHs(callbackObj);

	// then put the exception on the stack
    char *class_name = "XML::Xerces::SAXParseException";
    XPUSHs(sv_setref_pv(sv_newmortal(), 
			class_name, 
			(void *)&exception));
    PUTBACK;

    perl_call_method("error", G_VOID);

    FREETMPS;
    LEAVE;
}

void
PerlErrorCallbackHandler::fatalError(const SAXParseException& exception) {
//    printf("in error: fatal_error"); 
    if (!callbackObj) {
	die("Received FatalError and no ErrorHandler was set");
    }

    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);

	// first put the callback object on the stack
    XPUSHs(callbackObj);

	// then put the exception on the stack
    char *class_name = "XML::Xerces::SAXParseException";
    XPUSHs(sv_setref_pv(sv_newmortal(), 
			class_name, 
			(void *)&exception));
    PUTBACK;

    perl_call_method("fatal_error", G_VOID);

    FREETMPS;
    LEAVE;
}


void
PerlErrorCallbackHandler::resetErrors(void) 
{
//    printf("in error: reset_errors"); 
    if (!callbackObj) return;

    dSP;

    PUSHMARK(SP);

	// first put the callback object on the stack
    XPUSHs(callbackObj);

    PUTBACK;

    perl_call_method("reset_errors", G_VOID);
}
