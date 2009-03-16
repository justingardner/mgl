#ifdef documentation
=========================================================================

     program: mgl.h
          by: justin gardner & Jonas Larsson 
        date: 04/10/06
     purpose: header for mgl functions that includes some functions
              like standard usageError and functions to access global variables.									    
        e.g.:
  // get the global variable MGL.verbose, note
  // that if it does not exist, this creates it and
  // sets it to a default value of 0.0
  int verbose = (int)mglGetGlobalDouble("verbose");
  
  // this will set the variable MGL.double = 3.0
  mglSetGlobalDouble("double",3.0);

  // get the global variable MGL.test, note that
  // if the variable does not exist it returns a NULL pointer
  mxArray *gString = mglGetGlobalField("test");
  // check for null pointer
  if (gString == NULL)
    printf("UHOH: field test does not exist\n");
  // otherwise print out what it is set to
  else {
    char buf[256];
    mxGetString(gString,buf,256);
    printf("MGL.test = %s",buf);
  }
  // this sets MGL.test = "this is a test";
  mglSetGlobalField("test",mxCreateString("this is a test\n"));


=========================================================================
#endif

// don't include more than once
#ifndef MGL_H
#define MGL_H

/////////////////////////
// OS-independent includes
/////////////////////////
#include <mex.h>
#define mwIndex int
#define mwSize int

/////////////////////////
// OS-specific includes
/////////////////////////
#ifdef __APPLE__
//  on 64bit, default to compiling cocoa, unless overridden
#ifdef __x86_64__
#ifndef __carbon__
#ifndef __cocoa__
#define __cocoa__
#endif // ifndef __cocoa__
#endif // ifndef __carbon__
#else //__x86_64__
// for 32bit
#ifndef __carbon__
#define __cocoa__
#endif // ifndef __carbon__
#endif // ifdef __x86_64__
#ifndef __eventtap__
#define __eventtap__
#include <pthread.h>
#include <OpenGL/OpenGL.h>
#include <OpenGL/gl.h>
#include <OpenGL/glext.h>
#include <OpenGL/glu.h>
#include <ApplicationServices/ApplicationServices.h>
#include <Carbon/Carbon.h>
#include <CoreServices/CoreServices.h>
#include <AGL/agl.h>

// Cocoa specific imports.
// Necessary for the Listner code
#import <Foundation/Foundation.h>
#import <Appkit/Appkit.h>
#import <QTKit/QTKit.h>

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

////////////////
//   globals  //
////////////////
static CFMachPortRef gEventTap;
static pthread_mutex_t mut;
static eventTapInstalled = FALSE;
static NSAutoreleasePool *gPool;
static NSMutableArray *gKeyboardEventQueue;
static NSMutableArray *gMouseEventQueue;
static double gKeyStatus[MAXKEYCODES];
static unsigned char gEatKeys[MAXEATKEYS];

/////////////////////
//   queue event   //
/////////////////////
@interface queueEvent : NSObject {
    CGEventRef event;
    CGEventType type;
}
- (id)initWithEventAndType:(CGEventRef)initEvent :(CGEventType)initType;
- (CGEventRef)event;
- (CGKeyCode)keycode;
- (int)keyboardType;
- (double)timestamp;
- (CGEventType)type;
- (CGEventFlags)eventFlags;
- (int)clickState;
- (int)buttonNumber;
- (CGPoint)mouseLocation;
- (void)dealloc;
@end

///////////////////////////////
//   function declarations   //
///////////////////////////////

void* setupEventTap(void *data);
void launchSetupEventTapAsThread();
CGEventRef myCGEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon);
CGEventRef eatEvent(CGEventRef event, queueEvent *qEvent);

#endif

#endif // __APPLE__

#ifdef __linux__
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <GL/gl.h>
#include <GL/glext.h>
#include <GL/glx.h>
#include <GL/glu.h>
#include <X11/extensions/sync.h>
#include <X11/extensions/xf86vmode.h>
#include <sys/time.h>
#endif

#ifdef __WINDOWS__
#include <windows.h>
#include <GL\gl.h>
#include <GL\glu.h>
//#include <GL\glaux.h>
#include <math.h>

// Make sure that these extensions are defined.
#ifndef GL_TEXTURE_RECTANGLE_EXT
#define GL_TEXTURE_RECTANGLE_EXT 0x84F5
#endif
#ifndef GL_CLAMP_TO_EDGE
#define GL_CLAMP_TO_EDGE 0x812F
#endif
#endif


////////////////////////
//   define section   //
////////////////////////
#define MGL_GLOBAL_NAME "MGL"
#define MGL_VERSION 2.0

#ifndef mwIndex
#define mwIndex int
#endif

// older versions of OS X don't
// have kCGColorSpaceGenericRGB
#ifdef __APPLE__
    #ifndef kCGColorSpaceGenericRGB
        #define kCGColorSpaceGenericRGB kCGColorSpaceUserRGB
    #endif
    #ifndef kCGEventTapOptionDefault
        #define kCGEventTapOptionDefault 0x00000000
    #endif
#endif

///////////////////////////////
//   function declatations   //
///////////////////////////////
void usageError(char *);

// these functions get and set global variables in MGL_GLOBAL
// if get does  not find the field asked for then it returns
// a NULL pointer. (caller should check for this).
mxArray *mglGetGlobalField(char *field);
void mglSetGlobalField(char *field, mxArray *value);

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ //
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ //
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ //

// check global field: separate function for checking fields
// returns 
//     2 if field exists and is not empty
//     1 if field exists but is empty
//     0 if field does not exist
int mglCheckGlobalField(char* varname);

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ //
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ //
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ //


// these fucntions get a double value from the MGL_GLOBAL
// if get does not find the field it initializes the field
// and sets it to 0.0
double mglGetGlobalDouble(char *field);
void mglSetGlobalDouble(char *field, double value);

// this creates the global variable
void mglCreateGlobal(void);

// check to see if a global variable exists
int mglIsGlobal(char *field);

// returns the color passed in
int mglGetColor(const mxArray *colorArray, double *color);

// returns whether a window is open
int mglIsWindowOpen();


#endif // #ifndef MGL_H

