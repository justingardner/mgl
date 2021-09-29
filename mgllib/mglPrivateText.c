#ifdef documentation
=========================================================================

     program: mglText.c
          by: justin gardner
        date: 05/04/06
   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)

$Id$
=========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
#include "mgl.h"

////////////////////////
//   define section   //
////////////////////////
#define DEFAULT_FONT "Times Roman"
#define DEFAULT_FONTSIZE 36

/////////////////////////
//   OS Specific calls //
/////////////////////////
unsigned char *renderText(const mxArray *inputString, char*fontName, int fontSize, double *fontColor, double fontRotation, Boolean fontBold, Boolean fontItalic, Boolean fontUnderline, Boolean fontStrikethrough, int *pixelsWide, int *pixelsHigh, Rect *textImageRect);

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  // get status of global variable verbose
  int verbose = (int)mglGetGlobalDouble("verbose");

  int c,i,j,k;

  // check command line arguments
  if (nrhs == 0) {
    usageError("mglText");
    return;
  }

  // get the global variable for the font
  mxArray *gFontName = mglGetGlobalField("fontName");
  char fontName[1024];

  // check for null pointer
  if (gFontName == NULL)
    sprintf(fontName,DEFAULT_FONT);
  // otherwise get the font
  else {
    mxGetString(gFontName,fontName,1024);
  }

  // get fontsize
  int fontSize = (int)mglGetGlobalDouble("fontSize");
  if (fontSize == 0)
    fontSize = DEFAULT_FONTSIZE;

  // get fontcolor
  double fontColor[4] = {1, 0.5, 1, 1};
  mxArray *gFontColor = mglGetGlobalField("fontColor");
  if (gFontColor != NULL)
    mglGetColor(gFontColor,fontColor);

  // on intel mac it looks like we have to swap the bytes
#ifdef __LITTLE_ENDIAN__
  double temp;
  temp = fontColor[0];
  fontColor[0] = fontColor[3];
  fontColor[3] = temp;
  temp = fontColor[1];
  fontColor[1] = fontColor[2];
  fontColor[2] = temp;
#endif

  // display font color if verbose
  if (verbose)
    mexPrintf("(mglText) fontColor: [%f %f %f %f]\n",fontColor[0],fontColor[1],fontColor[2],fontColor[3]);

  // default font size
  if (fontSize == 0)
    fontSize = DEFAULT_FONTSIZE;

  // display font
  if (verbose)
    printf("(mglText) Using font: %s size: %i\n", fontName,fontSize);

  // get fontrotation
  double fontRotation = mglGetGlobalDouble("fontRotation");

  // get font characteristics
  Boolean fontBold = (Boolean)mglGetGlobalDouble("fontBold");
  Boolean fontItalic = (Boolean)mglGetGlobalDouble("fontItalic");
  Boolean fontStrikethrough = (Boolean)mglGetGlobalDouble("fontStrikeThrough");
  Boolean fontUnderline = (Boolean)mglGetGlobalDouble("fontUnderline");

  // now render the text into a bitmap.
  int pixelsWide = 0, pixelsHigh = 0;
  Rect textImageRect;
  unsigned char *bitmapData = renderText(prhs[0], fontName, fontSize, fontColor, fontRotation, fontBold, fontItalic, fontUnderline, fontStrikethrough, &pixelsWide, &pixelsHigh, &textImageRect);

  // create the output structure
  const char *fieldNames[] =  {"textImage","imageWidth","imageHeight","textImageRect"};
  const mwSize outDims[2] = {1, 1};
  plhs[0] = mxCreateStructArray(1,outDims,4,fieldNames);
  double *outptr;

  // now set the pixelsWide and height
  // notice that imagewidth and pixelsHigh are intentionally
  // transposed here, so that the image matches what matlab does
  mxSetField(plhs[0],0,"imageWidth",mxCreateDoubleMatrix(1,1,mxREAL));
  outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"imageWidth"));
  *outptr = (double)pixelsHigh;
  mxSetField(plhs[0],0,"imageHeight",mxCreateDoubleMatrix(1,1,mxREAL));
  outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"imageHeight"));
  *outptr = (double)pixelsWide;

  // information about the axes
  mxSetField(plhs[0],0,"textImageRect",mxCreateDoubleMatrix(1,4,mxREAL));//
  outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"textImageRect"));
  outptr[0] = (double)textImageRect.top;
  outptr[1] = (double)textImageRect.left;
  outptr[2] = (double)textImageRect.bottom;
  outptr[3] = (double)textImageRect.right;

  // if the user has specified more output arguments, then
  // return a matrix with the image data. Can't figure
  // out how to make a 3D matrix in mexfile, so it's
  // 2d and needs to be unpacked in matlab
  mxSetField(plhs[0],0,"textImage",mxCreateDoubleMatrix(pixelsWide,pixelsHigh*4,mxREAL));
  outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"textImage"));
  c = 0;
  int outptrIndex = 0;
  // for each color component
  for (k=0;k<4;k++) {
    c=0;
    // copy the data into the output matrix
    for (j = 0; j < pixelsHigh; j++) {
    	for (i = 0; i < pixelsWide; i++, c++) {
	      outptr[outptrIndex++] = (double)((unsigned char *)bitmapData)[c*4+k];
	    }
    }
  }
  // free up the original bitmapData
  free(bitmapData);
}

#ifdef __APPLE__
//-----------------------------------------------------------------------------------///
// ******************************* mac specific code  ******************************* //
//-----------------------------------------------------------------------------------///

// this wrapper no longer seems to exist
#define verify_noerr(x) (x)

unsigned char *renderText(const mxArray *inputString, char*fontName, int fontSize, double *fontColor, double fontRotation, Boolean fontBold, Boolean fontItalic, Boolean fontUnderline, Boolean fontStrikethrough, int *pixelsWide, int *pixelsHigh, Rect *textImageRect)
{
  // get text string
  int buflen = mxGetN(inputString)*mxGetM(inputString)+1;
  char *cInputString= (char*)malloc(buflen);
  if (cInputString == NULL) {
    mexPrintf("(mglText) Could not allocate buffer for string array of length %i\n",buflen);
    return(NULL);
  }
  // get the string
  mxGetString(inputString, cInputString, buflen);

  // get status of global variable verbose
  int verbose = (int)mglGetGlobalDouble("verbose");

  //////////////////////////
  // This code is modified from ATSUI Basics example Program helloworld.c
  //////////////////////////
  CFStringRef			string;
  UniChar			*text;
  UniCharCount			length;
  ATSUStyle			style;
  ATSUTextLayout		layout;
  ATSUFontID			font;
  Fixed				pointSize;
  ATSUAttributeTag		tags[2];
  ByteCount			sizes[2];
  ATSUAttributeValuePtr	        values[2];
  float				x, y, cgY;

  ////////////////////////////////////
  // Create style object
  ////////////////////////////////////
  // Create a style object. This is one of two objects necessary to draw using ATSUI.
  // (The layout is the other.)
  verify_noerr( ATSUCreateStyle(&style) );

  // Now we are going to set a few things in the style.
  // This is not strictly necessary, as the style comes
  // with some sane defaults after being created, but
  // it is useful to demonstrate.

  ////////////////////////////////////
  // Get font
  ////////////////////////////////////
  // Look up the font we are going to use, and set it in the style object, using
  // the aforementioned "triple" (tag, size, value) semantics. This is how almost
  // all settings in ATSUI are applied.
  verify_noerr( ATSUFindFontFromName(fontName, strlen(fontName), kFontFullName, kFontNoPlatform, kFontNoScript, kFontNoLanguage, &font) );
  tags[0] = kATSUFontTag;
  sizes[0] = sizeof(ATSUFontID);
  values[0] = &font;
  verify_noerr( ATSUSetAttributes(style, 1, tags, sizes, values) );

  // Notice below the point size is set as Fixed, not an int or a float.
  // For historical reasons, most values in ATSUI are Fixed or Fract, not int or float.
  // See the header FixMath.h in the CarbonCore framework for conversion macros.

  // Set the point size, also using a triple. You can actually set multiple triples at once,
  // since the tag, size, and value parameters are arrays. Other examples do this, such as
  // the vertical text example.
  //
  pointSize = Long2Fix(fontSize);
  tags[0] = kATSUSizeTag;
  sizes[0] = sizeof(Fixed);
  values[0] = &pointSize;
  verify_noerr( ATSUSetAttributes(style, 1, tags, sizes, values) );

  // set color of text, this should work, but is giving inconsistent
  // results of setting color, so as a fix, we will set the color here
  // to white and later on convert the generated bitmaps to the correct
  // color. see below under "set color of bitmap"
  //  ATSURGBAlphaColor textColor = {fontColor[0], fontColor[1], fontColor[2], fontColor[3]};
  ATSURGBAlphaColor textColor;
  textColor.red = 1.0;
  textColor.green = 1.0;
  textColor.blue = 1.0;
  textColor.alpha = 1.0;
  tags[0] = kATSURGBAlphaColorTag;
  sizes[0] = sizeof(ATSURGBAlphaColor);
  values[0] = &textColor;
  verify_noerr( ATSUSetAttributes(style, 1, tags, sizes, values) );

  // set bold
  tags[0] = kATSUQDBoldfaceTag;
  sizes[0] = sizeof(Boolean);
  values[0] = &fontBold;
  verify_noerr( ATSUSetAttributes(style, 1, tags, sizes, values) );

  // set italic
  tags[0] = kATSUQDItalicTag;
  sizes[0] = sizeof(Boolean);
  values[0] = &fontItalic;
  verify_noerr( ATSUSetAttributes(style, 1, tags, sizes, values) );

  // set strike-through
  tags[0] = kATSUStyleStrikeThroughTag;
  sizes[0] = sizeof(Boolean);
  values[0] = &fontStrikethrough;
  verify_noerr( ATSUSetAttributes(style, 1, tags, sizes, values) );

  // set strike-through
  tags[0] = kATSUQDUnderlineTag;
  sizes[0] = sizeof(Boolean);
  values[0] = &fontUnderline;
  verify_noerr( ATSUSetAttributes(style, 1, tags, sizes, values) );

  ////////////////////////////////////
  // Create text layout
  ////////////////////////////////////
  // Now we create the second of two objects necessary to draw text using ATSUI, the layout.
  // You can specify a pointer to the text buffer at layout creation time, or later using
  // the routine ATSUSetTextPointerLocation(). Below, we do it after layout creation time.
  verify_noerr( ATSUCreateTextLayout(&layout) );

  ////////////////////////////////////
  // Convert string to unicode
  ////////////////////////////////////
  // Before assigning text to the layout, we must first convert the string we plan to draw
  // from a CFStringRef into an array of UniChar.
  string = CFStringCreateWithCString(NULL, cInputString, kCFStringEncodingASCII);

  // Extract the raw Unicode from the CFString, then dispose of the CFString
  length = CFStringGetLength(string);
  text = (UniChar *)malloc(length * sizeof(UniChar));
  CFStringGetCharacters(string, CFRangeMake(0, length), text);
  CFRelease(string);

  // set rotation of text
  Fixed textRotation = FloatToFixed(-90.0+fontRotation);
  tags[0] = kATSULineRotationTag;
  sizes[0] = sizeof(Fixed);
  values[0] = &textRotation;
  verify_noerr( ATSUSetLayoutControls(layout, 1, tags, sizes, values) );
  ////////////////////////////////////
  // Attach text to layout
  ////////////////////////////////////
  // If input is 16bit Uint then it is a unicode, otherwise Attach the resulting UTF-16 Unicode text to the layout
  if (mxIsUint16(inputString))
    verify_noerr( ATSUSetTextPointerLocation(layout,(UniChar*)mxGetData(inputString),kATSUFromTextBeginning, kATSUToTextEnd, mxGetN(inputString)));
  else
    verify_noerr( ATSUSetTextPointerLocation(layout,text,kATSUFromTextBeginning, kATSUToTextEnd, length) );

  // Now we tie the two necessary objects, the layout and the style, together
  verify_noerr( ATSUSetRunStyle(layout, style, kATSUFromTextBeginning, kATSUToTextEnd) );

  ////////////////////////////////////
  // measure the bounds of the text
  ////////////////////////////////////
  verify_noerr( ATSUMeasureTextImage(layout,kATSUFromTextBeginning,kATSUToTextEnd,0,0,textImageRect));

  if (verbose)
    mexPrintf("(mglText) textImageRect: %i %i %i %i\n",textImageRect->top,textImageRect->left,textImageRect->bottom,textImageRect->right);

  // get the height and width of the text image
  *pixelsWide = (abs(textImageRect->right)+abs(textImageRect->left))+5;
  *pixelsHigh = (abs(textImageRect->bottom)+abs(textImageRect->top))+3;
  // adding this alignment here helps so that we don't get weird
  // overruns with certain text sizes (i.e. seems like width may
  // need to be a multiple of something?) but then this messes up
  // the alignment, so leaving it commented for now.
  //  pixelsWide = (int)(64.0*ceil(((double)pixelsWide)/64.0));
  //  pixelsHigh = (int)(64.0*ceil(((double)pixelsHigh)/64.0));

  ////////////////////////////////////
  // allocate bitmap context
  ////////////////////////////////////
  // now we know how large the text is going to be, allocate a bitmap with
  // the correct dimensions (this code is modified from "Creating a Bitmap Graphics Context"
  // in the Quartz 2D Programming Guide:
  // http://developer.apple.com/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_context/chapter_3_section_4.html#//apple_ref/doc/uid/TP30001066-CH203-CJBHBFFE

  CGContextRef    bitmapContext = NULL;
  CGColorSpaceRef colorSpace;
  int             bitmapByteCount;
  int             bitmapBytesPerRow;
  void            *bitmapData = NULL;

  // calculate bytes per row and count
  bitmapBytesPerRow   = (*pixelsWide * 4);
  bitmapByteCount     = (bitmapBytesPerRow * (*pixelsHigh));

  if (verbose)
    mexPrintf("(mglText) Buffer size: width: %i height: %i bytesPerRow: %i byteCount: %i\n",*pixelsWide,*pixelsHigh,bitmapBytesPerRow,bitmapByteCount);

  // set colorspace
#if 0
  colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
#else
  colorSpace = CGColorSpaceCreateDeviceRGB();
#endif
  // allocate memory for the bitmap and set to zero
  bitmapData = malloc(bitmapByteCount);
  memset(bitmapData,0,bitmapByteCount);

  // check to see if we allocated memory properly
  if (bitmapData == NULL) {
    mexPrintf ("(mglText) UHOH: Memory not bitmap could not be allocated\n");
    free(text);
    verify_noerr( ATSUDisposeStyle(style) );
    verify_noerr( ATSUDisposeTextLayout(layout) );
    free(cInputString);
    return(NULL);
  }

  // create the bitmap context
  bitmapContext = CGBitmapContextCreate(bitmapData,*pixelsWide,*pixelsHigh,8,bitmapBytesPerRow,colorSpace,kCGImageAlphaPremultipliedFirst);

  // check to see if we succeeded
  if (bitmapContext == NULL) {
    mexPrintf ("(mglText) UHOH: Bitmap context could not be created\n");
    free (bitmapData);
    free(text);
    verify_noerr( ATSUDisposeStyle(style) );
    verify_noerr( ATSUDisposeTextLayout(layout) );
    free(cInputString);
    return(NULL);
  }
  // release the color space
  CGColorSpaceRelease( colorSpace );

  ////////////////////////////////////
  // Bind context and layout
  ////////////////////////////////////
  // We use the bitmap context created above to draw into. Following is the comment
  // from the example code.
  //
  // On OS 9, ATSUI would draw using only Quickdraw. With Mac OS X, it can draw with
  // either Quickdraw or CoreGraphics. Quickdraw is now being de-emphasized in favor
  // of CoreGraphics, to the point where ATSUI will default to drawing using CoreGraphics.
  // By default ATSUI will work by using the cannonical CGContext that comes with every GrafPort.
  // However, it is preferred that clients set up their own CGContext and pass it to ATSUI
  // before drawing. This not only gives the client more control, it offers the best performance.
  //
  tags[0] = kATSUCGContextTag;
  sizes[0] = sizeof(CGContextRef);
  values[0] = &bitmapContext;
  verify_noerr( ATSUSetLayoutControls(layout, 1, tags, sizes, values) );

  ////////////////////////////////////
  // Draw text
  ////////////////////////////////////
  // Now, finally, we are ready to draw.
  //
  // When drawing it is important to note the difference between QD and CG style coordinates.
  // For QD, the y coordinate starts at zero at the top of the window, and goes down. For CG,
  // it is just the opposite. Because we have set a CGContext in our layout, ATSUI will be
  // expecting CG style coordinates. Otherwise, it would be expecting QD style coordinates.
  // Also, remember ATSUI only accepts coordinates in Fixed, not float or int. In our example,
  // "x" and "y" are the coordinates in QD space. "cgY" contains the y coordinate in CG space.
  //

  // window to get the coordinate in CG-aware space.
  x = 2-textImageRect->left;
  cgY = *pixelsHigh-2+textImageRect->top;
  verify_noerr( ATSUDrawText(layout, kATSUFromTextBeginning, kATSUToTextEnd, X2Fix(x), X2Fix(cgY)) );

  ////////////////////////////////////
  // Free up resources
  ////////////////////////////////////
  // Deallocate string storage
  free(text);
  free(cInputString);

  // Layout and style also need to be disposed
  verify_noerr( ATSUDisposeStyle(style) );
  verify_noerr( ATSUDisposeTextLayout(layout) );

  ////////////////////////////////////
  // Set color of bitmap
  ////////////////////////////////////

  // copy the data into the buffer
  int n=0,c,i,j;
  for (c = 0; c < 4; c++) {
    for (j = 0; j < *pixelsHigh; j++) {
      for (i = 0; i < (*pixelsWide)*4; i+=4) {
	((unsigned char*)bitmapData)[i+j*(*pixelsWide)*4+c] = (unsigned char)(fontColor[c]*(double)((unsigned char *)bitmapData)[i+j*(*pixelsWide)*4+c]);
      }
    }
  }
  // free bitmap context
  CGContextRelease(bitmapContext);

  // return buffer of rendered text
  return(bitmapData);
}
#endif //__APPLE__
