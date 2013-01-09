#include "javaMovie.h" 
#include <unistd.h>

// Cocoa specific imports.
#include <Carbon/Carbon.h>
#include <CoreServices/CoreServices.h>
#include <ApplicationServices/ApplicationServices.h>
#import <Foundation/Foundation.h>
#import <Appkit/Appkit.h>
#import <QTKit/QTKit.h>

NSWindow * startWindow();

JNIEXPORT jboolean JNICALL Java_javaMovie_initMovie(JNIEnv *env, jclass cls)
{
  printf("In javaMovie C function\n");
  printf("Is main thread: %i\n",[NSThread isMainThread]);
  // start auto release pool
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  NSWindow *myWindow = startWindow();
  
  static char* filename="bosque.mov";
  // init a QTMovie
  NSError *myError = [NSError alloc];//NULL;
  NSString *NSFilename = [[NSString alloc] initWithCString:filename];
  QTMovie *movie = [QTMovie movieWithURL: [NSURL fileURLWithPath:NSFilename] error:&myError];
  [NSFilename release];

  // see if there was an error
  if ([myError code] != 0) {
    printf("(mglPrivateMovie) Error opening movie %s: %s\n",filename,[[myError localizedDescription] cStringUsingEncoding:NSASCIIStringEncoding]);
    // release memory
    [movie release];
    // drain the pool
    [pool drain];
    return JNI_FALSE;
  }


  QTMovieView *movieView = [[QTMovieView alloc] initWithFrame:NSMakeRect(100,100,320,240)];
  //  QTMovieView *movieView = [QTMovieView alloc];
  [movieView setMovie:movie];
  [movieView setControllerVisible:YES];
  [myWindow setContentView:movieView];
  //  [[myWindow contentView] addSubview:movieView];
  [[myWindow contentView] display];
  [myWindow display];


  [[movieView movie] play];
  //  sleep(0);
  //  [movieView setAlphaValue:1];
  //  [movieView play:nil];
  //  int i;
  //  for(i = 1;i<10000000;i++) {
  //    usleep(5000000);
  //  }
  // drain the pool
  [pool drain];

  
  return 1 ? JNI_TRUE: JNI_FALSE;
}


NSWindow * startWindow()
{
  int verbose = 1;
  NSWindow *myWindow;
  int screenWidth = 600,screenHeight = 400;

  // start the application -- i.e. connect our code to the window server
  if (NSApplicationLoad() == NO)
    printf("(javaMovie:startWindow) NSApplicationLoad returned NO\n");
  else
    printf("(javaMovie:startWindow) NSApplicationLoad returned YES\n");

  // set up a pixel format for the openGL context
  NSOpenGLPixelFormatAttribute attrs[] = {
    NSOpenGLPFADoubleBuffer,
    NSOpenGLPFADepthSize, 32,
    NSOpenGLPFAStencilSize, 8,
    0
  };
  NSOpenGLPixelFormat* myPixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
  if (myPixelFormat==nil) {
    printf("(mglPrivateOpen) Could not create pixel format\n");
    return;
  }
  [myPixelFormat release];
  
  // set initial size and location
  NSRect contentRect = NSMakeRect(100,100+screenHeight,screenWidth,screenHeight);

  // create the window, if we are running desktop, then open a borderless non backing
  // store window because anything else causes problems
  myWindow = [[NSWindow alloc] initWithContentRect:contentRect styleMask:NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask|NSTexturedBackgroundWindowMask backing:NSBackingStoreBuffered defer:false];
    
  if (myWindow==nil) {
    printf("(mglPrivateOpen) Could not create window\n");
    return;
  }
  //  if (verbose) printf("(mglPrivateOpen) Created window: %x\n",(unsigned int)myWindow);

  // center the window
  [myWindow center];
  [myWindow setAlphaValue:0.8];

  // sleep for 5000 micro seconds. The window manager appears to need a little bit of time
  // to create the window. There should be a function call to check the window status
  // but, I don't know what it is. The symptom is that if we don't wait here, then
  // the screen comes up in white and then doesn't have the GLContext set properly.
  usleep(5000);

  // show window
  if (verbose) printf("(mglPrivateOpen) Order window\n");
  [myWindow orderFront:nil];
  if (verbose) printf("(mglPrivateOpen) Display window\n");
  [myWindow display];
  if (verbose) printf("(mglPrivateOpen) Window isVisible:%i\n",[myWindow isVisible]);

  if (verbose) printf("(mglPrivateOpen) Hiding task and menu bar\n");
  OSStatus setSystemUIModeStatus = SetSystemUIMode(kUIModeAllHidden,kUIOptionAutoShowMenuBar|kUIOptionDisableAppleMenu);

  // order the window in front if called for
  if (verbose) printf("(mglPrivateOpen) Ordering window in front\n");
  // would like to order in front of task and menu bar, 
  // but can't seem to do that... tried the following
  //[myWindow makeMainWindow];
  [myWindow orderFrontRegardless];
  //[myWindow orderFront:nil];
  //[myWindow makeKeyAndOrderFront];

  return(myWindow);
}
