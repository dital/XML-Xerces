/***********/
/*         */
/* XMLCh * */
/*         */
/***********/

/************************************************************************/
/*                                                                      */
/* FOR FUNCTIONS TAKING XMLCh * (I.E AN XMLCh STRING) AS AN ARGUMENT -- */
/* NOW YOU CAN JUST SUPPLY A STRING.  THIS TYPEMAP CONVERTS             */
/* PERL-STRINGS TO XMLCh STRINGS AUTOMATICALLY                          */
/*                                                                      */
/************************************************************************/

/************************************************************************/
/*                                                                      */
/* CAVEAT:                                                              */
/* TO CONVERT STRINGS TO XMLCh STRINGS, A TEMPORARY POINTER MUST BE     */
/* CREATED IN THE in TYPEMAP TO POINT TO MEMORY THAT HOLDS THE          */
/* CONVERSION.  THE MEMORY IS DYNAMIC, SO IT MUST BE FREED AFTER THE C  */
/* FUNCTION THAT USES IT IS CALLED.  THIS IS DONE VIA A "freearg"       */
/* TYPEMAP.                                                             */
/*                                                                      */
/************************************************************************/

%{
SV*
XMLString2Perl(XMLCh* input){
    SV *output;
  unsigned int charsEaten = 0;
  int length  = XMLString::stringLen(input);      // string length
  XMLByte* res = new XMLByte[length * UTF8_MAXLEN];          // output string
  unsigned int total_chars =
    UTF8_TRANSCODER->transcodeTo((const XMLCh*) input, 
				   (unsigned int) length,
				   (XMLByte*) res,
				   (unsigned int) length*UTF8_MAXLEN,
				   charsEaten,
				   XMLTranscoder::UnRep_Throw
				   );
  res[total_chars] = '\0';
  if (DEBUG_UTF8_OUT) {
      printf("Xerces out length = %d: ",total_chars);
      for (int i=0;i<length;i++){
	  printf("<0x%.4X>",res[i]);
      }
      printf("\n");
  }
  output = sv_newmortal();
  sv_setpv((SV*)output, (char *)res );
  SvUTF8_on((SV*)output);
  delete[] res;
  return output;
}

XMLCh* 
Perl2XMLString(SV* input){
    XMLCh* output;

    STRLEN length;
    char *ptr = (char *)SvPV(input,length);
    if (DEBUG_UTF8_IN) {
	printf("Perl in length = %d: ",length);
	for (unsigned int i=0;i<length;i++){
	    printf("<0x%.4X>",ptr[i]);
	}
	printf("\n");
    }
    if (SvUTF8(input)) {
	unsigned int charsEaten = 0;
        unsigned char* sizes = new unsigned char[length+1];
        output = new XMLCh[length+1];
	unsigned int chars_stored = 
	    UTF8_TRANSCODER->transcodeFrom((const XMLByte*) ptr,
					   (unsigned int) length,
					   (XMLCh*) output, 
					   (unsigned int) length,
					   charsEaten,
					   (unsigned char*)sizes
					   );
	delete [] sizes;
	if (DEBUG_UTF8_IN) {
	    printf("Xerces in length = %d: ",chars_stored);
	    for (unsigned int i=0;i<chars_stored;i++){
		printf("<0x%.4X>",output[i]);
	    }
	    printf("\n");
	}
	    // indicate the end of the string
	output[chars_stored] = '\0';
    } else {
	output = XMLString::transcode(ptr);
	if (DEBUG_UTF8_IN) {
	    printf("Xerces: ");
	    for (int i=0;output[i];i++){
		printf("<0x%.4X>",output[i]);
	    }
	    printf("\n");
	}
    }
    return(output);
}
%}

// in typemap
%typemap(in) XMLCh * {
  if (SvPOK($input)||SvIOK($input)||SvNOK($input)) {
    $1 = Perl2XMLString($input);
  } else {
    croak("Type error in argument 2 of $name, Expected perl-string.");
    XSRETURN(1);
  }
}

%typemap(freearg) XMLCh * {
  delete[] $1;
}

// out typemap
%typemap(out) XMLCh * {
  $result = XMLString2Perl($1);
  ++argvi;
}

//
//  MemBufInputSource::MemBufInputSource()
// 

// 
// ALWAYS ADOPT BUFFER (I.E. MAKE A COPY OF IT) SINCE IT IS TAKEN FROM
// PERL, AND WHO KNOWS WHAT WILL HAPPEN TO IT AFTER IT IS GIVEN TO THE
// CONSTRUCTOR
// 

%typemap(in) (const XMLByte* const srcDocBytes, unsigned int byteCount) {
  if (SvPOK($input)||SvIOK($input)||SvNOK($input)) {
    STRLEN len;
    XMLByte *xmlbytes = (XMLByte *)SvPV($input, len);
    $2 = len;
    $1 = new XMLByte[len];
    memcpy($1, xmlbytes, len);
  } else {
    croak("Type error in argument 2 of $symname, Expected perl-string.");
    XSRETURN(1);
  }
}

// PERL SHOULD IGNORE THIS ARGUMENT 
%typemap(in,numinputs=0) const unsigned int byteCount {}

// 
// FOR Perl*Handler MEMBER FUNCTIONS, SO PERL SCALAR DOESN'T GET WRAPPED 
// 
%typemap(in) SV * {
  $1 = $input;
}

// XMLByte arrays are just char*'s
%apply char * {  XMLByte * }


// The typecheck functions are for use by SWIG's auto-overloading support
%typemap(typecheck, precedence=60)
SV*
{
  $1 = SvOK($input) ? 1 : 0;
}

%typemap(typecheck, precedence=70)
XMLCh*, const XMLCh* 
{
  $1 = SvPOK($input)||SvIOK($input)||SvNOK($input) ? 1 : 0;
}

//
// IDOM_Node*
//

// %typemap(out) DOMNode* {
//     swig_type_info *ty = SWIG_TypeDynamicCast($1_descriptor, (void **) &$1);
//     ST(argvi) = sv_newmortal();
//     SWIG_MakePtr(ST(argvi++), (void *) result, ty,0);
// }
%typemap(out) XERCES_CPP_NAMESPACE::DOMNode * = SWIGTYPE *DYNAMIC;

DYNAMIC_CAST(SWIGTYPE_p_XERCES_CPP_NAMESPACE__DOMNode, DOMNode_dynamic_cast);

%{
static swig_type_info *
DOMNode_dynamic_cast(void **ptr) {
   DOMNode **nptr = (DOMNode **) ptr;
   if (*nptr == NULL) {
       return NULL;
   }
   short int type = (*nptr)->getNodeType();
   if (type == DOMNode::TEXT_NODE) {
      return SWIGTYPE_p_XERCES_CPP_NAMESPACE__DOMText;
   }
   if (type == DOMNode::PROCESSING_INSTRUCTION_NODE) {
      return SWIGTYPE_p_XERCES_CPP_NAMESPACE__DOMProcessingInstruction;
   }
   if (type == DOMNode::DOCUMENT_NODE) {
      return SWIGTYPE_p_XERCES_CPP_NAMESPACE__DOMDocument;
   }
   if (type == DOMNode::ELEMENT_NODE) {
      return SWIGTYPE_p_XERCES_CPP_NAMESPACE__DOMElement;
   }
   if (type == DOMNode::ENTITY_REFERENCE_NODE) {
      return SWIGTYPE_p_XERCES_CPP_NAMESPACE__DOMEntityReference;
   }
   if (type == DOMNode::CDATA_SECTION_NODE) {
      return SWIGTYPE_p_XERCES_CPP_NAMESPACE__DOMCDATASection;
   }
   if (type == DOMNode::CDATA_SECTION_NODE) {
      return SWIGTYPE_p_XERCES_CPP_NAMESPACE__DOMCDATASection;
   }
   if (type == DOMNode::COMMENT_NODE) {
      return SWIGTYPE_p_XERCES_CPP_NAMESPACE__DOMComment;
   }
   if (type == DOMNode::DOCUMENT_TYPE_NODE) {
      return SWIGTYPE_p_XERCES_CPP_NAMESPACE__DOMDocumentType;
   }
   if (type == DOMNode::ENTITY_NODE) {
      return SWIGTYPE_p_XERCES_CPP_NAMESPACE__DOMEntity;
   }
   if (type == DOMNode::ATTRIBUTE_NODE) {
      return SWIGTYPE_p_XERCES_CPP_NAMESPACE__DOMAttr;
   }
   if (type == DOMNode::NOTATION_NODE) {
      return SWIGTYPE_p_XERCES_CPP_NAMESPACE__DOMNotation;
   }
   return NULL;
}
%}

