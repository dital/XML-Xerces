class PerlEntityResolverHandler : public EntityResolver {


public:

    PerlEntityResolverHandler();
    ~PerlEntityResolverHandler();

    SV* set_callback_obj(SV*);
//    InputSource* resolveEntity (const XMLCh* /*const*/ publicId, 
//				const XMLCh* /*const*/ systemId);
//
};

