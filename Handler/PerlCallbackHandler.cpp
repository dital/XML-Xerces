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
    SvREFCNT_inc(object);
    callbackObj = object;
}

// SV*
// PerlCallbackHandler::set_callback_obj(SV* object) {
//     SV *oldRef = &PL_sv_undef;	// default to 'undef'
//     if (callbackObj != NULL) {
// 	oldRef = callbackObj;
// 	SvREFCNT_dec(oldRef);
//     }
//     SvREFCNT_inc(object);
//     callbackObj = object;
//     return oldRef;
// }

