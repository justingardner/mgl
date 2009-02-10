#ifdef documentation
=========================================================================
program: mglPrivateEyelinkOpen.c
by:      eric dewitt and eli merriam
date:    02/08/09
copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
purpose: mex function to open a connection to an Eyelink tracker and configure
         it for use with the specificed mgl window
usage:   mglPrivateEyelinkOpen(ipaddress, trackedwindow, displaywindow)


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
INT16  ELCALLBACK  setup_cal_display(void);
void ELCALLBACK exit_cal_display(void);
INT16 ELCALLBACK setup_image_display(INT16 width, INT16 height);
void ELCALLBACK image_title(INT16 threshold, char *cam_name);
void ELCALLBACK draw_image_line(INT16 width, INT16 line, INT16 totlines, byte *pixels);
void ELCALLBACK set_image_palette(INT16 ncolors, byte r[130], byte g[130], byte b[130]);
void ELCALLBACK exit_image_display(void);
void ELCALLBACK erase_cal_target(void);
void ELCALLBACK  draw_cal_target(INT16 x, INT16 y);
void ELCALLBACK cal_target_beep(void);
void ELCALLBACK dc_done_beep(INT16 error);
void ELCALLBACK dc_target_beep(void);
void ELCALLBACK cal_done_beep(INT16 error);
INT16 ELCALLBACK get_input_key(InputEvent *key_input);
void ELCALLTYPE get_display_information(DISPLAYINFO *di);
INT16 ELCALLTYPE init_expt_graphics();

// int ELCALLBACK writeImage(char *outfilename, int format, EYEBITMAP *bitmap);

/////////////
//   main   //
//////////////

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

    init_expt_graphics(); // initialize the callbacks
    

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
  Although, this is optional, one should do the innerds of this function elsewhere in a proper manner.

  @remark The prototype of this function can be modified to suit ones needs. Eg.
  The init_expt_graphics of eyelink_core_graphics.dll takes in 2 parameters.
  
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
// int ELCALLBACK writeImage(char *outfilename, IMAGETYPE format, EYEBITMAP *bitmap)
// {
// 
//  return 0;
// }


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
      *inSize = 5; // in pixels for now
      inColor[0] = 0.5; // red
      inColor[1] = 0.5; // green
      inColor[2] = 0.5; // blue
      
      
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

  switch(sound)
  {
    case CAL_TARG_BEEP: /* play cal target beep */
    	break;
    case CAL_GOOD_BEEP: /* play cal good beep */
        break;
    case CAL_ERR_BEEP:  /* play cal error beep */
        break;
    case DC_TARG_BEEP:  /* play drift correct target beep */
       	break;
    case DC_GOOD_BEEP:  /* play drift correct good beep */
      	break;
    case DC_ERR_BEEP:  /* play drift correct error beep */
      	break;
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

/***************************** HIDE DISPLAY ON RECORDING ABORT ************************/


/*
  Called to clear the display.
 */
void ELCALLBACK clear_cal_display(void)
{
   
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
  return 0;
}


/*!
	This is called to notify that all camera setup things are complete.  Any
	resources that are allocated in setup_image_display can be released in this
	function.
*/
void ELCALLBACK exit_image_display(void)
{

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

}



