class PerlErrorCallbackHandler : public ErrorHandler {

public:

    PerlErrorCallbackHandler();
//    ~PerlErrorCallbackHandler();

    void set_callback_obj(SV*);

//     virtual void warning(const SAXParseException& exception);
//     virtual void error(const SAXParseException& exception);
//     virtual void fatalError(const SAXParseException& exception);
//     virtual void resetErrors(void);
};

