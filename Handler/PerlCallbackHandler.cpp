#include <stdlib.h>
#include "PerlCallbackHandler.hpp"

PerlCallbackHandler::PerlCallbackHandler() {
   callbackObj = NULL;
//    printf("PerlCallback: constructor");
}

PerlCallbackHandler::~PerlCallbackHandler() {
     if (callbackObj) {
 	SvREFCNT_dec(callbackObj); 
 	callbackObj = NULL;
     }
//    printf("PerlCallback: destructor");
}

PerlCallbackHandler::PerlCallbackHandler(SV* object) {
  set_callback_obj(object);
}

PerlCallbackHandler::PerlCallbackHandler(PerlCallbackHandler* handler) {
    SvREFCNT_inc(callbackObj);
    handler->callbackObj = callbackObj;
//     printf("<copy constructor for obj: 0x%.4X, new obj: 0x%.4X>\n", this, handler);
}

SV*
PerlCallbackHandler::set_callback_obj(SV* object) {
    SV *oldRef = &PL_sv_undef;	// default to 'undef'
//    printf("<setting callback object for this: 0x%.4X>\n", this);
    if (callbackObj != NULL) {
	oldRef = callbackObj;
//	printf("<old callback object 0x%.4X>\n", callbackObj);
//	SvREFCNT_dec(oldRef);
    }
    SvREFCNT_inc(object);
//    printf("<setting callback object 0x%.4X>\n", object);
    callbackObj = object;
//    printf("<new callback object 0x%.4X>\n", callbackObj);
    return oldRef;
}

