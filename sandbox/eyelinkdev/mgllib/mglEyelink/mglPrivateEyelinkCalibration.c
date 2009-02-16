#ifdef documentation
=========================================================================
program: mglPrivateEyelinkCalibration.c
by:      eric dewitt and eli merriam
date:    02/08/09
copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
purpose: Sets the eyetracker into setup mode for calibration, validation
         and drift correction. Allows for mgl based (local) calibration 
         and eyelink software (remote, on eyelink computer) based setup.
         Local setup allows for self calibration. Wrapper handles keyboard.
         You must specify display location for the camera graphics.
usage:   mglPrivateEyelinkCalibration([display_num])

=========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
#include "../mgl.h"
#include <eyelink.h>
#include <core_expt.h>


// declarations -- coule be in header
void ELCALLBACK clear_cal_display(void);
INT16  ELCALLBACK setup_cal_display(void);
void ELCALLBACK exit_cal_display(void);
INT16 ELCALLBACK setup_image_display(INT16 width, INT16 height);
void ELCALLBACK image_title(INT16 threshold, char *cam_name);
void ELCALLBACK draw_image_line(INT16 width, INT16 line, INT16 totlines, byte *pixels);
void ELCALLBACK set_image_palette(INT16 ncolors, byte r[130], byte g[130], byte b[130]);
void ELCALLBACK exit_image_display(void);
void ELCALLBACK erase_cal_target(void);
void ELCALLBACK draw_cal_target(INT16 x, INT16 y);
void ELCALLBACK cal_target_beep(void);
void ELCALLBACK dc_done_beep(INT16 error);
void ELCALLBACK dc_target_beep(void);
void ELCALLBACK cal_done_beep(INT16 error);
INT16 ELCALLBACK get_input_key(InputEvent *key_input);
void ELCALLTYPE get_display_information(DISPLAYINFO *di);
INT16 ELCALLTYPE init_expt_graphics();

// draws a line from (x1,y1) to (x2,y2) - required for all tracker versions.
void drawLine(CrossHairInfo *chi, int x1, int y1, int x2, int y2, int cindex);

// draws shap that has semi-circle on either side and connected by lines.
// Bounded by x,y,width,height. x,y may be negative.
// This only needed for EL1000.
void drawLozenge(CrossHairInfo *chi, int x, int y, int width, int height, int cindex);

// Returns the current mouse position and its state. only neede for EL1000.
void getMouseState(CrossHairInfo *chi, int *rx, int *ry, int *rstate);

// int ELCALLBACK writeImage(char *outfilename, int format, EYEBITMAP *bitmap);

// library variables (would be class member vars)
GLuint glCameraImageTextureNumber;          // Texture for camera image display
GLuint glCameraTitleTextureNumber;          // Texture for camera title display
GLubyte *glCameraImage;                     // Camera image texture contents
static UINT32 cameraImagePalleteMap[130+2]; // Camera image pallete mapping
mxArray* mglTexture[2];                     // mgl texture structures
char cameraTitle[1024];                     // current camera title
int mglDisplayNum;                          // which mgl display are we using

/////////////
//   main   //
//////////////

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    if (nrhs>2) /* What arguments should this take? */
    {
        usageError("mglPrivateEyelinkCalibration");
        return;
    }
    
    if (nrhs>=1) {
       mexPrintf("(mglPrivateEyelinkCalibration) Attempting to use specific display.\n"); 
       n = mxGetN(prhs[0])*mxGetM(prhs[0]);
       if (n != 1) {
         mexErrMsgTxt("(mglPrivateEyelinkCalibration) You must specify a single display number.");
       }
       mglDisplayNum = (int)*(double*)mxGetPr(prhs[0]);
       mexPrintf("(mglPrivateEyelinkCalibrate) Attempting to use display %d.\n");
       mexPrintf("(mglPrivateEyelinkCalibrate) [Currently reverting to current display.]\n");
    }
    
    if (nrhs==2) {
        // get default mode for this round
    }
    
    // initialize the callbacks
    init_expt_graphics();

    // this handles all the actual calibration routines
    // we need to be able to pass in a variable to push the system into
    // calibrate, validate, or drift_correct
    // NOTE: Display and keyboard handling is done via callbacks--this function
    //       does not exit until the exit setup button has been pressed on the
    //       eyelink (or via key/message sent to the device)
    do_tracker_setup();

    // let everyone know that we're finished
    mexPrintf("(mglPrivateEyelinkCalibrate) finished...\n");
    
}

/*!
  This is an optional function to get information 
  on video driver and current mode use this to determine 
  if in proper mode for experiment.

  @param[out] di  A valid pointer to DISPLAYINFO is passed in to return values.
  @remark The prototype of this function can be changed to match one's need or
  if it is not necessary, one can choose not to implement this function also.

 */
void ELCALLTYPE get_display_information(DISPLAYINFO *di)
{
  /*
  1. detect the current display mode
  2. fill in values into di
  */
  memset(di,0, sizeof(DISPLAYINFO)); // clear everything to 0
  
  if (mglIsGlobal("screenWidth")) {
      di->width = (int)mglGetGlobalDouble("screenWidth");
  } else {
      mexErrMsgTxt("MGL must be initialised.");
  }
  
  if (mglIsGlobal("screenHeight")) {
      di->height = (int)mglGetGlobalDouble("screenHeight");
  } else {
      mexErrMsgTxt("MGL must be initialised.");
  }

  if (mglIsGlobal("bitDepth")) {
      di->bits = (int)mglGetGlobalDouble("bitDepth");
  } else {
      mexErrMsgTxt("MGL must be initialised.");
  }

  if (mglIsGlobal("frameRate")) {
      di->refresh = (int)mglGetGlobalDouble("frameRate");
  } else {
      mexErrMsgTxt("MGL must be initialised.");
  }
  
}

/*!

  This is an optional function to initialze graphics and calibration system.
  Although, this is optional, one should do the innerds of this function
  elsewhere in a proper manner.
  
   @remark The prototype of this function can be modified to suit ones needs.
  Eg. The init_expt_graphics of eyelink_core_graphics.dll takes in 2
  parameters.
  
*/
INT16 ELCALLTYPE init_expt_graphics()
{
  HOOKFCNS fcns;
  memset(&fcns,0,sizeof(fcns)); /* clear the memory */

  /* setup the values for HOOKFCNS */
  fcns.setup_cal_display_hook = setup_cal_display;
  fcns.exit_cal_display_hook  = exit_cal_display;
  fcns.setup_image_display_hook = setup_image_display;
  fcns.image_title_hook       = image_title;
  fcns.draw_image_line_hook   = draw_image_line;
  fcns.set_image_palette_hook = set_image_palette;
  fcns.exit_image_display_hook= exit_image_display;
  fcns.clear_cal_display_hook = clear_cal_display;
  fcns.erase_cal_target_hook  = erase_cal_target;
  fcns.draw_cal_target_hook   = draw_cal_target;
  fcns.cal_target_beep_hook   = cal_target_beep;
  fcns.cal_done_beep_hook     = cal_done_beep;
  fcns.dc_done_beep_hook      = dc_done_beep;
  fcns.dc_target_beep_hook    = dc_target_beep;
  fcns.get_input_key_hook     = get_input_key;


  /* register the call back functions with eyelink_core library */
  setup_graphic_hook_functions(&fcns);

  /* register the write image function */
  // set_write_image_hook(writeImage,0);

  /*
  	1. initalize graphics
  	2. if graphics initalization suceeds, return 0 otherewise return 1.
  */

  return 0;
}

/*!
  This is an optional function to properly close and release any resources
  that are not required beyond calibration needs.
  @remark the prototype of this function can be modified to suit ones need.
 */
void ELCALLTYPE close_expt_graphics()
{
	
}

/*!
	This is called to check for keyboard input. 
	In this function:
	\arg check if there are any input events
	\arg if there are input events, fill key_input and return 1.
		 otherwise return 0. If 1 is returned this will be called
	     again to check for more events.
	@param[out] key_input  fill in the InputEvent structure to return
		 key,modifier values.
	@return if there is a key, return 1 otherwise return 0.
*/

INT16 ELCALLBACK get_input_key(InputEvent *key_input)
{
	
	return 0;
}

/*!
	This function provides support to writing images to disk. Upon calls to el_bitmap_save_and_backdrop or
	el_bitmap_save this function is requested to do the write operaiton in the preferred format.

	@param[in] outfilename Name of the file to be saved.
	@param[in] format  format to be saved as.
	@param[in] bitmap bitmap data to be saved.
	@return if successful, return 0.
*/
int ELCALLBACK writeImage(char *outfilename, IMAGETYPE format, EYEBITMAP *bitmap)
{

 return 0;
}

/*! 
	Setup the calibration display. This function called before any
	calibration routines are called.
*/
INT16  ELCALLBACK  setup_cal_display(void)
{
  return 0;
}

/*!
  This is called to release any resources that are not required beyond calibration.
  Beyond this call, no calibration functions will be called.
 */
void ELCALLBACK exit_cal_display(void)
{

}

/*!
  This function is responsible for the drawing of the target for calibration,validation
  and drift correct at the given coordinate.
  @param x x coordinate of the target.
  @param y y coordinate of the target.
  @remark The x and y are relative to what is sent to the tracker for the command screen_pixel_coords.
 */
void ELCALLBACK  draw_cal_target(INT16 x, INT16 y)
{    
      mxArray *callInput[4];
      double *inX;
      double *inY;
      double *inSize;
      double *inColor;
      
      callInput[0] = mxCreateDoubleMatrix(1,1,mxREAL);
      callInput[1] = mxCreateDoubleMatrix(1,1,mxREAL);
      callInput[2] = mxCreateDoubleMatrix(1,1,mxREAL);
      callInput[3] = mxCreateDoubleMatrix(1,3,mxREAL);
      inX = (double*)mxGetPr(callInput[0]);
      inY = (double*)mxGetPr(callInput[1]);
      inSize = (double*)mxGetPr(callInput[2]);
      inColor = (double*)mxGetPr(callInput[3]);
      *inX = (double)x;
      *inY = (double)y;
      *inSize = 20; // in pixels for now
      inColor[0] = 0.7; // red
      inColor[1] = 0.7; // green
      inColor[2] = 0.7; // blue
      
      
      mexCallMATLAB(0,NULL,4,callInput,"mglGluDisk");            
      //mglGluDisk(xDeg, yDeg, targetSize, targetcolor);
      mexCallMATLAB(0,NULL,0,NULL,"mglFlush");
}

/*!
	This function is responsible for erasing the target that was drawn by the last call to draw_cal_target.
*/
void ELCALLBACK erase_cal_target(void)
{
	/* erase the last calibration target  */
    mexCallMATLAB(0,NULL,0,NULL,"mglClearScreen");
    mexCallMATLAB(0,NULL,0,NULL,"mglFlush");
}

#define CAL_TARG_BEEP   1
#define CAL_GOOD_BEEP   0
#define CAL_ERR_BEEP   -1
#define DC_TARG_BEEP    3
#define DC_GOOD_BEEP    2
#define DC_ERR_BEEP    -2
/*!
	In most cases on can implement all four (cal_target_beep,cal_done_beep,dc_target_beep,dc_done_beep)
	beep callbacks using just one function.  
	
	This function is responsible for selecting and playing the audio clip.
	@param sound sound id to play.
 */
void ELCALLBACK  cal_sound(INT16 sound)
{
    char *wave =NULL;
    switch(sound) // select the appropriate sound to play
    {
        case CAL_TARG_BEEP: /* play cal target beep */
        wave ="Tink";
        break;
        case CAL_GOOD_BEEP: /* play cal good beep */
        wave ="Purr";
        break;
        case CAL_ERR_BEEP:  /* play cal error beep */
        wave ="Funk";
        break;
        case DC_TARG_BEEP:  /* play drift correct target beep */
        wave ="Hero";
        break;
        case DC_GOOD_BEEP:  /* play drift correct good beep */
        wave ="Morse";
        break;
        case DC_ERR_BEEP:  /* play drift correct error beep */
        wave ="Sosumi";
        break;
    }
    if(wave)
    {
        mxArray *sound[1];
        sound[0] = mxCreateString(wave);
        mexCallMATLAB(0,NULL,1,sound,"mglPlaySound");
    }
}

/*!
 This function is called to signal new target.
 */
void ELCALLBACK cal_target_beep(void)
{
	cal_sound(CAL_TARG_BEEP);
}

/*!
  This function is called to signal end of calibration.
  @param error if non zero, then the calibration has error.
 */
void ELCALLBACK cal_done_beep(INT16 error)
{
if(error)
    {
      cal_sound(CAL_ERR_BEEP);
    }
  else
    {
      cal_sound(CAL_GOOD_BEEP);
    }
}

/*!
  This function is called to signal a new drift correct target.
 */
void ELCALLBACK dc_target_beep(void)
{
	cal_sound(DC_TARG_BEEP);
}

/*
  This function is called to singnal the end of drift correct. 
  @param error if non zero, then the drift correction failed.
 */
void ELCALLBACK dc_done_beep(INT16 error)
{
 if(error)
    {
      cal_sound(DC_ERR_BEEP);
    }
  else
    {
      cal_sound(DC_GOOD_BEEP);
    }
}

/*
  Called to clear the display.
 */
void ELCALLBACK clear_cal_display(void)
{
    mexCallMATLAB(0,NULL,0,NULL,"mglClearScreen");
    mexCallMATLAB(0,NULL,0,NULL,"mglFlush");
   
}

#define BYTEDEPTH 4
#define TEXTURE_DATATYPE GL_UNSIGNED_BYTE // Independent of endianness
/*!
	This function is responsible for initializing any resources that are 
	required for camera setup.
	
	@param width width of the source image to expect.
	@param height height of the source image to expect.
	@return -1 if failed,  0 otherwise.
 */
INT16 ELCALLBACK setup_image_display(INT16 width, INT16 height)
{
    // a bit of a hack, but this will be the easiest way to not duplicate
    // code see the note in the mgllib developers.txt file.
    
    // get an array of the correct size for the image
    mwSize ndims = 3, dims[3] = {height, width, 4};
    mxArray* camArray[1];
    camArray[0] = mxCreateNumericArray(ndims, dims, mxDOUBLE_CLASS, mxReal);
    glCameraImage = (GLubyte*)malloc(width*height*sizeof(GLubyte)*BYTEDEPTH);
    
    
    // create an mgl texture
    mexCallMATLAB(1, mglTexture[0], 1, camArray, "mglPrivateCreateTexture");
    mxDestroyArray(camArray);
    cameraTitle = "IMAGE";
    mexCallMATLAB(1, mglTexture[1], 1, mxCreateString(cameraTitle), "mglPrivateCreateTexture");
    
    // get the texture number for the camera texture
    glCameraImageTextureNumber = (int)*mxGetPr(mxGetField(mglTexture[0],0,"textureNumber"));
    glCameraImageTextureNumber = (int)*mxGetPr(mxGetField(mglTexture[1],0,"textureNumber"));
    
    glBindTexture(GL_TEXTURE_2D, glCameraImageTextureNumber);
    glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, TEXTURE_DATATYPE, glCameraImage);
    
    return 0;
}

/*!
	This is called to notify that all camera setup things are complete.  Any
	resources that are allocated in setup_image_display can be released in this
	function.
*/
void ELCALLBACK exit_image_display(void)
{
    // clean up matlab/mgl textures
    mexCallMATLAB(1, mglTexture[0], 1, camArray, "mglPrivateDeleteTexture");
    mexCallMATLAB(1, mglTexture[1], 1, camArray, "mglPrivateDeleteTexture");
    // cleanup our local texture
    free(glCameraImage);    
}

/*!
  This function is called to update any image title change.
  @param threshold if -1 the entire tile is in the title string
				   otherwise, the threshold of the current image.
  @param title     if threshold is -1, the title contains the whole title 
				   for the image. Otherwise only the camera name is given.
 */
void ELCALLBACK image_title(INT16 threshold, char *title)
{
    // printf("this is a very slow way to do re-titling.");
    mexCallMATLAB(1, mglTexture[1], 1, camArray, "mglPrivateDeleteTexture");
    if (threshold == -1){
        snprintf(cameraTitle, sizeof(cameraTitle), "%s", title);
    } else {
        snprintf(cameraTitle, sizeof(cameraTitle), "%s, threshold at %d", threshold);
    }
    mexCallMATLAB(1, mglTexture[1], 1, mxCreateString(cameraTitle), "mglPrivateCreateTexture");
}

/*!
	This function is called after setup_image_display and before the first call to 
	draw_image_line. This is responsible to setup the palettes to display the camera
	image.

    @param ncolors number of colors in the palette.
	@param r       red component of rgb.
	@param g       blue component of rgb.
	@param b       green component of rgb.
	
*/
void ELCALLBACK set_image_palette(INT16 ncolors, byte r[130], byte g[130], byte b[130])
{

    int i = 0; 
    for(i=0; i<ncolors; i++) 
    { 
        UINT32 rf = r[i];
        UINT32 gf = g[i];
        UINT32 bf = b[i];
        // we will have an rgba palette setup. 
        cameraImagePalleteMap[i] = (rf<<16) | (gf<<8) | (bf);
    } 

}

/*!
	This function is called to supply the image line by line from top to bottom.
	@param width  width of the picture. Essentially, number of bytes in \c pixels.
	@param line   current line of the image
	@param totlines total number of lines in the image. This will always equal the height of the image.
	@param pixels pixel data.

    Eg. Say we want to extract pixel at position (20,20) and print it out as rgb values.  

	@code
    if(line == 19) // y = 20
	{
		byte pix = pixels[19];
		// Note the r,g,b arrays come from the call to set_image_palette
		printf("RGB %d %d %d\n",r[pix],g[pix],b[pix]); 
	}
	@endcode

	@remark certain display draw the image up side down. eg. GDI.
*/
void ELCALLBACK draw_image_line(INT16 width, INT16 line, INT16 totlines, byte *pixels)
{
    //     else if (imageType == 3) {    
    //       for(i = 0; i < imageHeight; i++) { 
    //         for(j = 0; j < imageWidth;j++,c+=BYTEDEPTH) {
    // imageFormatted[c+0] = (GLubyte)imageData[sub2ind( i, j, imageHeight, 1 )];
    // imageFormatted[c+1] = (GLubyte)imageData[sub2ind( i, j, imageHeight, 1 )+imageWidth*imageHeight];
    // imageFormatted[c+2] = (GLubyte)imageData[sub2ind( i, j, imageHeight, 1 )+imageWidth*imageHeight*2];
    // imageFormatted[c+3] = (GLubyte)255;
    //         }
    //       }
    //     }
//    glCameraImage set image texture

    short i;
    UINT32 *v0;
    GLubyte *p = pixels;

    glBindTexture(GL_TEXTURE_2D, glCameraImageTextureNumber);
    glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, TEXTURE_DATATYPE, glCameraImage);
    glBindTexture(GL_TEXTURE_2D, glCameraImageTextureNumber);
    glTexImage2D(GL_TEXTURE_RECTANGLE_EXT,0,GL_RGBA,width,imageHeight,0,GL_RGBA,TEXTURE_DATATYPE,glCameraImage);


    v0 = (UINT32 *)(((GLubyte*)image->pixels) + ((line-1)*()));
    for(i=0; i<width; i++)
    {
        *v0++ = image_palmap32[*p++]; // copy the line to image
    }
    if(line == totlines)
    {
        // at this point we have a complete camera image. This may be very small.
        // we might want to enlarge it. For simplicity reasons, we will skip that.

    // center the camera image on the screen
    // SDL_Rect r = {(mainWindow->w-image->w)/2,(mainWindow->h-image->h)/2,0,0};
    // mgl blt texture

    // now we need to draw the cursors.

        CrossHairInfo crossHairInfo;
        memset(&crossHairInfo,0,sizeof(crossHairInfo));

        crossHairInfo.w = image->w;
        crossHairInfo.h = image->h;
        crossHairInfo.drawLozenge = drawLozenge;
        crossHairInfo.drawLine = drawLine;
        crossHairInfo.getMouseState = getMouseState;
        crossHairInfo.userdata = image;

        eyelink_draw_cross_hair(&crossHairInfo);
    }

}


/*!
	@ingroup cam_example
	draws a line from (x1,y1) to (x2,y2) - required for all tracker versions.
*/
void drawLine(CrossHairInfo *chi, int x1, int y1, int x2, int y2, int cindex)
{
    SDL_Rect r;
    UINT32 color =0;
    SDL_Surface *img = (SDL_Surface *)(chi->userdata);
    switch(cindex)
    {
        case CR_HAIR_COLOR:
        case PUPIL_HAIR_COLOR:
            // color = SDL_MapRGB(img->format,255,255,255);
        printf("Add Parse Color\n");
        break;
        case PUPIL_BOX_COLOR:
            // color = SDL_MapRGB(img->format,0,255,0);
        printf("Add Parse Color\n");
        break;
        case SEARCH_LIMIT_BOX_COLOR:
        case MOUSE_CURSOR_COLOR:
            // color = SDL_MapRGB(img->format,255,0,0);
        printf("Add Parse Color\n");
        break;
    }
	mglLines(x0, y0, x1, y1,size,color,bgcolor)
  if(x1 == x2) // vertical line
  {
	  if(y1 < y2)
	  {
		  r.x = x1;
		  r.y = y1;
		  r.w = 1;
		  r.h = y2-y1;
	  }
	  else
	  {
		  r.x = x2;
		  r.y = y2;
		  r.w = 1;
		  r.h = y1-y2;
	  }
	  SDL_FillRect(img,&r,color);
  }
  else if(y1 == y2) // horizontal line.
  {
	  if(x1 < x2)
	  {
		  r.x = x1;
		  r.y = y1;
		  r.w = x2-x1;
		  r.h = 1;
	  }
	  else
	  {
		  r.x = x2;
		  r.y = y2;
		  r.w = x1-x2;
		  r.h = 1;
	  }
	  SDL_FillRect(img,&r,color);
  }
  else
  {
	printf("non horizontal/vertical lines not implemented. \n");
  }
}

/*!
	@ingroup cam_example
	draws shap that has semi-circle on either side and connected by lines.
	Bounded by x,y,width,height. x,y may be negative.
	@remark This is only needed for EL1000.	
*/
void drawLozenge(CrossHairInfo *chi, int x, int y, int width, int height, int cindex)
{
	// NOT IMPLEMENTED.
	printf("drawLozenge not implemented. \n");
}

/*!
	@ingroup cam_example
	Returns the current mouse position and its state.
	@remark This is only needed for EL1000.	
*/
void getMouseState(CrossHairInfo *chi, int *rx, int *ry, int *rstate)
{
    // NOT IMPLEMENTED.
    printf("drawLozenge not implemented. \n");

//   int x =0;
//   int y =0;
//   Uint8 state =SDL_GetMouseState(&x,&y);
//   x = x-(mainWindow->w - ((SDL_Surface*)chi->userdata)->w)/2;
//   y = y-(mainWindow->h - ((SDL_Surface*)chi->userdata)->h)/2;
//   if(x>=0 && y >=0 && x <=((SDL_Surface*)chi->userdata)->w && y <= ((SDL_Surface*)chi->userdata)->h)
//   {
//     *rx = x;
// *ry = y;
// *rstate = state;
//   }
}
