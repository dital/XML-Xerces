class PerlCallbackHandler {

public:

   PerlCallbackHandler();
   PerlCallbackHandler(SV*);
   SV* set_callback_obj(SV*);
};

class PerlNodeFilterCallbackHandler : public DOMNodeFilter, public PerlCallbackHandler {

public:

    PerlNodeFilterCallbackHandler();
    PerlNodeFilterCallbackHandler(SV*);
//    void set_callback_obj(SV*);

};

class PerlDocumentCallbackHandler : public DocumentHandler, public PerlCallbackHandler {

public:

    PerlDocumentCallbackHandler();
    PerlDocumentCallbackHandler(SV*);
//    void set_callback_obj(SV*);

};

class PerlContentCallbackHandler : public ContentHandler, public PerlCallbackHandler {

public:

    PerlContentCallbackHandler();
    PerlContentCallbackHandler(SV*);
//    void set_callback_obj(SV*);

};

class PerlEntityResolverHandler : public EntityResolver, public PerlCallbackHandler {

public:

    PerlEntityResolverHandler();
    PerlEntityResolverHandler(SV*);
//    void set_callback_obj(SV*);

};

class PerlErrorCallbackHandler : public ErrorHandler, public PerlCallbackHandler {

public:

    PerlErrorCallbackHandler();
    PerlErrorCallbackHandler(SV*);
//    void set_callback_obj(SV*);
};


