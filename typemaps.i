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
/* TYPEMAP.  IT IS MAJORLY KLUDGY, BUT IT WORKS.                        */
/*                                                                      */
/* ONE PROBLEM:  A FEW XERCES FUNCTIONS TAKE MULTIPLE ARGUMENTS OF      */
/* TYPE XMLCh STRING.  THEREFORE, A DIFFERENT TEMPORARY VARIABLE MUST   */
/* BE USED FOR EACH ONE.  THIS IS ACCOMPLISHED BY MAKING SEPERATE       */
/* in AND freearg TYPEMAPS FOR EACH ARGUMENT OF A GIVEN NAME. ONCE      */
/* AGAIN, THIS IS KLUDGY, BUT IT WORKS.                                 */
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

/********************/
/*                  */
/* GENERIC ARGUMENT */
/*                  */
/********************/
%typemap(perl5, in) XMLCh * {
  if (SvPOK($input)||SvIOK($input)||SvNOK($input)) {
    $1 = Perl2XMLString($input);
  } else {
    croak("Type error in argument 2 of $name, Expected perl-string.");
    XSRETURN(1);
  }
}

%typemap(perl5, freearg) XMLCh * {
  delete[] $1;
}

// 
// RETURN VALUE OF getMessage METHOD ON A saxException (WHAT A 
// perlErrorHandler) FUNCTION SUCH AS "warning" RECEIVES AS AN ARGUMENT
// 
%typemap(perl5, out) XMLCh * {
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

%typemap(perl5, in) (const XMLByte* const srcDocBytes, unsigned int byteCount) {
  if (SvPOK($input)||SvIOK($input)||SvNOK($input)) {
    XMLByte *xmlbytes = (XMLByte *)SvPV($input, $2);
    $1 = new XMLByte[$2];
    memcpy($1, xmlbytes, $2);
  } else {
    croak("Type error in argument 2 of $symname, Expected perl-string.");
    XSRETURN(1);
  }
}

// PERL SHOULD IGNORE THIS ARGUMENT -- CALCULATE IN KLUDGE ABOVE FOR MemBufInputSource 
%typemap(perl5, ignore) const unsigned int byteCount {
}

// 
// FOR Perl*Handler MEMBER FUNCTIONS, SO PERL SCALAR DOESN'T GET WRAPPED 
// BY SWIG
// 
%typemap(perl5, in) SV * {
  $1 = $input;
}

//
// IDOM_Node*
//

%typemap(out) IDOM_Node* {
    swig_type_info *ty = SWIG_TypeDynamicCast($1_descriptor, (void **) &$1);
    ST(argvi) = sv_newmortal();
    SWIG_MakePtr(ST(argvi++), (void *) result, ty);
}

// %typemap(out) IDOM_Node * = SWIGTYPE *DYNAMIC;

DYNAMIC_CAST(SWIGTYPE_p_IDOM_Node, IDOM_Node_dynamic_cast);

%{
static swig_type_info *
IDOM_Node_dynamic_cast(void **ptr) {
   IDOM_Node **nptr = (IDOM_Node **) ptr;
   if (*nptr == NULL) {
       return NULL;
   }
   short int type = (*nptr)->getNodeType();
   if (type == IDOM_Node::TEXT_NODE) {
      return SWIGTYPE_p_IDOM_Text;
   }
   if (type == IDOM_Node::PROCESSING_INSTRUCTION_NODE) {
      return SWIGTYPE_p_IDOM_ProcessingInstruction;
   }
   if (type == IDOM_Node::DOCUMENT_NODE) {
      return SWIGTYPE_p_IDOM_Document;
   }
   if (type == IDOM_Node::ELEMENT_NODE) {
      return SWIGTYPE_p_IDOM_Element;
   }
   if (type == IDOM_Node::ENTITY_REFERENCE_NODE) {
      return SWIGTYPE_p_IDOM_EntityReference;
   }
   if (type == IDOM_Node::CDATA_SECTION_NODE) {
      return SWIGTYPE_p_IDOM_CDATASection;
   }
   if (type == IDOM_Node::CDATA_SECTION_NODE) {
      return SWIGTYPE_p_IDOM_CDATASection;
   }
   if (type == IDOM_Node::COMMENT_NODE) {
      return SWIGTYPE_p_IDOM_Comment;
   }
   if (type == IDOM_Node::DOCUMENT_TYPE_NODE) {
      return SWIGTYPE_p_IDOM_DocumentType;
   }
   if (type == IDOM_Node::ENTITY_NODE) {
      return SWIGTYPE_p_IDOM_Entity;
   }
   if (type == IDOM_Node::ATTRIBUTE_NODE) {
      return SWIGTYPE_p_IDOM_Attr;
   }
   if (type == IDOM_Node::NOTATION_NODE) {
      return SWIGTYPE_p_IDOM_Notation;
   }
   return NULL;
}
%}

