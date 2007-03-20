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

#ifdef __linux__
#include <string.h>
#include <math.h>

#include <ft2build.h>
#include FT_FREETYPE_H
#endif


////////////////////////
//   define section   //
////////////////////////
#define DEFAULT_FONT "Times Roman"
#define DEFAULT_FONTSIZE 36

///////////////////
//   functions   //
///////////////////
int sub2indM( int row, int col, int height, int elsize ) {
  // return linear index corresponding to (row,col) into row-major array (Matlab-style)
       return ( row*elsize + col*height*elsize );
}

int sub2indC( int row, int col, int width, int elsize ) {
  // return linear index corresponding to (row,col) into column-major array (C-style)
  return ( col*elsize + row*width*elsize );
}

#ifdef __linux__
void
draw_bitmap( FT_Bitmap*  bitmap,
             FT_Int      x,
             FT_Int      y,
	     unsigned char *image,
	     int width,
	     int height )
{
  FT_Int  i, j, p, q;
  FT_Int  x_max = x + bitmap->width;
  FT_Int  y_max = y + bitmap->rows;


  for ( i = x, p = 0; i < x_max; i++, p++ )
  {
    for ( j = y, q = 0; j < y_max; j++, q++ )
    {
      if ( i >= width || j >= height )
        continue;

      image[sub2indC(y,x,width,1)] |= bitmap->buffer[q * bitmap->width + p];
    }
  }
}
#endif

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  int c,i,j,k;

  // check command line arguments
  if (nrhs == 0) {
    usageError("mglText");
    return;
  }

  // get text string
  int buflen = mxGetN(prhs[0])*mxGetM( prhs[0] )+1;
  char *inputString= (char*)malloc(buflen);
  if (inputString == NULL) {
    mexPrintf("(mglText) UHOH: Could not allocate buffer for string array of length %i\n",buflen);
    return;
  }
  // get the string
  mxGetString( prhs[0], inputString, buflen);

  // get status of global variable that sets whether to display
  // verbose information
  int verbose = (int)mglGetGlobalDouble("verbose");

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

#ifdef __APPLE__
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
  Boolean bold = (Boolean)mglGetGlobalDouble("fontBold");
  tags[0] = kATSUQDBoldfaceTag;
  sizes[0] = sizeof(Boolean);
  values[0] = &bold;
  verify_noerr( ATSUSetAttributes(style, 1, tags, sizes, values) );

  // set italic
  Boolean italic = (Boolean)mglGetGlobalDouble("fontItalic");
  tags[0] = kATSUQDItalicTag;
  sizes[0] = sizeof(Boolean);
  values[0] = &italic;
  verify_noerr( ATSUSetAttributes(style, 1, tags, sizes, values) );

  // set strike-through
  Boolean strikeThrough = (Boolean)mglGetGlobalDouble("fontStrikeThrough");
  tags[0] = kATSUStyleStrikeThroughTag;
  sizes[0] = sizeof(Boolean);
  values[0] = &strikeThrough;
  verify_noerr( ATSUSetAttributes(style, 1, tags, sizes, values) );

  // set strike-through
  Boolean underline = (Boolean)mglGetGlobalDouble("fontUnderline");
  tags[0] = kATSUQDUnderlineTag;
  sizes[0] = sizeof(Boolean);
  values[0] = &underline;
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
  string = CFStringCreateWithCString(NULL, inputString, kCFStringEncodingASCII);

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
  if (mxIsUint16(prhs[0])) 
    verify_noerr( ATSUSetTextPointerLocation(layout,(UniChar*)mxGetData(prhs[0]),kATSUFromTextBeginning, kATSUToTextEnd, mxGetN(prhs[0])));
  else
    verify_noerr( ATSUSetTextPointerLocation(layout,text,kATSUFromTextBeginning, kATSUToTextEnd, length) );

  // Now we tie the two necessary objects, the layout and the style, together
  verify_noerr( ATSUSetRunStyle(layout, style, kATSUFromTextBeginning, kATSUToTextEnd) );

  ////////////////////////////////////
  // measure the bounds of the text
  ////////////////////////////////////
  Rect textImageRect;
  verify_noerr( ATSUMeasureTextImage(layout,kATSUFromTextBeginning,kATSUToTextEnd,0,0,&textImageRect));

  if (verbose)
    mexPrintf("(mglText) textImageRect: %i %i %i %i\n",textImageRect.top,textImageRect.left,textImageRect.bottom,textImageRect.right);

  // get the height and width of the text image
  int pixelsWide = (abs(textImageRect.right)+abs(textImageRect.left))+5;
  int pixelsHigh = (abs(textImageRect.bottom)+abs(textImageRect.top))+3;
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
  bitmapBytesPerRow   = (pixelsWide * 4);
  bitmapByteCount     = (bitmapBytesPerRow * pixelsHigh);
 
  if (verbose)
    mexPrintf("(mglText) Buffer size: width: %i height: %i bytesPerRow: %i byteCount: %i\n",pixelsWide,pixelsHigh,bitmapBytesPerRow,bitmapByteCount);

  // set colorspace
  colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);

  // allocate memory for the bitmap and set to zero
  bitmapData = malloc(bitmapByteCount);
  memset(bitmapData,0,bitmapByteCount);

  // check to see if we allocated memory properly
  if (bitmapData == NULL) {
    mexPrintf ("(mglText) UHOH: Memory not bitmap could not be allocated\n");
    free(text);
    verify_noerr( ATSUDisposeStyle(style) );
    verify_noerr( ATSUDisposeTextLayout(layout) );
    free(inputString);
    return;
  }

  // create the bitmap context
  bitmapContext = CGBitmapContextCreate(bitmapData,pixelsWide,pixelsHigh,8,bitmapBytesPerRow,colorSpace,kCGImageAlphaPremultipliedFirst);

  // check to see if we succeeded
  if (bitmapContext == NULL) {
    mexPrintf ("(mglText) UHOH: Bitmap context could not be created\n");
    free (bitmapData);
    free(text);
    verify_noerr( ATSUDisposeStyle(style) );
    verify_noerr( ATSUDisposeTextLayout(layout) );
    free(inputString);
    return;
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
  x = 2-textImageRect.left;
  cgY = pixelsHigh-2+textImageRect.top;
  verify_noerr( ATSUDrawText(layout, kATSUFromTextBeginning, kATSUToTextEnd, X2Fix(x), X2Fix(cgY)) );

  ////////////////////////////////////
  // Free up resources
  ////////////////////////////////////
  // Deallocate string storage
  free(text);
  free(inputString);

  // Layout and style also need to be disposed
  verify_noerr( ATSUDisposeStyle(style) );
  verify_noerr( ATSUDisposeTextLayout(layout) );

  ////////////////////////////////////
  // Set color of bitmap
  ////////////////////////////////////

  // copy the data into the buffer
  int n=0;
  for (c = 0; c < 4; c++) {
    for (j = 0; j < pixelsHigh; j++) {
      for (i = 0; i < pixelsWide*4; i+=4) {
	((unsigned char*)bitmapData)[i+j*pixelsWide*4+c] = (unsigned char)(fontColor[c]*(double)((unsigned char *)bitmapData)[i+j*pixelsWide*4+c]);
      }
    }
  }


  ///////////////////////////
  // create a texture
  ///////////////////////////
  GLuint textureNumber;

  // get a unique texture identifier name
  glGenTextures(1, &textureNumber);
  
  // bind the texture to be a 2D texture
  // should really add check that non-power-of-two textures are supported, but seems to be default on new Macs
  glBindTexture(GL_TEXTURE_RECTANGLE_EXT, textureNumber);

  // some other stuff
  glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glPixelStorei(GL_UNPACK_ROW_LENGTH,0);

  // now place the data into the texture
  glTexImage2D(GL_TEXTURE_RECTANGLE_EXT,0,GL_RGBA,pixelsWide,pixelsHigh,0,GL_RGBA,GL_UNSIGNED_INT_8_8_8_8,bitmapData);  

  // create the output structure
  const char *fieldNames[] =  {"textureNumber","imageWidth","imageHeight","textureAxes","textImageRect","hFlip","vFlip","isText" };
  int outDims[2] = {1, 1};
  plhs[0] = mxCreateStructArray(1,outDims,8,fieldNames);
  
  // now set the textureNumber field
  double *outptr;
  mxSetField(plhs[0],0,"textureNumber",mxCreateDoubleMatrix(1,1,mxREAL));
  outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"textureNumber"));
  *outptr = (double)textureNumber;

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
  mxSetField(plhs[0],0,"textureAxes",mxCreateString("xy"));  
  mxSetField(plhs[0],0,"textImageRect",mxCreateDoubleMatrix(1,4,mxREAL));
  outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"textImageRect"));
  outptr[0] = (double)textImageRect.top;
  outptr[1] = (double)textImageRect.left;
  outptr[2] = (double)textImageRect.bottom;
  outptr[3] = (double)textImageRect.right;

  // set information about desired flips
  mxSetField(plhs[0],0,"hFlip",mxCreateDoubleMatrix(1,1,mxREAL));
  outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"hFlip"));
  *outptr = mglGetGlobalDouble("fontHFlip");

  // set information about desired flips
  mxSetField(plhs[0],0,"vFlip",mxCreateDoubleMatrix(1,1,mxREAL));
  outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"vFlip"));
  *outptr = mglGetGlobalDouble("fontVFlip");

  mxSetField(plhs[0],0,"isText",mxCreateDoubleMatrix(1,1,mxREAL));
  outptr = (double*)mxGetPr(mxGetField(plhs[0],0,"isText"));
  *outptr = (double)1;

  // get a buffer for the bitmap data
  c = 0;
  for (k=0;k<4;k++) {
    if (nlhs >= (k+1)){
            plhs[k+1] = mxCreateDoubleMatrix(pixelsWide,pixelsHigh,mxREAL);
      //plhs[k+1] = mxCreateDoubleMatrix(pixelsHigh,pixelsWide,mxREAL);
      double *outputBuffer = (double *)mxGetPr(plhs[k+1]);
      c=0;
      // copy the data into the buffer
      for (j = 0; j < pixelsHigh; j++) {
	for (i = 0; i < pixelsWide; i++, c++) {
	  outputBuffer[c] = (double)((unsigned char *)bitmapData)[c*4+k];
	  //	  outputBuffer[c++] = (double)((unsigned char *)bitmapData)[i+j*pixelsWide*4+k];
	}
      }
    }
  }

  // free up the original bitmapData
  CGContextRelease(bitmapContext);
  free(bitmapData);

#endif

#ifdef __linux__

  FT_Library    library;
  FT_Face       face;

  FT_GlyphSlot  slot;
  FT_Matrix     matrix;                 /* transformation matrix */
  FT_UInt       glyph_index;
  FT_Vector     pen;                    /* untransformed origin  */
  FT_Error      error;

  double        angle;
  int           target_height, target_width;
  int           n, num_chars;


  num_chars     = strlen( inputString );
  angle         = ( fontRotation / 360 ) * 3.14159 * 2;      /* use 25 degrees     */
  target_height = HEIGHT;
  target_width = ;

  unsigned char * target_bitmap=(unsigned char *)malloc(target_height*target_width); 

  error = FT_Init_FreeType( &library );              /* initialize library */
  /* error handling omitted */

  error = FT_New_Face( library, fontName, 0, &face ); /* create face object */
  /* error handling omitted */

  /* use 50pt at 100dpi */
  error = FT_Set_Char_Size( face, 50 * 64, 0,
                            100, 0 );                /* set character size */
  /* error handling omitted */

  slot = face->glyph;

  /* set up matrix */
  matrix.xx = (FT_Fixed)( cos( angle ) * 0x10000L );
  matrix.xy = (FT_Fixed)(-sin( angle ) * 0x10000L );
  matrix.yx = (FT_Fixed)( sin( angle ) * 0x10000L );
  matrix.yy = (FT_Fixed)( cos( angle ) * 0x10000L );

  /* the pen position in 26.6 cartesian space coordinates; */
  /* start at (300,200) relative to the upper left corner  */
  pen.x = 300 * 64;
  pen.y = ( target_height - 200 ) * 64;

  for ( n = 0; n < num_chars; n++ )
  {
    /* set transformation */
    FT_Set_Transform( face, &matrix, &pen );

    /* load glyph image into the slot (erase previous one) */
    error = FT_Load_Char( face, inputString[n], FT_LOAD_RENDER );
    if ( error )
      continue;                 /* ignore errors */

    /* now, draw to our target surface (convert position) */
    draw_bitmap( &slot->bitmap,
                 slot->bitmap_left,
                 target_height - slot->bitmap_top, 
		 target_bitmap,
		 target_width,
		 target_height );

    /* increment pen position */
    pen.x += slot->advance.x;
    pen.y += slot->advance.y;
  }

  // Convert text bitmap to RGBA texture map
  GLubyte * textureBitmap = (GLubyte *)malloc(target_height*target_width*sizeof(GLubyte)*4);

  int offs;
  for (int j=0; j<target_height; j++)
    for (int i=0; i<target_width; i++) {
      offs=sub2indC(j,i,target_width,1);
      for (int k=0; k<4; k++) {
	tetxureBitmap[offs+k]=(GLubyte) target_bitmap[offs];
      }
    }
  
  // create texture from bitmap


  FT_Done_Face    ( face );
  FT_Done_FreeType( library );

  free(target_bitmap);
  free(textureBitmap);

  
#endif 


}

