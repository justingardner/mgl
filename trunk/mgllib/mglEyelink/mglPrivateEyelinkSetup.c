#ifdef documentation
=========================================================================
  program: mglPrivateEyelinkSetup.c
  by:      eric dewitt and eli merriam
  date:    02/08/09
  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
  purpose: Sets the eyetracker into setup mode for calibration, validation
  and drift correction. Allows for mgl based (local) calibration 
  and eyelink software (remote, on eyelink computer) based setup.
  Local setup allows for self calibration. Wrapper handles keyboard.
  You must specify display location for the camera graphics.
  usage:   mglPrivateEyelinkSetup([display_num], [calTargetParams])

  =========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
#include "mglPrivateEyelinkSetup.h"

//////////////
//   main   //
//////////////

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  int i;

  if (nrhs > 2) { /* What arguments should this take? */
    usageError("mglPrivateEyelinkSetup");
    return;
  }

  if (nrhs >= 1) {
    int n;
    mexPrintf("(mglPrivateEyelinkSetup) Attempting to use specific display.\n"); 
    n = mxGetN(prhs[0])*mxGetM(prhs[0]);
    if (n != 1) {
      mexErrMsgTxt("(mglPrivateEyelinkSetup) You must specify a single display number.");
    }
    mglcDisplayNumber = (int)*(double*)mxGetPr(prhs[0]);
  }
  else {
    mglcDisplayNumber = (int)mglGetGlobalDouble("displayNumber");
  }

  // Setup the calibration target colors if specified.
  if (nrhs >= 2) {
    // Make sure a struct was passed.
    if (!mxIsStruct(prhs[1])) {
      mexErrMsgTxt("(mglPrivateEyelinkSetup) calTargetParams must be a struct.");
    }

    // Pull out the target parameters from the passed struct.
    memcpy(_calTarget.innerRGB, mxGetPr(mxGetField(prhs[1], 0, "innerRGB")), sizeof(double)*3);
    memcpy(_calTarget.outerRGB, mxGetPr(mxGetField(prhs[1], 0, "outerRGB")), sizeof(double)*3);
  }
  else {
    // Make the outer part of the target greyish.
    for (i = 0; i < 3; i++) {
      _calTarget.outerRGB[i] = 0.8;
    }

    // Make the inner part of the target red.
    _calTarget.innerRGB[0] = 1.0;
    _calTarget.innerRGB[1] = 0.0;
    _calTarget.innerRGB[2] = 0.0;
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

  // setupGeyKeyCallback();

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

  UINT16 keycode = 0;    // the key (mgl code)


  //  mxArray *callOutput[1];
  //  mexCallMATLAB(1, callOutput, 0, NULL, "mglGetKeys");
  //  int nKeys = mxGetNumberOfElements(callOutput[0]);
  //  double *keysDown = (double *)mxGetPr(callOutput[0]);
  //  int keyDown = 0;
  //  int i;
  //  for (i = 0; i < nKeys; i++)
  //    if (keysDown[i])
  //      keyDown = i+1;
  //  if (keyDown)
  //    mexPrintf("%i\n",keyDown);




  //  if (nKeys > 0) {
  //    int myEventKeyCode = (int)*(double *)mxGetPr(callOutput[0]);
  //    int myEventKeyCharcode = (int)*(double *)mxGetPr(callOutput[2]);
  //    mexPrintf("%i %i %i\n",nKeys,myEventKeyCode,myEventKeyCharcode);
  //  }


  // get a key event using the get key event.
  if (!(keycode = mglcGetKeys())) {
    eventKeyCode = 0;
    return 0;
  }
  else {
    if (eventKeyCode == keycode) {
      return 0;
    }
    eventKeyCode = keycode;
    // parse key and place in *key_input
    UINT16 charcode = 0, modcode = 0; // the key (ascii)
    // get modifiers
    int shift = 0, control = 0, command = 0, alt = 0, capslock = 0;
    // get the key event
    // charbuff = keycodeToChar(keycode);
    // if (charbuff!=NULL)
    //     charcode = (UINT16)charbuff[0];
    // else
    //     charcode = 0;
    // mxFree(charbuff);
    // free(charbuff);
    // if (tmpOut!=NULL) {
    //     shift = (int)*(double*)mxGetPr(tmpOut);
    //     control = (int)*(double*)mxGetPr(mxGetField(callOutput[0],0,"control"));
    //     capslock = (int)*(double*)mxGetPr(mxGetField(callOutput[0],0,"capslock"));
    //     alt = (int)*(double*)mxGetPr(mxGetField(callOutput[0],0,"alt"));
    // }
    charcode = (UINT16)*keycodeToChar(keycode);
    // mexPrintf("c %d (%.1s) k %d shift %d cntr %d caps %d alt %d\n", charcode,
    //     charbuff, keycode, shift, control, capslock, alt);
    // mexPrintf("c %d k %d shift %d cntr %d caps %d alt %d\n", charcode,
    //     keycode, shift, control, capslock, alt);

    // if (shift)
    //     modcode = (modcode | ELKMOD_LSHIFT | ELKMOD_RSHIFT);
    // if (control)
    //     modcode = (modcode | ELKMOD_LCTRL | ELKMOD_RCTRL);
    // if (alt)
    //     modcode = (modcode | ELKMOD_LALT | ELKMOD_RALT);
    // if (capslock)
    //     modcode = (modcode | ELKMOD_CAPS);

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
  // mexPrintf("(mglPrivateEyelinkCalibrate) call to draw_cal_target(%i,%i)\n",x,y);
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

  *inSize = 5; // in pixels for now
  memcpy(inColor, _calTarget.outerRGB, sizeof(double)*3);
  // mglGluDisk(xDeg, yDeg, targetSize, targetcolor);
  mexCallMATLAB(0, NULL, 4, callInput, "mglGluDisk");            
  *inSize = 2; // in pixels for now
  memcpy(inColor, _calTarget.innerRGB, sizeof(double)*3);
  mexCallMATLAB(0, NULL, 4, callInput, "mglGluDisk");            
  mexEvalString("mglFlush;");
  // mexPrintf("mglPrivateEyelinkCalibrate) mglGluDisk at (%g,%g) with size %g.\n", *inX, *inY, *inSize);
}

/*!
  This function is responsible for erasing the target that was drawn by the last call to draw_cal_target.
 */
void ELCALLBACK erase_cal_target(void)
{
  /* erase the last calibration target  */
  mexEvalString("mglClearScreen;");
  mexEvalString("mglFlush;");
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
  mexEvalString("mglClearScreen;");
  mexEvalString("mglFlush;");

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
  // set up colormap for screen display
  for(i=0; i<ncolors; i++) {
    cameraImageColormap[i][0] = (GLubyte)r[i];
    cameraImageColormap[i][1] = (GLubyte)g[i];
    cameraImageColormap[i][2] = (GLubyte)b[i];
  }
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

  // create a texture using mglCreateTexture
  mxArray *callInput[3],*callOutput[2];
  mwSize dims[3] = {height, width, BYTEDEPTH};
  callInput[0] = mxCreateNumericArray(3,dims,mxDOUBLE_CLASS,mxREAL);
  callInput[1] = mxCreateString("yx");
  callInput[2] = mxCreateDoubleMatrix(1,1,mxREAL);
  double *arg = (double*)mxGetPr(callInput[2]);
  *arg = 1;
  mexCallMATLAB(1,callOutput,3,callInput,"mglCreateTexture");            

  // clean up
  mxDestroyArray(callInput[0]);
  mxDestroyArray(callInput[1]);
  mxDestroyArray(callInput[2]);

  // get the pointer to the "liveBuffer" which we can use to modify the texture on the fly
  cameraTexture = callOutput[0];
  cameraImageBuffer = (GLubyte*)(unsigned long)*mxGetPr(mxGetField(callOutput[0],0,"liveBuffer"));
  cameraTextureType = (GLenum)*mxGetPr(mxGetField(callOutput[0],0,"textureType"));
  cameraTextureNumber = (GLuint)*mxGetPr(mxGetField(callOutput[0],0,"textureNumber"));

  // set the alpha channel to 255
  int i,c=0;
  for(i = 0;i<width*height;i++,c+=4)
    cameraImageBuffer[c+3] = 255;

  // clear the screen
  mexEvalString("mglClearScreen");
  mexEvalString("mglFlush;");

  // set the center of the screen
  screenCenterX = mglGetGlobalDouble("screenWidth")/2;
  screenCenterY = mglGetGlobalDouble("screenHeight")/2;

  // and the bottom left corner of the screen image
  cameraPos[0] = screenCenterX - width;
  cameraPos[1] = screenCenterY - height;
  return 0;
}

/*!
  This is called to notify that all camera setup things are complete.  Any
  resources that are allocated in setup_image_display can be released in this
  function.
 */
void ELCALLBACK exit_image_display(void)
{
  // check to see if we need to delete the texture
  mxArray *callInput[1];
  if (cameraImageBuffer) {
    callInput[0] = cameraTexture;
    mexCallMATLAB(0,NULL,1,callInput,"mglDeleteTexture");
  }
  // clear the screen
  mexEvalString("mglClearScreen;");
  mexEvalString("mglFlush;");
  mexEvalString("mglClearScreen;");
  mexEvalString("mglFlush;");

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
  // init variables
  short i;
  byte *p = pixels;
  mxArray *callInput[2];

  // get the beginning of the current line
  GLubyte *thisLineCameraImageBuffer = cameraImageBuffer+(line-1)*width*BYTEDEPTH;

  // draw the line into our memory buffer
  for(i=0; i<width; i++) {
    thisLineCameraImageBuffer[i*BYTEDEPTH] = cameraImageColormap[*p][0];
    thisLineCameraImageBuffer[i*BYTEDEPTH+1] = cameraImageColormap[*p][1];
    thisLineCameraImageBuffer[i*BYTEDEPTH+2] = cameraImageColormap[*p][2];
    p++;
  }
  if(line == totlines) {
    // at this point we have a complete camera image.
    // rebind the texture to the image buffer
    glBindTexture(cameraTextureType, cameraTextureNumber);
    glTexImage2D(cameraTextureType,0,GL_RGBA,width,totlines,0,GL_RGBA,TEXTURE_DATATYPE,cameraImageBuffer);

    // clear the screen,
    mexEvalString("mglClearScreen;");

    // blt that texture to the screen
    callInput[0] = cameraTexture;
    callInput[1] = mxCreateDoubleMatrix(1,4,mxREAL);
    double *bltPos = (double*)mxGetPr(callInput[1]);
    bltPos[0] = screenCenterX;bltPos[1] = screenCenterY;bltPos[2] = width*2;bltPos[3] = totlines*2;
    mexCallMATLAB(0,NULL,2,callInput,"mglBltTexture");            

    // now we need to draw the cursors.
    CrossHairInfo crossHairInfo;
    memset(&crossHairInfo,0,sizeof(crossHairInfo));

    crossHairInfo.w = width*2;
    crossHairInfo.h = totlines*2;
    crossHairInfo.drawLozenge = drawLozenge;
    crossHairInfo.drawLine = drawLine;
    crossHairInfo.getMouseState = getMouseState;
    // crossHairInfo.userdata = image; // could be used for gl display num

    eyelink_draw_cross_hair(&crossHairInfo);

    // flush screen
    mexEvalString("mglFlush;");
    return;


  }

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
    snprintf(cameraTitle, sizeof(cameraTitle), "%s, threshold at %d", 
        title, threshold);
  }
  //  mexPrintf("(mglPrivateEyelinkSetup) Camera Title: %s\n", cameraTitle);
  // mglcFreeTexture(mgltTitle);
  // mgltTitle = mglcCreateTextTexture(cameraTitle);

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
  *(double*)mxGetPr(callInput[0]) = x1 + cameraPos[0];
  *(double*)mxGetPr(callInput[1]) = y1 + cameraPos[1];
  *(double*)mxGetPr(callInput[2]) = x2 + cameraPos[0];
  *(double*)mxGetPr(callInput[3]) = y2 + cameraPos[1];

  //  *(double*)mxGetPr(callInput[0]) = x1;
  //  *(double*)mxGetPr(callInput[1]) = y1;
  //  *(double*)mxGetPr(callInput[2]) = x2;
  //  *(double*)mxGetPr(callInput[3]) = y2;
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




// =========================
// = New Get Keys Function =
// =========================
int mglcGetKeys()
{
  int i,n,displayKey;

  //-----------------------------------------------------------------------------------///
  // ******************************* mac specific code  ******************************* //
  //-----------------------------------------------------------------------------------///
#ifdef __APPLE__
  int longNum;int bitNum;int logicalNum = 0;
  //  get the status of the keyboard
  KeyMap theKeys;
  GetKeys(theKeys);
  unsigned char *keybytes;
  short k;
  keybytes = (unsigned char *) theKeys;

  i = 0;
  while (i < 128) {
    k=(short)i;
    if ((keybytes[k>>3] & (1 << (k&7))) != 0) {
      return i+1;
    }
    i++;
  }
  return 0;
#endif//__APPLE__

  //-----------------------------------------------------------------------------------///
  // ****************************** linux specific code  ****************************** //
  //-----------------------------------------------------------------------------------///
#ifdef __linux__
  Display * dpy;
  int dpyptr=(int)mglGetGlobalDouble("XDisplayPointer");
  if (dpyptr<=0) {
    // open a dummy display
    dpy=XOpenDisplay(0);
  } else {
    dpy=(Display *)dpyptr;
  }
  char keys_return[32];

  XQueryKeymap(dpy, keys_return);

  if (!returnAllKeys) {
    // figure out how many elements are desired
    n = mxGetN(prhs[0]);
    // and create an output matrix
    plhs[0] = mxCreateDoubleMatrix(1,n,mxREAL);
    outptr = mxGetPr(plhs[0]);
    // now go through and get each key
    for (i=0; i<n; i++) {
      displayKey = (int)*(inptr+i)-1; // input is 1-offset
      if ((displayKey < 0) || (displayKey > 256)) {
        mexPrintf("(mglGetKeys) Key %i out of range 1:256",displayKey);
        return;
      }
      int keypos=(int) floor(displayKey/8);
      int keyshift=displayKey%8;

      *(outptr+i) = (double) (( keys_return[keypos] >> keyshift) & 0x1);
    }
  } else {
    plhs[0] = mxCreateLogicalMatrix(1,256);
    mxLogical *loutptr = mxGetLogicals(plhs[0]);

    for (int n=0; n<32; n++) {
      for (int m=0; m<8; m++) {
        *(loutptr+n*8+m) = (double) (( keys_return[n] >> m ) & 0x1);
      }
    }
    if (verbose) {
      mexPrintf("(mglGetKeys) Keystate = ");
      for (int n=0; n<32; n++) {
        for (int m=0; m<8; m++) {
          mexPrintf("%i ", ( keys_return[n] >> m ) & 0x1 );
        }
      }
      mexPrintf("\n");
    }
  }

  if (dpyptr<=0) {
    XCloseDisplay(dpy);
  }



#endif 
}


#ifdef __linux__
#include <sys/time.h>
#endif

INT16 mglcGetKeyEvent(MGLKeyEvent *mglKey)
{

  // declare variables
  double waittime = 0.0;
  //-----------------------------------------------------------------------------------///
  // **************************** mac cocoa specific code  **************************** //
  //-----------------------------------------------------------------------------------///
#ifdef __APPLE__
#ifdef __cocoa__
  // 64 bit version not implemented
  mexPrintf("(mglcGetKeyEvent) 64bit version not implemented\n");
  return;
  //-----------------------------------------------------------------------------------///
  // **************************** mac carbon specific code  *************************** //
  //-----------------------------------------------------------------------------------///
#else //__cocoa__
  // get next event on queue
  UInt32 waitTicks = (UInt32) round(waittime * 60.15);
  EventRecord theEvent;
  EventMask theMask = keyDownMask;

  // either return immediately or wait till we get an event
  Boolean result;
  if (waitTicks)
    result=WaitNextEvent(theMask,&theEvent, waitTicks,nil);
  else
    result=GetNextEvent(theMask,&theEvent);

  if (!result) {
    return 0;
  }
  else {
    FlushEvents (theMask, 0);
    // set the output variables
    mglKey->charCode = (INT16)(theEvent.message & charCodeMask);
    mglKey->keyCode = (INT16)((theEvent.message & keyCodeMask)>>8);
    mglKey->keyboard = (INT16)(theEvent.message>>16);
    mglKey->when = (INT16)theEvent.when;
    return 1;
  }
#endif//__cocoa__
#endif//__APPLE__
  //-----------------------------------------------------------------------------------///
  // ****************************** linux specific code  ****************************** //
  //-----------------------------------------------------------------------------------///
#ifdef __linux__

  int dpyptr=(int)mglGetGlobalDouble("XDisplayPointer");
  if (dpyptr<=0) {
    if (verbose) mexPrintf("No display found!\n");
    return;
  }
  Display * dpy=(Display *)dpyptr;
  int winptr=(int) mglGetGlobalDouble("XWindowPointer");
  Window win = *(Window *)winptr;
  XEvent event;

  Bool keyPressed=false;
  if (waittime>0.0) {
    struct timeval tp;
    struct timezone tz;

    double currtime=0.0;

    gettimeofday( &tp, &tz );
    double starttime= (double) tp.tv_sec + (double) tp.tv_usec * 0.000001;

    do {
      //      keyPressed=XCheckTypedWindowEvent(dpy, win, KeyPress, &event);
      keyPressed=XCheckTypedEvent(dpy, KeyPress, &event);
      gettimeofday( &tp, &tz );
      currtime= (double) tp.tv_sec + (double) tp.tv_usec * 0.000001 - starttime;
    } while ( !keyPressed && currtime<waittime );

  } else {
    //    keyPressed=XCheckTypedWindowEvent(dpy, win, KeyPress, &event);
    keyPressed=XCheckTypedEvent(dpy, KeyPress, &event);
  }

  if ( keyPressed ) {
    // set the fields
    plhs[0] = makeOutputStructure(&outptrCharCode,&outptrKeyCode,&outptrKeyboard,&outptrWhen);
    *outptrCharCode = (double)*(XKeysymToString(XKeycodeToKeysym(dpy, event.xkey.keycode, 0))); // always returns first entry of keycode list
    *outptrKeyCode = (double)event.xkey.keycode;
    *outptrKeyboard = (double)event.xkey.state; // contains information about keyboard
    *outptrWhen = (double)event.xkey.time*0.001;

  } else {
    plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
  }
#endif //__linux__
}
//-----------------------------------------------------------------------------------///
// **************************** mac cocoa specific code  **************************** //
//-----------------------------------------------------------------------------------///
#ifdef __APPLE__
#ifdef __cocoa__
///////////////////////
//   keycodeToChar   //
///////////////////////
char *keycodeToChar(UInt16 keycode)
{
  UInt32 keyboard_type = 0;
  const void *chr_data = NULL;
  UInt32 deadKeyState = 0;
  UniCharCount maxStringLength = 8, actualStringLength;
  UniChar *unicodeString = malloc(sizeof(UniChar)*8);

  // get the current keyboard "layout input source"
  TISInputSourceRef currentKeyLayoutRef = TISCopyCurrentKeyboardLayoutInputSource();
  // and the keyboard type
  keyboard_type = LMGetKbdType ();
  // now get the unicode key layout data
  if (currentKeyLayoutRef) {
    CFDataRef currentKeyLayoutDataRef = (CFDataRef )TISGetInputSourceProperty(currentKeyLayoutRef,kTISPropertyUnicodeKeyLayoutData);
    if (currentKeyLayoutDataRef) 
      chr_data = CFDataGetBytePtr(currentKeyLayoutDataRef);
    else
      mexPrintf("(mglCharToKeycode) Could not get UnicodeKeyLayoutData\n");
  };

  // get the keycode using UCKeyTranslate
  UCKeyTranslate(chr_data,keycode-1,kUCKeyActionDown,0,keyboard_type,0,&deadKeyState,maxStringLength,&actualStringLength,unicodeString);
  // mexPrintf("%u\n",(char)unicodeString[0]);
  char *c = malloc(sizeof(char)*2);
  c[1]=0;
  c[0]=unicodeString[0];
  return (c);

}
//-----------------------------------------------------------------------------------///
// **************************** mac carbon specific code  *************************** //
//-----------------------------------------------------------------------------------///
#else //__cocoa__
///////////////////////
//   keycodeToChar   //
///////////////////////
char *keycodeToChar(UInt16 keycode)
{

  /*
     Converts a virtual key code to a character code based on a 'KCHR' resource.

     UInt32 KeyTranslate (
     const void * transData,
     UInt16 keycode,
     UInt32 * state
     );

     Parameters

     transData

     A pointer to the 'KCHR' resource that you want the KeyTranslate function to use when converting the key code to a character code. 
     keycode

     A 16-bit value that your application should set so that bits 0?6 contain the virtual key code and bit 7 contains either 1 to indicate an up stroke or 0 to indicate a down stroke of the key. Bits 8?15 have the same interpretation as the high byte of the modifiers field of the event structure and should be set according to the needs of your application. 
     state

     A pointer to a value that your application should set to 0 the first time it calls KeyTranslate or any time your application calls KeyTranslate with a different 'KCHR' resource. Thereafter, your application should pass the same value in the state parameter as KeyTranslate returned in the previous call. 

     Return Value
     Discussion

     The KeyTranslate function returns a 32-bit value that gives the character code for the virtual key code specified by the keycode parameter.

     The KeyTranslate function returns the values that correspond to one or possibly two characters that are generated by the specified virtual key code. For example, a given virtual key code might correspond to an alphabetic character with a separate accent character. For example, when the user presses Option-E followed by N, you can map this through the KeyTranslate function using the U.S. 'KCHR' resource to produce ?n, which KeyTranslate returns as two characters in the bytes labeled Character code 1 and Character code 2. If KeyTranslate returns only one character code, it is always in the byte labeled Character code 2. However, your application should always check both bytes labeled Character code 1 and Character code 2 for possible values that map to the virtual key code.

   */

  void *kchr;
  UInt32 state=0;
  KeyboardLayoutRef layout;

  if (KLGetCurrentKeyboardLayout(&layout) != noErr) {
    mexPrintf("Error retrieving current layout\n");
    return;
  }

  //  if (KLGetKeyboardLayoutProperty(layout, kKLKCHRData, const_cast<const void**>(&kchr)) != noErr) {
  if (KLGetKeyboardLayoutProperty(layout, kKLKCHRData, (const void **) (&kchr)) != noErr) {
    mexPrintf("Couldn't load active keyboard layout\n");
    return;
  }

  int bullshitFromSystem=1;
  const void * bullshitFromSystemptr=(void *)&bullshitFromSystem;
  if (KLGetKeyboardLayoutProperty(layout, kKLKind, (&bullshitFromSystemptr)) != noErr) {
    mexPrintf("Couldn't load active keyboard layout\n");
    return;
  }

  char *c = malloc(sizeof(char)*2);
  c[1]=0;

  UInt32 charcode=KeyTranslate( kchr, keycode-1, &state );

  // get byte corresponding to character
  c[0] = (char) (charcode);

  return (c);
}
#endif//__cocoa__
#endif//__APPLE__

//-----------------------------------------------------------------------------------///
// ****************************** linux specific code  ****************************** //
//-----------------------------------------------------------------------------------///
#ifdef __linux__

///////////////////////
//   keycodeToChar   //
///////////////////////
mxArray *keycodeToChar(const mxArray *arrayOfKeycodes)
{

  // Compare the beautiful simplicity of the following code with the Mac horrors above. 
  // Amazing considering that X was developed *before* Apple's API. 

  int nkeys,i;
  Display * dpy;

  // init the output array
  nkeys=mxGetNumberOfElements(arrayOfKeycodes);
  mxArray *out=mxCreateCellMatrix(1,nkeys);


  int dpyptr=(int)mglGetGlobalDouble("XDisplayPointer");
  if (dpyptr<=0) {
    // open a dummy display
    dpy=XOpenDisplay(0);
  } else {
    dpy=(Display *)dpyptr;
  }

  for (i=0; i<nkeys; i++) {
    KeySym keysym=XKeycodeToKeysym(dpy, (int)*(mxGetPr(arrayOfKeycodes)+i)-1, 0);// remove 1-offset  
    if (keysym!=NoSymbol) 
      mxSetCell(out, i, mxCreateString( XKeysymToString(keysym)));
  }

  if (dpyptr<=0) {
    XCloseDisplay(dpy);
  }

  return(out);
}
#endif //__linux__


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
