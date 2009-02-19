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
mxArray *mglTexture[1];                     // mgl texture structures
mxArray *mglTextureLoc[1];                  // texture location
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
        int n;
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

// Below are the key code defines to be passed for all non-ascii chars

// The following are defined in <core_expt.h>
// #define CURS_UP    0x4800    /*!< Cursor up key.*/
// #define CURS_DOWN  0x5000    /*!< Cursor down key.*/
// #define CURS_LEFT  0x4B00    /*!< Cursor left key.*/
// #define CURS_RIGHT 0x4D00    /*!< Cursor right key.*/
// 
// #define ESC_KEY   0x001B     /*!< Escape key.*/
// #define ENTER_KEY 0x000D     /*!< Return key.*/
// 
// #define PAGE_UP   0x4900     /*!< Page up key.*/
// #define PAGE_DOWN 0x5100     /*!< Page down key.*/
// #define JUNK_KEY      1      /*!< Junk key to indicate untranslatable key.*/ 
// #define TERMINATE_KEY 0x7FFF /*!< Returned by getkey if program should exit.*/

// other keycode defines
#define F1_KEY    0x3B00
#define F2_KEY    0x3C00
#define F3_KEY    0x3D00
#define F4_KEY    0x3E00
#define F5_KEY    0x3F00
#define F6_KEY    0x4000
#define F7_KEY    0x4100
#define F8_KEY    0x4200
#define F9_KEY    0x4300
#define F10_KEY   0x4400

// #define ELKMOD_NONE   0x0000
// #define ELKMOD_LSHIFT 0x0001
// #define ELKMOD_RSHIFT 0x0002
// #define ELKMOD_LCTRL  0x0040
// #define ELKMOD_RCTRL  0x0080
// #define ELKMOD_LALT   0x0100
// #define ELKMOD_RALT   0x0200
// #define ELKMOD_LMETA  0x0400
// #define ELKMOD_RMETA  0x0800,
// #define ELKMOD_NUM    0x1000
// #define ELKMOD_CAPS   0x2000
// #define ELKMOD_MODE   0x4000

#define KEYDOWN 0
#define KEYUP 1

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
    mxArray *callOutput[1];

    // get a key event using the get key event.
    // mglGetKeyEvent()
    mexCallMATLAB(1,callOutput,0,NULL,"mglGetKeyEvent");            
    if (mxIsEmpty(callOutput[0])) {
        return 0;        
    }
    else {
        // parse key and place in *key_input
        UINT16 charcode = 0, modcode = 0; // the key (ascii)
        UINT16 keycode = 0;    // the key (mgl code)
        char *charbuff;
        // get modifiers
        int shift, control, command, alt, capslock;

        // get the key event
        charbuff = mxArrayToString(mxGetField(callOutput[0],0,"charCode"));
        charcode = (UINT16)charbuff[0];
        keycode = (UINT16)*(double*)mxGetPr(mxGetField(callOutput[0],0,"keyCode"));
        shift = (int)*(double*)mxGetPr(mxGetField(callOutput[0],0,"shift"));
        control = (int)*(double*)mxGetPr(mxGetField(callOutput[0],0,"control"));
        capslock = (int)*(double*)mxGetPr(mxGetField(callOutput[0],0,"capslock"));
        alt = (int)*(double*)mxGetPr(mxGetField(callOutput[0],0,"alt"));

        mexPrintf("c %d (%.1s) k %d shift %d cntr %d caps %d alt %d\n", charcode,
            charbuff, keycode, shift, control, capslock, alt);

        if (shift)
            modcode = (modcode | ELKMOD_LSHIFT | ELKMOD_RSHIFT);
        if (control)
            modcode = (modcode | ELKMOD_LCTRL | ELKMOD_RCTRL);
        if (alt)
            modcode = (modcode | ELKMOD_LALT | ELKMOD_RALT);
        if (capslock)
            modcode = (modcode | ELKMOD_CAPS);

        if (charcode>=20 && charcode <=127) {
            key_input->key.key = (char)charcode;
        } else {
            switch (keycode) {
                case 100:
                key_input->key.key = F1_KEY;
                break;
                case 123:
                key_input->key.key = F2_KEY;
                break;
                case 121:
                key_input->key.key = F3_KEY;
                break;
                case 119:
                key_input->key.key = F4_KEY;
                break;
                case 97:
                key_input->key.key = F5_KEY;
                break;
                case 98:
                key_input->key.key = F6_KEY;
                break;
                case 99:
                key_input->key.key = F7_KEY;
                break;
                case 101:
                key_input->key.key = F8_KEY;
                break;
                case 102:
                key_input->key.key = F9_KEY;
                break;
                case 110:
                key_input->key.key = F10_KEY;
                break;
                case 127:
                key_input->key.key = CURS_UP;
                break;
                case 126:
                key_input->key.key = CURS_DOWN;
                break;
                case 124:
                key_input->key.key = CURS_LEFT;
                break;
                case 125:
                key_input->key.key = CURS_RIGHT;
                break;
                case 54:
                key_input->key.key = ESC_KEY;
                break;
                case 37:
                key_input->key.key = ENTER_KEY;
                break;
                case 117:
                key_input->key.key = PAGE_UP;
                break;
                case 122:
                key_input->key.key = PAGE_DOWN;
                break;
                  // case 000:
                  // key_input->key.key = TERMINATE_KEY; // what should this be?
                  // break;
                default:
                key_input->key.key = JUNK_KEY;
            }
        }
        key_input->key.modifier = modcode;
        key_input->key.state = KEYUP;
        key_input->key.type = KEYINPUT_EVENT;
        key_input->type = KEYINPUT_EVENT;
        mexPrintf("InputEvent->type %d\nInputEvent->key.key %d\nInputEvent->key.modifier %d\n"
        "InputEvent->key.state %d\nInputEvent->key.type %d\n", key_input->type, key_input->key.key,
        key_input->key.modifier, key_input->key.state, key_input->key.type);
        return 1;
    }
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
      
      
      mexCallMATLAB(0, NULL, 4, callInput, "mglGluDisk");            
      //mglGluDisk(xDeg, yDeg, targetSize, targetcolor);
      mexCallMATLAB(0, NULL, 0, NULL, "mglFlush");
}

/*!
	This function is responsible for erasing the target that was drawn by the last call to draw_cal_target.
*/
void ELCALLBACK erase_cal_target(void)
{
	/* erase the last calibration target  */
    mexCallMATLAB(0, NULL, 0, NULL, "mglClearScreen");
    mexCallMATLAB(0, NULL, 0, NULL, "mglFlush");
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
        mexCallMATLAB(0, NULL, 1, sound, "mglPlaySound");
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
    mexCallMATLAB(0, NULL, 0, NULL, "mglClearScreen");
    mexCallMATLAB(0, NULL, 0, NULL, "mglFlush");
   
}

#define BYTEDEPTH 4 // MUST be 4 for now--or we'd have to change a bunch of code
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
    mxArray *camArray[1];
    camArray[0] = mxCreateNumericArray(ndims, dims, mxDOUBLE_CLASS, mxREAL);
    glCameraImage = (GLubyte*)malloc(width*height*sizeof(GLubyte)*BYTEDEPTH);
    
    // create an mgl texture
    mxArray *texI[1], *texT[1], *tex[2];
    mexCallMATLAB(1, texI, 1, camArray, "mglCreateTexture");
    mxDestroyArray(camArray[0]);
    snprintf(cameraTitle, sizeof(cameraTitle), "%s","IMAGE");
    mxArray *title[1];
    title[0] = mxCreateString(cameraTitle);
    mexCallMATLAB(1, texT, 1, title, "mglText");
    
    tex[0] = texI[1];
    tex[1] = texT[1];
    mexCallMATLAB(1, mglTexture, 2, tex, "vertcat");
    mglTextureLoc[0] = mxCreateDoubleMatrix(1, 2, mxREAL);
    double *loc = (double*)mxGetPr(mglTextureLoc[0]);
    loc[0] = 0; // x
    loc[1] = 0; // y
    
    // get the texture number for the camera texture
    glCameraImageTextureNumber = (int)*mxGetPr(mxGetField(mglTexture[0],0,"textureNumber"));
    glCameraImageTextureNumber = (int)*mxGetPr(mxGetField(mglTexture[0],1,"textureNumber"));
    
    #ifndef GL_TEXTURE_RECTANGLE_EXT
    printf("ERROR: GL requires ^2 on this system and is unhandled by this code.\n")
    #endif
    
    glBindTexture(GL_TEXTURE_2D, glCameraImageTextureNumber);
    glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, TEXTURE_DATATYPE, glCameraImage);
    
    mexCallMATLAB(0,NULL,0,NULL,"mglClearScreen");
    mexCallMATLAB(0,NULL,0,NULL,"mglFlush");
        
    
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
    // mexCallMATLAB(1, mglTexture[0], 1, camArray, "mglPrivateDeleteTexture");
    // mexCallMATLAB(1, mglTexture[1], 1, camArray, "mglPrivateDeleteTexture");
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
    // mexCallMATLAB(1, mglTexture[1], 1, camArray, "mglPrivateDeleteTexture");
    // if (threshold == -1){
    //     snprintf(cameraTitle, sizeof(cameraTitle), "%s", title);
    // } else {
    //     snprintf(cameraTitle, sizeof(cameraTitle), "%s, threshold at %d", threshold);
    // }
    // mexCallMATLAB(1, mglTexture[1], 1, mxCreateString(cameraTitle), "mglCreateTexture");
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
    
    // short i;
    // UINT32 *currentLine;    // we will write rgba at once as a packed pixel
    // // byte *p = pixels;       // a packed rgba lookup
    // 
    // // get the beginning of the current line
    // currentLine = (UINT32*)glCameraImage+((line-1)*sizeof(GLubyte)*BYTEDEPTH*width);
    // 
    // for(i=0; i<width; i++)
    // {
    //     *currentLine++ = cameraImagePalleteMap[*pixels++]; // copy the line to image
    // }
    // if(line == totlines)
    // {
    //     // at this point we have a complete camera image. This may be very small.
    //     // we might want to enlarge it. For simplicity reasons, we will skip that.
    // 
    //     // center the camera image on the screen
    //     glBindTexture(GL_TEXTURE_2D, glCameraImageTextureNumber);
    //     glTexImage2D(GL_TEXTURE_RECTANGLE_EXT,0,GL_RGBA,width,totlines,0,
    //         GL_RGBA,TEXTURE_DATATYPE,glCameraImage);
    //     mxArray *bltTextureRHS[2];
    //     bltTextureRHS[0] = mglTexture[0];
    //     bltTextureRHS[1] = mglTextureLoc[0];
    //     mexCallMATLAB(0, NULL, 2, bltTextureRHS, "mglBltTexture");
    //     mexCallMATLAB(0, NULL, 0, NULL,"mglFlush");
    //     
    //     // now we need to draw the cursors.
    // 
    //     CrossHairInfo crossHairInfo;
    //     memset(&crossHairInfo,0,sizeof(crossHairInfo));
    //     
    //     crossHairInfo.w = width;
    //     crossHairInfo.h = totlines;
    //     crossHairInfo.drawLozenge = drawLozenge;
    //     crossHairInfo.drawLine = drawLine;
    //     crossHairInfo.getMouseState = getMouseState;
    //     // crossHairInfo.userdata = image; // could be used for gl display num
    //     
    //     eyelink_draw_cross_hair(&crossHairInfo);
    //     
    // }

}


/*!
	@ingroup cam_example
	draws a line from (x1,y1) to (x2,y2) - required for all tracker versions.
*/
void drawLine(CrossHairInfo *chi, int x1, int y1, int x2, int y2, int cindex)
{
    mxArray *callInput[6];
    double *inX1, *inX2;
    double *inY1, *inY2;
    double *inSize;
    double *inColor;

    callInput[0] = mxCreateDoubleMatrix(1,1,mxREAL);
    callInput[1] = mxCreateDoubleMatrix(1,1,mxREAL);
    callInput[2] = mxCreateDoubleMatrix(1,1,mxREAL);
    callInput[3] = mxCreateDoubleMatrix(1,1,mxREAL);
    callInput[4] = mxCreateDoubleMatrix(1,1,mxREAL);
    callInput[5] = mxCreateDoubleMatrix(1,3,mxREAL);
    *(double*)mxGetPr(callInput[0]) = x1;
    *(double*)mxGetPr(callInput[1]) = y1;
    *(double*)mxGetPr(callInput[2]) = x2;
    *(double*)mxGetPr(callInput[3]) = y2;
    inSize = (double*)mxGetPr(callInput[4]);
    inColor = (double*)mxGetPr(callInput[5]);
    *inSize = 2; // in pixels for now
    inColor[0] = 0;
    inColor[1] = 0;
    inColor[2] = 0;

    switch(cindex)
    {
        case CR_HAIR_COLOR:
        case PUPIL_HAIR_COLOR:
        inColor[0] = 1;
        inColor[1] = 1;
        inColor[2] = 1;
        break;
        case PUPIL_BOX_COLOR:
        inColor[0] = 0;
        inColor[1] = 1;
        inColor[2] = 0;
        break;
        case SEARCH_LIMIT_BOX_COLOR:
        case MOUSE_CURSOR_COLOR:
        inColor[0] = 1;
        inColor[1] = 0;
        inColor[2] = 0;
        break;
    }

    // mglLines(x0, y0, x1, y1,size,color,bgcolor)
    mexCallMATLAB(0,NULL,6,callInput,"mglLines");            

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
    printf("getMouseState not implemented. \n");

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
