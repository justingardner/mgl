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
// #include <CarbonEvents.h>
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

#define ALIGNLEFT -1
#define ALIGNCENTER 0
#define ALIGNRIGHT 1
#define ALIGNTOP -1
#define ALIGNBOTTOM 1
#define DEFAULT_H_ALIGNMENT ALIGNCENTER
#define DEFAULT_V_ALIGNMENT ALIGNCENTER
#define XY 1
#define YX 0

#ifdef __eventtap__

////////////////////////
//   define section   //
////////////////////////
#define TRUE 1
#define FALSE 0
#define INIT 1
#define GETKEYEVENT 2
#define GETMOUSEEVENT 3
#define QUIT 0
#define GETKEYS 4
#define GETALLKEYEVENTS 5
#define GETALLMOUSEEVENTS 6
#define EATKEYS 7
#define MAXEATKEYS 256
#define MAXKEYCODES 128

#endif

// ===========
// = Structs =
// ===========
typedef struct MGLKeyEvent {
    INT16 charCode;
    INT16 keyCode;
    INT16 keyboard;
    INT16 when;
} MGLKeyEvent;

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
int ELCALLBACK writeImage(char *outfilename, IMAGETYPE format, EYEBITMAP *bitmap);

int mglcGetKeys();
char *keycodeToChar(UInt16 keycode);
void setupGeyKeyCallback();
CGEventRef myCGEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon);
INT16 mglcGetKeyEvent(MGLKeyEvent *mglKey);

unsigned char *renderText(char *cInputString, char*fontName, int fontSize, double *fontColor, double fontRotation, Boolean fontBold, Boolean fontItalic, Boolean fontUnderline, Boolean fontStrikethrough, int *pixelsWide, int *pixelsHigh, Rect *textImageRect);

// Structure to encapsulate some of the calibration target parameters.
typedef struct 
{
  double innerRGB[3];
  double outerRGB[3];
} CalibrationTarget;

// =============================
// = (Static) Member Variables =
// =============================
static char cameraTitle[1024];
static int cameraPos[2];
static int titlePos[4] = {551, 100, 0, 0};
static UINT32 cameraImagePalleteMap[130+2]; // Camera image pallete mapping
static int mglcDisplayNumber;
static int mglcFrameNumber = 0;

static CFMachPortRef gEventTap;

static int keyDownEvent = 0;
static int eventKeyCode = 0;
static CGEventFlags eventKeyFlags;

mxArray *cameraTexture;
GLubyte *cameraImageBuffer = NULL;
GLenum cameraTextureType = 0;
GLuint cameraTextureNumber = 0;
GLubyte cameraImageColormap[256][3];

double screenCenterX;
double screenCenterY;

static CalibrationTarget _calTarget;

#endif __MGLEYELINK_H

