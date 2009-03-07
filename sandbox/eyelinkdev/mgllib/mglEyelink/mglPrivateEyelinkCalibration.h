// 
//  mglEyelink.h
//  
//  
//  Created by Eric DeWitt, NYU on 2009-03-06.
//  Copyright 2009 Eric DeWitt. All rights reserved.
// 

 
#ifndef __MGLEYELINK_H
#define __MGLEYELINK_H

#include "../mgl.h"
#include <eyelink.h>
#include <core_expt.h>

// ===========
// = Defines =
// ===========
#define DEFAULT_FONT "Times Roman"
#define DEFAULT_FONTSIZE 36

#define BYTEDEPTH 4
#define TEXTURE_DATATYPE GL_UNSIGNED_BYTE // Independent of endianness

// Below are the key code defines to be passed for all non-ascii chars
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
#define KEYUP   1

// Calibration Sounds
#define CAL_TARG_BEEP   1
#define CAL_GOOD_BEEP   0
#define CAL_ERR_BEEP   -1
#define DC_TARG_BEEP    3
#define DC_GOOD_BEEP    2
#define DC_ERR_BEEP    -2

#define LEFT -1
#define CENTER 0
#define RIGHT 1
#define TOP -1
#define BOTTOM 1
#define DEFAULT_H_ALIGNMENT CENTER
#define DEFAULT_V_ALIGNMENT CENTER
#define XY 1
#define YX 0

// ===========
// = Structs =
// ===========
typedef struct MGLTexture {
  GLuint textureNumber;
  GLubyte pixels;
  double imageWidth;
  double imageHeight;
  int textureAxes;
  int vFlip;
  int hFlip;
  double textOverhang;
  int isText;
  double displayRect[4];
  double rotation;
} MGLTexture;


// ================
// = Declarations =
// ================
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
void drawLine(CrossHairInfo *chi, int x1, int y1, int x2, int y2, int cindex);
void drawLozenge(CrossHairInfo *chi, int x, int y, int width, int height, int cindex);
void getMouseState(CrossHairInfo *chi, int *rx, int *ry, int *rstate);
int ELCALLBACK writeImage(char *outfilename, int format, EYEBITMAP *bitmap);

unsigned char *renderText(const mxArray *inputString, char*fontName, int fontSize, double *fontColor, double fontRotation, Boolean fontBold, Boolean fontItalic, Boolean fontUnderline, Boolean fontStrikethrough, int *pixelsWide, int *pixelsHigh, Rect *textImageRect);

// =============================
// = (Static) Member Variables =
// =============================
GLuint glCameraTexture;                     // Texture for camera image display
GLubyte *glCameraPixels;                    // Camera image texture contents
GLuint glTitleTexture;                      // Texture for camera title display
GLubyte *glTitlePixels;                     // Camera image texture contents
static UINT32 cameraImagePalleteMap[130+2]; // Camera image pallete mapping

#endif __MGLEYELINK_H