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
#include "mglPrivateEyelinkCalibration.h"

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
        mglcDisplayNumber = (int)*(double*)mxGetPr(prhs[0]);
        mexPrintf("(mglPrivateEyelinkCalibrate) Attempting to use display %d.\n");
        mexPrintf("(mglPrivateEyelinkCalibrate) [Currently reverting to current display.]\n");
    } else {
        mglcDisplayNumber = (int)mglGetGlobalDouble("displayNumber");
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
    mxArray *callOutput[1], *tmpOut;

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
        int shift = 0, control = 0, command = 0, alt = 0, capslock = 0;

        // get the key event
        charbuff = mxArrayToString(mxGetField(callOutput[0],0,"charCode"));
        if (charbuff!=NULL)
            charcode = (UINT16)charbuff[0];
        else
            charcode = 0;
        mxFree(charbuff);
        keycode = (UINT16)*(double*)mxGetPr(mxGetField(callOutput[0],0,"keyCode"));
        tmpOut = mxGetField(callOutput[0],0,"shift");
        if (tmpOut!=NULL) {
            shift = (int)*(double*)mxGetPr(tmpOut);
            control = (int)*(double*)mxGetPr(mxGetField(callOutput[0],0,"control"));
            capslock = (int)*(double*)mxGetPr(mxGetField(callOutput[0],0,"capslock"));
            alt = (int)*(double*)mxGetPr(mxGetField(callOutput[0],0,"alt"));
        }

        // mexPrintf("c %d (%.1s) k %d shift %d cntr %d caps %d alt %d\n", charcode,
        //     charbuff, keycode, shift, control, capslock, alt);

        if (shift)
            modcode = (modcode | ELKMOD_LSHIFT | ELKMOD_RSHIFT);
        if (control)
            modcode = (modcode | ELKMOD_LCTRL | ELKMOD_RCTRL);
        if (alt)
            modcode = (modcode | ELKMOD_LALT | ELKMOD_RALT);
        if (capslock)
            modcode = (modcode | ELKMOD_CAPS);

        if (charcode>=33 && charcode <=127) {
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
        // mexPrintf("InputEvent->type %d\nInputEvent->key.key %d\nInputEvent->key.modifier %d\n"
        // "InputEvent->key.state %d\nInputEvent->key.type %d\n", key_input->type, key_input->key.key,
        // key_input->key.modifier, key_input->key.state, key_input->key.type);
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
INT16 ELCALLBACK setup_cal_display(void)
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
void ELCALLBACK draw_cal_target(INT16 x, INT16 y)
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
      mglcFlush(mglcDisplayNumber);
      mexPrintf("mglPrivateEyelinkCalibrate) draw_cal_target");
}

/*!
	This function is responsible for erasing the target that was drawn by the last call to draw_cal_target.
*/
void ELCALLBACK erase_cal_target(void)
{
	/* erase the last calibration target  */
    mglcClearScreen(NULL);
    mglcFlush(mglcDisplayNumber);
}

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
    mglcClearScreen(NULL);
    mglcFlush(mglcDisplayNumber);
   
}

/*!
	This function is responsible for initializing any resources that are 
	required for camera setup.
	
	@param width width of the source image to expect.
	@param height height of the source image to expect.
	@return -1 if failed,  0 otherwise.
 */
INT16 ELCALLBACK setup_image_display(INT16 width, INT16 height)
{
    
    cameraPos[2] = width*2;
    cameraPos[3] = height*2;
    mgltCamera = mglcCreateRGBATexture(width, height);
    // mgltTitle = mglcCreateTextTexture("Title");    
    mglcClearScreen(NULL);
    mglcFlush(mglcDisplayNumber);
    
    return 0;
}

/*!
	This is called to notify that all camera setup things are complete.  Any
	resources that are allocated in setup_image_display can be released in this
	function.
*/
void ELCALLBACK exit_image_display(void)
{

    mglcFreeTexture(mgltCamera);
    // mglcFreeTexture(mgltTitle);
    
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

    if (threshold == -1){
        snprintf(cameraTitle, sizeof(cameraTitle), "%s", title);
    } else {
        snprintf(cameraTitle, sizeof(cameraTitle), "%s, threshold at %d", threshold);
    }
    // mexPrintf("Camera Title: %s\n", cameraTitle);
    // mglcFreeTexture(mgltTitle);
    // mgltTitle = mglcCreateTextTexture(cameraTitle);
    
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
        UINT32 alpha = 255;
#ifdef __LITTLE_ENDIAN__
        cameraImagePalleteMap[i] = (alpha<<24) | (rf<<16) | (gf<<8) | (bf);
#else
        cameraImagePalleteMap[i] = (rf<<24) | (gf<<16) | (bf<<8) | (alpha);
#endif
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
    
    short i;
    UINT32 *currentLine;    // we will write rgba at once as a packed pixel
    byte *p = pixels;       // a packed rgba lookup
    
    // mexPrintf("(mglPrivateEyelinkCalibrate) width %d, line %d, height %d\n", width, line, totlines);
    
    // get the beginning of the current line
    currentLine = (UINT32*)(((GLubyte*)(mgltCamera->pixels))+((line-1)*sizeof(GLubyte)*BYTEDEPTH*width));
    
    for(i=0; i<width; i++)
    {
        *currentLine++ = cameraImagePalleteMap[*p++]; // copy the line to image
    }
    if(line == totlines)
    {
        // at this point we have a complete camera image. This may be very small.
        // we might want to enlarge it. For simplicity reasons, we will skip that.

        mglcClearScreen(NULL);

        // center the camera image on the screen
        glBindTexture(GL_TEXTURE_2D, mgltCamera->textureNumber);    
// #ifdef __APPLE__
//         // tell GL that the memory will be handled by us. (apple)
//         glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE,0);
//         // now, try to store the memory in VRAM (apple)
//         glTexParameteri(GL_TEXTURE_RECTANGLE_EXT,GL_TEXTURE_STORAGE_HINT_APPLE,GL_STORAGE_CACHED_APPLE);
//         glTextureRangeAPPLE(GL_TEXTURE_RECTANGLE_EXT,mgltCamera->imageWidth*mgltCamera->imageHeight*BYTEDEPTH,mgltCamera->pixels);
// #endif
        glTexImage2D(GL_TEXTURE_RECTANGLE_EXT,0,GL_RGBA,
            mgltCamera->imageWidth,mgltCamera->imageHeight,0,
            GL_RGBA,TEXTURE_DATATYPE,mgltCamera->pixels);  
                
        // mexPrintf("[Camera Texture]");
        mglcBltTexture(mgltCamera, cameraPos, ALIGNCENTER, ALIGNCENTER);
        // mexPrintf("[Title Texture]");
        // mglcBltTexture(mgltTitle, titlePos, ALIGNCENTER, ALIGNCENTER);
        
        mexPrintf("F %d\n", mglcFrameNumber++);
        
        // now we need to draw the cursors.
            
        CrossHairInfo crossHairInfo;
        memset(&crossHairInfo,0,sizeof(crossHairInfo));
        
        crossHairInfo.w = cameraPos[2];
        crossHairInfo.h = cameraPos[3];
        crossHairInfo.drawLozenge = drawLozenge;
        crossHairInfo.drawLine = drawLine;
        crossHairInfo.getMouseState = getMouseState;
        // crossHairInfo.userdata = image; // could be used for gl display num
        
        eyelink_draw_cross_hair(&crossHairInfo);

        mglcFlush(mglcDisplayNumber);

        
    }

}


/*!
	@ingroup cam_example
	draws a line from (x1,y1) to (x2,y2) - required for all tracker versions.
*/
void drawLine(CrossHairInfo *chi, int x1, int y1, int x2, int y2, int cindex)
{
    mxArray *callInput[6];
    double *inColor;

    callInput[0] = mxCreateDoubleMatrix(1,1,mxREAL);
    callInput[1] = mxCreateDoubleMatrix(1,1,mxREAL);
    callInput[2] = mxCreateDoubleMatrix(1,1,mxREAL);
    callInput[3] = mxCreateDoubleMatrix(1,1,mxREAL);
    callInput[4] = mxCreateDoubleMatrix(1,1,mxREAL);
    callInput[5] = mxCreateDoubleMatrix(1,3,mxREAL);
    *(double*)mxGetPr(callInput[0]) = x1 + cameraPos[0] - cameraPos[2]/2;
    *(double*)mxGetPr(callInput[1]) = y1 + cameraPos[1] - cameraPos[3]/2;
    *(double*)mxGetPr(callInput[2]) = x2 + cameraPos[0] - cameraPos[2]/2;
    *(double*)mxGetPr(callInput[3]) = y2 + cameraPos[1] - cameraPos[3]/2;
    *(double*)mxGetPr(callInput[4]) = 2;                // Size in pixels
    inColor = (double*)mxGetPr(callInput[5]);
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
    mexCallMATLAB(0,NULL,6,callInput,"mglLines2");            

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
    // printf("drawLozenge not implemented. \n");
}

/*!
	@ingroup cam_example
	Returns the current mouse position and its state.
	@remark This is only needed for EL1000.	
*/
void getMouseState(CrossHairInfo *chi, int *rx, int *ry, int *rstate)
{
    // NOT IMPLEMENTED.
    // printf("getMouseState not implemented. \n");

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


/*
    // declare some variables for dealing with alignment
    int hAlignment, vAlignment;
    hAlignment = DEFAULT_H_ALIGNMENT;
    vAlignment = DEFAULT_V_ALIGNMENT;
*/

void mglcBltTexture(MGLTexture *texture, int position[4], int hAlignment, int vAlignment)
{

    double xPixelsToDevice, yPixelsToDevice, deviceHDirection, deviceVDirection;

    xPixelsToDevice = mglGetGlobalDouble("xPixelsToDevice");
    yPixelsToDevice = mglGetGlobalDouble("yPixelsToDevice");
    deviceHDirection = mglGetGlobalDouble("deviceHDirection");
    deviceVDirection = mglGetGlobalDouble("deviceVDirection");
    
    texture->displayRect[0] = position[0];
    texture->displayRect[1] = position[1];
    if (position[2] == 0)
        texture->displayRect[2] = texture->imageWidth*xPixelsToDevice;
    else
        texture->displayRect[2] = position[2];
    if (position[3] == 0)
        texture->displayRect[3] = texture->imageHeight*yPixelsToDevice;
    else
        texture->displayRect[3] = position[3];
    
    // mexPrintf("(mglcBltTexture) Display rect = [%0.2f %0.2f %0.2f %0.2f]\n",texture->displayRect[0],texture->displayRect[1],texture->displayRect[2],texture->displayRect[3]);

    // get the xPixelsToDevice and yPixelsToDevice making sure these are set properly
    if ((xPixelsToDevice == 0) || (yPixelsToDevice == 0)) {
        xPixelsToDevice = 1;
        yPixelsToDevice = 1;
    }

    // ok now fix horizontal alignment
    if (hAlignment == ALIGNCENTER) {
        texture->displayRect[0] = texture->displayRect[0] - (texture->displayRect[2]+texture->textOverhang)/2;
    }
    else if (hAlignment == ALIGNRIGHT) {
        if (deviceHDirection > 0)
            texture->displayRect[0] = texture->displayRect[0] - (texture->displayRect[2]+texture->textOverhang);
    }
    else if (hAlignment == ALIGNLEFT) {
        if (deviceHDirection < 0)
            texture->displayRect[0] = texture->displayRect[0] + (texture->displayRect[2]+texture->textOverhang);
    }

    // ok now fix vertical alignment
    if (vAlignment == ALIGNCENTER) {
        texture->displayRect[1] = texture->displayRect[1] - (texture->displayRect[3]+texture->textOverhang)/2;
        if (deviceVDirection > 0) {
    // and adjust overhang
            texture->displayRect[1] = texture->displayRect[1]+texture->textOverhang;
        }
    }
    else if (vAlignment == ALIGNBOTTOM) {
        if (deviceVDirection < 0) {
            texture->displayRect[1] = texture->displayRect[1] - (texture->displayRect[3]+texture->textOverhang);
            texture->displayRect[1] = texture->displayRect[1]-texture->textOverhang;
        }
        else {
            texture->displayRect[1] = texture->displayRect[1]+2*texture->textOverhang;
        }
    }
    else if (vAlignment == ALIGNTOP) {
        if (deviceVDirection > 0) {
            texture->displayRect[1] = texture->displayRect[1] - (texture->displayRect[3]+texture->textOverhang);
        }
        else {
            texture->displayRect[1] = texture->displayRect[1]+texture->textOverhang;
        }
    }

    // add the offset to the display rect
    texture->displayRect[2] = texture->displayRect[2] + texture->displayRect[0];
    texture->displayRect[3] = texture->displayRect[3] + texture->displayRect[1];

    // check for flips, this is only necessary for text textures (i.e. ones created by mglText)
    // so that the global variables textHFlip and textVFlip control how the texture is blted
    if (texture->isText) {
      // look in global for flips    
      // first check whether coordinate system runs upward or downward
        if (deviceVDirection < 0) {
            // coordinate system flipped in y-direction; flip text by default
            double temp;
            temp = texture->displayRect[1];
            texture->displayRect[1] = texture->displayRect[3];
            texture->displayRect[3] = temp;
        }
    }
    // see if we need to do vflip
    if (texture->vFlip) {
        double temp;
        temp = texture->displayRect[1];
        texture->displayRect[1] = texture->displayRect[3];
        texture->displayRect[3] = temp;
    }
    // see if we need to do hflip
    if (texture->hFlip) {
        double temp;
        temp = texture->displayRect[2];
        texture->displayRect[2] = texture->displayRect[0];
        texture->displayRect[0] = temp;
    }
    // mexPrintf("(mglcBltTexture) Display rect = [%0.2f %0.2f %0.2f %0.2f]\n",texture->displayRect[0],texture->displayRect[1],texture->displayRect[2],texture->displayRect[3]);

    // set blending functions etc.
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glColor4f(1,1,1,1);

    // calculate the amount of shift we need to
    // move the axis (to center tex)
    double xshift = texture->displayRect[0]+(texture->displayRect[2]-texture->displayRect[0])/2;
    double yshift = texture->displayRect[1]+(texture->displayRect[3]-texture->displayRect[1])/2;
    texture->displayRect[3] -= yshift;
    texture->displayRect[2] -= xshift;
    texture->displayRect[1] -= yshift;
    texture->displayRect[0] -= xshift;

    // now shift and rotate the coordinate frame
    glMatrixMode( GL_MODELVIEW );    
    glPushMatrix();
    glTranslated(xshift,yshift,0);
    glRotated(texture->rotation,0,0,1);

#ifdef GL_TEXTURE_RECTANGLE_EXT
    // bind the texture we want to draw
    glEnable(GL_TEXTURE_RECTANGLE_EXT);
    glBindTexture(GL_TEXTURE_RECTANGLE_EXT, texture->textureNumber);

    // and set the transformation
    glBegin(GL_QUADS);
    if (texture->textureAxes == YX) {
    // default texture axes (yx, using matlab coordinates) does not require
    // swapping y and x in texture coords (done in mglCreateTexture)
        glTexCoord2d(0.0, 0.0);
        glVertex3d(texture->displayRect[0],texture->displayRect[1], 0.0);

        glTexCoord2d(0.0, texture->imageHeight);
        glVertex3d(texture->displayRect[0], texture->displayRect[3], 0.0);

        glTexCoord2d(texture->imageWidth, texture->imageHeight);
        glVertex3d(texture->displayRect[2], texture->displayRect[3], 0.0);

        glTexCoord2d(texture->imageWidth, 0.0);
        glVertex3d(texture->displayRect[2], texture->displayRect[1], 0.0);
        glEnd();
    }
    else {
        if (texture->textureAxes==XY) {
      //  using reverse ordered coordinates does require swapping y and x in texture coords.
            glTexCoord2d(0.0, 0.0);
            glVertex3d(texture->displayRect[0],texture->displayRect[1], 0.0);

            glTexCoord2d(0.0, texture->imageWidth);
            glVertex3d(texture->displayRect[2], texture->displayRect[1], 0.0);

            glTexCoord2d(texture->imageHeight,texture->imageWidth);
            glVertex3d(texture->displayRect[2], texture->displayRect[3], 0.0);

            glTexCoord2d(texture->imageHeight, 0.0);
            glVertex3d(texture->displayRect[0], texture->displayRect[3], 0.0);    
        }
    }

    glEnd();
    glDisable(GL_TEXTURE_RECTANGLE_EXT);
#else//GL_TEXTURE_RECTANGLE_EXT
    // bind the texture we want to draw
    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, texture->textureNumber);

    // and set the transformation
    glBegin(GL_QUADS);
    if (strncmp(texture->textureAxes, "yx",2)==0) {
        // default texture axes (yx, using matlab coordinates) does not require swapping y and x in texture coords.
        glTexCoord2f(0.0, 0.0);
        glVertex3f(texture->displayRect[0],texture->displayRect[1], 0.0);

        glTexCoord2f(0.0, 1.0);
        glVertex3f(texture->displayRect[0], texture->displayRect[3], 0.0);

        glTexCoord2f(1.0, 1.0);
        glVertex3f(texture->displayRect[2], texture->displayRect[3], 0.0);

        glTexCoord2f(1.0, 0.0);
        glVertex3f(texture->displayRect[2], texture->displayRect[1], 0.0);
    }
    else {
        if (strncmp(texture->textureAxes,"xy",2)==0) {
        //  using reverse ordered coordinates does require swapping y and x in texture coords.
            glTexCoord2f(0.0, 0.0);
            glVertex3f(texture->displayRect[0],texture->displayRect[1], 0.0);

            glTexCoord2f(0.0, 1.0);
            glVertex3f(texture->displayRect[2], texture->displayRect[1], 0.0);

            glTexCoord2f(1.0, 1.0);
            glVertex3f(texture->displayRect[2], texture->displayRect[3], 0.0);

            glTexCoord2f(1.0, 0.0);
            glVertex3f(texture->displayRect[0], texture->displayRect[3], 0.0);

        }
    }
    glEnd();
#endif//GL_TEXTURE_RECTANGLE_EXT
    glPopMatrix();
}

MGLTexture *mglcCreateRGBATexture(int width, int height)
{
    // we need eventually add parameters to set other elements of the texture
    // array

    // declare some variables
    int i,j;
    double xPixelsToDevice, yPixelsToDevice, deviceHDirection, deviceVDirection;
    MGLTexture *texture;
    
    texture = (MGLTexture*)malloc(sizeof(MGLTexture));

    xPixelsToDevice = mglGetGlobalDouble("xPixelsToDevice");
    yPixelsToDevice = mglGetGlobalDouble("yPixelsToDevice");
    deviceHDirection = mglGetGlobalDouble("deviceHDirection");
    deviceVDirection = mglGetGlobalDouble("deviceVDirection");
    
    glGenTextures(1, &(texture->textureNumber));
    texture->pixels = (GLubyte*)malloc(width*height*sizeof(GLubyte)*BYTEDEPTH);
    texture->imageWidth = width;
    texture->imageHeight = height;
    texture->textureAxes = YX;
    texture->hFlip = 0;
    texture->vFlip = 0;
    texture->textOverhang = 0;
    texture->isText = 0;
    texture->rotation = 0;
    texture->displayRect[0] = 0;
    texture->displayRect[1] = 0;
    texture->displayRect[2] = 0;
    texture->displayRect[3] = 0;

  // If rectangular textures are unsupported, scale image to nearest dimensions
#ifndef GL_TEXTURE_RECTANGLE_EXT
  // No support for non-power of two textures
    printf("NO SUPPORT FOR NON-POWER OF TWO TEXTURES!");
    int po2Width=texture->imageWidth;
    int po2Height=texture->imageHeight;
    double lw=log(texture->imageWidth)/log(2);
    double lh=log(texture->imageHeight)/log(2);
    if (lw!=round(lw) | lh!=round(lh)) {
        po2Width=(int) pow(2,round(lw));
        po2Height=(int) pow(2,round(lh));
        GLubyte * tmp = (GLubyte*)malloc(po2Width*po2Height*sizeof(GLubyte)*BYTEDEPTH);
        gluScaleImage( GL_RGBA, texture->imageWidth, texture->imageHeight, TEXTURE_DATATYPE, glPixels, po2Width, po2Height, TEXTURE_DATATYPE, tmp);
        free(texture->pixels);
        texture->pixels=tmp;
        texture->imageWidth = po2Width;
        texture->imageHeight = po2Height;
    }
    glBindTexture(GL_TEXTURE_2D, texture->textureNumber);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glPixelStorei(GL_UNPACK_ROW_LENGTH,0);

  // now place the data into the texture
    glTexImage2D(GL_TEXTURE_2D,0,4,texture->imageWidth,texture->imageHeight,0,GL_RGBA,TEXTURE_DATATYPE,texture->pixels);

#else// GL_TEXTURE_RECTANGLE_EXT
  // Support for non-power of two textures
    glBindTexture(GL_TEXTURE_RECTANGLE_EXT, texture->textureNumber);

// #ifdef __APPLE__
//     // tell GL that the memory will be handled by us. (apple)
//     glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE,0);
//     // now, try to store the memory in VRAM (apple)
//     glTexParameteri(GL_TEXTURE_RECTANGLE_EXT,GL_TEXTURE_STORAGE_HINT_APPLE,GL_STORAGE_CACHED_APPLE);
//     glTextureRangeAPPLE(GL_TEXTURE_RECTANGLE_EXT,texture->imageWidth*texture->imageHeight*BYTEDEPTH,texture->pixels);
// #endif

  // some other stuff
    glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glPixelStorei(GL_UNPACK_ROW_LENGTH,0);

  // now place the data into the texture
    glTexImage2D(GL_TEXTURE_RECTANGLE_EXT,0,GL_RGBA,texture->imageWidth,texture->imageHeight,0,GL_RGBA,TEXTURE_DATATYPE,texture->pixels);

#endif// GL_TEXTURE_RECTANGLE_EXT
    return(texture);
    
}

void mglcFreeTexture(MGLTexture *texture)
{
    mexPrintf("Freeing texture number %d\n", texture->textureNumber);
    glDeleteTextures(1,&texture->textureNumber);
    free(texture->pixels);
    free(texture);
}

MGLTexture *mglcCreateTextTexture(char *text)
{

  // get the global variable for the font
    mxArray *gFontName = mglGetGlobalField("fontName");
    char fontName[1024];

  // check for null pointer
    if (gFontName == NULL)
        snprintf(fontName, sizeof(fontName), DEFAULT_FONT); // safety first!
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
    GLubyte *bitmapData = (GLubyte *)renderText(text, fontName, fontSize, fontColor, fontRotation, fontBold, fontItalic, fontUnderline, fontStrikethrough, &pixelsWide, &pixelsHigh, &textImageRect);

    ///////////////////////////
    // create a texture
    ///////////////////////////
    MGLTexture *texture;
    texture = mglcCreateRGBATexture(pixelsHigh,pixelsWide);
    memcpy(texture->pixels, bitmapData, (BYTEDEPTH*texture->imageWidth*texture->imageHeight));  
    texture->isText = 1;
    texture->vFlip = mglGetGlobalDouble("fontHFlip");
    texture->hFlip = mglGetGlobalDouble("fontHFlip");
    
    
    // WE'LL NEED THIS IF THE DATA ISN'T HANDLED LOCALLY
    // // now place the data into the texture
    glBindTexture(GL_TEXTURE_2D, texture->textureNumber);    
    glTexImage2D(GL_TEXTURE_RECTANGLE_EXT,0,GL_RGBA,texture->imageWidth,texture->imageHeight,0,GL_RGBA,TEXTURE_DATATYPE,texture->pixels);  

    // free up the original bitmapData
    // free(bitmapData);
    return(texture);
}

#ifdef __APPLE__
//-----------------------------------------------------------------------------------///
// ******************************* mac specific code  ******************************* //
//-----------------------------------------------------------------------------------///
unsigned char *renderText(char *cInputString, char*fontName, int fontSize, double *fontColor, double fontRotation, Boolean fontBold, Boolean fontItalic, Boolean fontUnderline, Boolean fontStrikethrough, int *pixelsWide, int *pixelsHigh, Rect *textImageRect)
{

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
    // if (mxIsUint16(inputString)) 
    //     verify_noerr( ATSUSetTextPointerLocation(layout,(UniChar*)mxGetData(inputString),kATSUFromTextBeginning, kATSUToTextEnd, mxGetN(inputString)));
    // else
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
    // free(cInputString);

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
//-----------------------------------------------------------------------------------///
// ****************************** linux specific code  ****************************** //
//-----------------------------------------------------------------------------------///
#ifdef __linux__

#include <string.h>
#include <math.h>
#include <ft2build.h>
#include FT_FREETYPE_H

void draw_bitmap( FT_Bitmap* bitmap, FT_Int x, FT_Int y, unsigned char *image, int width, int height )
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


unsigned char *renderText(const mxArray *inputString, char*fontName, int fontSize, double *fontColor, double fontRotation, Boolean fontBold, Boolean fontItalic, Boolean fontUnderline, Boolean fontStrikethrough, int *pixelsWide, int *pixelsHigh, Rect *textImageRect)
{

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

    mglM  int offs;
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


}

#endif //__linux__

void mglcClearScreen(int *color)
{
    if (color!=NULL) {
        glClearColor(color[0],color[1],color[2],color[3]);    
    }
    // now clear to the set color
    glClear(GL_COLOR_BUFFER_BIT);    
}

void mglcFlush(int displayNumber)
{
  int fullScreen=1;

  
//-----------------------------------------------------------------------------------///
// **************************** mac cocoa specific code  **************************** //
//-----------------------------------------------------------------------------------///
#ifdef __APPLE__ 
#ifdef __cocoa__
  if (displayNumber >= 0) {
    if (mglGetGlobalDouble("isCocoaWindow")) {
      // cocoa, get openGLContext and flush
      NSOpenGLContext *myOpenGLContext = (NSOpenGLContext*)(unsigned long)mglGetGlobalDouble("GLContext");
      if (myOpenGLContext)
	[myOpenGLContext flushBuffer];
    }
    else {
      // get the current context
      CGLContextObj contextObj = CGLGetCurrentContext();
      // and flip the double buffered screen
      // this call waits for vertical blanking
      CGLFlushDrawable(contextObj); 
    }
  }
#else //__cocoa__
//-----------------------------------------------------------------------------------///
// **************************** mac carbon specific code  *************************** //
//-----------------------------------------------------------------------------------///
  if (displayNumber > 0) {

    // get the current context
    CGLContextObj contextObj = CGLGetCurrentContext();

    // and flip the double buffered screen
    // this call waits for vertical blanking
    CGLFlushDrawable(contextObj); 
  }
  else if (displayNumber == 0) {
    // run in a window: get agl context
    AGLContext contextObj=aglGetCurrentContext ();

    if (!contextObj) {
      printf("(mglFlush) No drawable context found\n");
    }

    // there seems to be some interaction with the matlab desktop
    // in which the windowed graphics context crashes. The crash
    // appears to occur in handeling a FlushAllWindows call. This
    // causes a EXC_BAD_ACCESS error (something like a seg fault).
    // I think this is occuring because of some interaction with
    // multiple threads running--presumably, the window is being
    // updated by one thread which called FlushAllBuffers and
    // also by our call (either here, or in ShowWindow or HideWindow).
    // the multiple accesses make Mac unhappy. 
    // Don't know how to deal with this problem. I have tried to 
    // check here that QDDone has finished, but it doesn't seem to make a
    // difference.
    // other things were tried too, like checking for events (assuming
    // that maybe the OS got stuck with events that were never processed
    // but none of that helped).
    // The only thing that does seem to help is not closing and opening
    // the window.
    //AGLDrawable drawableObj = aglGetDrawable(contextObj);
    //    QDFlushPortBuffer(drawableObj,NULL);
    // swap buffers
    //    if (QDDone(drawableObj))
    aglSwapBuffers (contextObj);
    
    // get an event
    //    EventRef theEvent;
    //    EventTargetRef theTarget;
    //    theTarget = GetEventDispatcherTarget();
    //    if (ReceiveNextEvent(0,NULL,3/60,true,&theEvent) == noErr) {
    //      SendEventToEventTarget(theEvent,theTarget);
    //      ReleaseEvent(theEvent);
    //    }
    //    EventRecord theEventRecord;
    //    EventMask theMask = everyEvent;
    //    WaitNextEvent(theMask,&theEventRecord,3,nil);
  }
#endif//__cocoa__
#endif//__APPLE__
//-----------------------------------------------------------------------------------///
// ****************************** linux specific code  ****************************** //
//-----------------------------------------------------------------------------------///
#ifdef __linux__

  int dpyptr=(int)mglGetGlobalDouble("XDisplayPointer");
  if (dpyptr<=0) return;
  Display * dpy=(Display *)dpyptr;
  glXSwapBuffers( dpy, glXGetCurrentDrawable() );

#endif//__linux__

//-----------------------------------------------------------------------------------///
// **************************** Windows specific code  ****************************** //
//-----------------------------------------------------------------------------------///
#ifdef __WINDOWS__
  unsigned int ref;
  HDC hDC;
  HGLRC hRC;
  
  // Grab our device and rendering context pointers.
  ref = (unsigned int)mglGetGlobalDouble("winDeviceContext");
  hDC = (HDC)ref;
  ref = (unsigned int)mglGetGlobalDouble("GLContext");
  hRC = (HGLRC)ref;
  
  wglMakeCurrent(hDC, hRC);
  SwapBuffers(hDC);
#endif // __WINDOWS__
}


int sub2indM( int row, int col, int height, int elsize ) {
  // return linear index corresponding to (row,col) into row-major array (Matlab-style)
    return ( row*elsize + col*height*elsize );
}

int sub2indC( int row, int col, int width, int elsize ) {
  // return linear index corresponding to (row,col) into column-major array (C-style)
    return ( col*elsize + row*width*elsize );
}

int sub2ind( int row, int col, int height, int elsize ) {
  // return linear index corresponding to (row,col) into Matlab array
  return ( row*elsize + col*height*elsize );
}
