class PerlNodeFilterCallbackHandler : public IDOM_NodeFilter {

public:

    PerlNodeFilterCallbackHandler();

    void set_callback_obj(SV*);

};

