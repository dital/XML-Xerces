class PerlDocumentCallbackHandler : public DocumentHandler {

// private:
//     SV *callbackObj;

public:

    PerlDocumentCallbackHandler();
//    ~PerlDocumentCallbackHandler();

    void set_callback_obj(SV*);

	// The DocumentHandler interface
//     void startElement(const XMLCh* /*const*/ name, 
// 			 AttributeList& attributes);
//     void endElement(const XMLCh* /*const*/ name);
//     void characters(const XMLCh* /*const*/ chars, 
// 			  const unsigned int length);
//     void ignorableWhitespace(const XMLCh* /*const*/ chars, 
// 				   const unsigned int length);
//     void resetDocument(void);
//     void startDocument();
//     void endDocument();
//     void processingInstruction (const XMLCh* /*const*/ target,
// 					 const XMLCh* /*const*/ data);
//     void setDocumentLocator(const Locator* /*const*/ locator);

};

