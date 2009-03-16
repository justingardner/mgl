#ifdef documentation
=========================================================================

    program: mglPrivateInstallListener.c
    by: justin gardner
    copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
    date: 06/18/08
    purpose: Installs an event-tap to get keyboard events. Event-taps are
    a low level accessibilty function that gets keyboard/mouse
    events at a very low level (before application windows). We
    intall a "listener" which is a callback that is called every
    time there is a new event. This listener is run in a separate
    thread and stores the keyboard and mouse events using an
    objective-c based NSMutableArray. Then recalling this function
    returns the events for processing with mgl.
    =========================================================================
#endif

/////////////////////////
//   include section   //
/////////////////////////
#include "mgl.h"

//-----------------------------------------------------------------------------------///
// **************************** mac cocoa specific code  **************************** //
//-----------------------------------------------------------------------------------///
#ifdef __eventtap__

//////////////
//   main   //
//////////////
    void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  // start auto release pool
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
  // get which command this is
    int command = mxGetScalar(prhs[0]);
    
    int i;
    CGKeyCode keycode;
    double timestamp;
    CGEventType type;
    CGEventFlags eventFlags;
    CGEventRef event;
    int keyboardType;
    
  // INIT command -----------------------------------------------------------------
    if (command == INIT) {
    // return argument set to 0
        plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
        *mxGetPr(plhs[0]) = 0;
        
    // start the thread that will have a callback that gets called every
    // time there is a keyboard or mouse event of interest
        if (!eventTapInstalled) {
      // first check if the accessibility API is enabled, cause otherwise we are F*&%ed.
            if (!AXAPIEnabled()) {
                mexPrintf("(mglPrivateListener) **WARNING** To get keyboard events, you must"
                    "have the Accessibility API enabled. From System Preferences open Universal"
                    "Access and make sure that \"Enable access for assistive devices\" is checked"
                    """**WARNING **\n"); 
                int ret = NSRunAlertPanel (@"To get keyboard events, you"
                    "must have the Accessibility API enabled. Would you like to launch System"
                    "Preferences so that you can turn on \"Enable access for assistive devices\".",
                    @"", @"OK",@"", @"Cancel"); switch (ret) { case NSAlertDefaultReturn:
                    [[NSWorkspace sharedWorkspace]
                        openFile:@"/System/Library/PreferencePanes/UniversalAccessPref.prefPane"];
      // busy wait until accessibility is activated
                    while (!AXAPIEnabled());
                    break;
                    default:
                    [pool drain];
                    return;
                    break;
                }
            }
      // init pthread_mutex
            pthread_mutex_init(&mut,NULL);
      // init the event queue
            gPool = [[NSAutoreleasePool alloc] init];
            gKeyboardEventQueue = [[NSMutableArray alloc] init];
            gMouseEventQueue = [[NSMutableArray alloc] init];
      // default to no keys to eat
            gEatKeys[0] = 0;
      // set up the event tap
            launchSetupEventTapAsThread();
      // and remember that we have an event tap thread running
            eventTapInstalled = TRUE;
      // and clear the gKeyStatus array
            for (i = 0; i < MAXKEYCODES; i++)
                gKeyStatus[i] = 0;
            mexPrintf("(mglPrivateListener) Starting keyboard and mouse event tap. End with mglListener('quit').\n");
      // started running, return 1
            *mxGetPr(plhs[0]) = 1;
        }
        else {
      // already running, return 1
            *mxGetPr(plhs[0]) = 1;
        }
    }
  // GETKEYEVENT command ----------------------------------------------------------
    else if (command == GETKEYEVENT) {
        if (eventTapInstalled) {
      // get the last event.
            pthread_mutex_lock(&mut);
      // see how many events we have
            unsigned count = [gKeyboardEventQueue count];
      // if we have more than one,
            if (count >= 1) {
                queueEvent *qEvent;
    // get the last event
                qEvent = [gKeyboardEventQueue objectAtIndex:0];
    // and get the keycode,flags and timestamp
                keycode = [qEvent keycode];
                timestamp = [qEvent timestamp];
                eventFlags = [qEvent eventFlags];
                keyboardType = [qEvent keyboardType];
    // remove it from the queue
                [gKeyboardEventQueue removeObjectAtIndex:0];
    // release the mutex
                pthread_mutex_unlock(&mut);
    // return event as a matlab structure
                const char *fieldNames[] =  {"when","keyCode","shift","control","alt","command","capslock","keyboard"};
                int outDims[2] = {1, 1};
                plhs[0] = mxCreateStructArray(1,outDims,8,fieldNames);
                
                mxSetField(plhs[0],0,"when",mxCreateDoubleMatrix(1,1,mxREAL));
                *(double*)mxGetPr(mxGetField(plhs[0],0,"when")) = timestamp;
                mxSetField(plhs[0],0,"keyCode",mxCreateDoubleMatrix(1,1,mxREAL));
                *(double*)mxGetPr(mxGetField(plhs[0],0,"keyCode")) = (double)keycode;
                mxSetField(plhs[0],0,"shift",mxCreateDoubleMatrix(1,1,mxREAL));
                *(double*)mxGetPr(mxGetField(plhs[0],0,"shift")) = (double)(eventFlags&kCGEventFlagMaskShift) ? 1:0;
                mxSetField(plhs[0],0,"control",mxCreateDoubleMatrix(1,1,mxREAL));
                *(double*)mxGetPr(mxGetField(plhs[0],0,"control")) = (double)(eventFlags&kCGEventFlagMaskControl) ? 1:0;
                mxSetField(plhs[0],0,"alt",mxCreateDoubleMatrix(1,1,mxREAL));
                *(double*)mxGetPr(mxGetField(plhs[0],0,"alt")) = (double)(eventFlags&kCGEventFlagMaskAlternate) ? 1:0;
                mxSetField(plhs[0],0,"command",mxCreateDoubleMatrix(1,1,mxREAL));
                *(double*)mxGetPr(mxGetField(plhs[0],0,"command")) = (double)(eventFlags&kCGEventFlagMaskCommand) ? 1:0;
                mxSetField(plhs[0],0,"capslock",mxCreateDoubleMatrix(1,1,mxREAL));
                *(double*)mxGetPr(mxGetField(plhs[0],0,"capslock")) = (double)(eventFlags&kCGEventFlagMaskAlphaShift) ? 1:0;
                mxSetField(plhs[0],0,"keyboard",mxCreateDoubleMatrix(1,1,mxREAL));
                *(double*)mxGetPr(mxGetField(plhs[0],0,"keyboard")) = (double)keyboardType;
            }
            else {
    // no event found, unlock mutex and return empty
                pthread_mutex_unlock(&mut);
                plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
            }
        }
        else {
            mexPrintf("(mglPrivateListener) mglPrivateListener must be initialized before extracting keyboard events\n");
            plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
        }
        
    }
  // GETALLKEYEVENTS command ----------------------------------------------------------
    else if (command == GETALLKEYEVENTS) {
        if (eventTapInstalled) {
            pthread_mutex_lock(&mut);
      // see how many events we have
            unsigned count = [gKeyboardEventQueue count];
      // if we have more than one,
            if (count > 0) {
                int i = 0;
    // return event as a matlab structure
                const char *fieldNames[] =  {"when","keyCode"};
                int outDims[2] = {1, 1};
                plhs[0] = mxCreateStructArray(1,outDims,2,fieldNames);

                mxSetField(plhs[0],0,"when",mxCreateDoubleMatrix(1,count,mxREAL));
                double *timestampOut = (double*)mxGetPr(mxGetField(plhs[0],0,"when"));
                mxSetField(plhs[0],0,"keyCode",mxCreateDoubleMatrix(1,count,mxREAL));
                double *keycodeOut = (double*)mxGetPr(mxGetField(plhs[0],0,"keyCode"));
                while (count--) {
                    queueEvent *qEvent;
      // get the last event
                    qEvent = [gKeyboardEventQueue objectAtIndex:0];
      // and get the keycode,flags and timestamp
                    keycodeOut[i] = [qEvent keycode];
                    timestampOut[i++] = [qEvent timestamp];
      // remove it from the queue
                    [gKeyboardEventQueue removeObjectAtIndex:0];
                }
    // release the mutex
                pthread_mutex_unlock(&mut);
            }
            else {
    // no event found, unlock mutex and return empty
                pthread_mutex_unlock(&mut);
                plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
            }
        }
        else {
            mexPrintf("(mglPrivateListener) mglPrivateListener must be initialized before extracting keyboard events\n");
            plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
        }
        
    }
  // GETMOUSEEVENT command --------------------------------------------------------
    else if (command == GETMOUSEEVENT) {
        if (eventTapInstalled) {
      // get the last event.
            pthread_mutex_lock(&mut);
      // see how many events we have
            unsigned count = [gMouseEventQueue count];
      // if we have more than one,
            if (count >= 1) {
                queueEvent *qEvent;
    // get the last event
                qEvent = [gMouseEventQueue objectAtIndex:0];
    // and get the clickState, buttonNumber, timestamp and location
                int clickState = [qEvent clickState];
                int buttonNumber = [qEvent buttonNumber];
                timestamp = [qEvent timestamp];
                CGPoint mouseLocation = [qEvent mouseLocation];
    // remove it from the queue
                [gMouseEventQueue removeObjectAtIndex:0];
    // release the mutex
                pthread_mutex_unlock(&mut);
    // return event as a matlab structure
                const char *fieldNames[] =  {"when","buttons","x","y","clickState"};
                int outDims[2] = {1, 1};
                plhs[0] = mxCreateStructArray(1,outDims,5,fieldNames);

                mxSetField(plhs[0],0,"when",mxCreateDoubleMatrix(1,1,mxREAL));
                *(double*)mxGetPr(mxGetField(plhs[0],0,"when")) = timestamp;
                mxSetField(plhs[0],0,"buttons",mxCreateDoubleMatrix(1,1,mxREAL));
                *(double*)mxGetPr(mxGetField(plhs[0],0,"buttons")) = (double)buttonNumber;
                mxSetField(plhs[0],0,"x",mxCreateDoubleMatrix(1,1,mxREAL));
                *(double*)mxGetPr(mxGetField(plhs[0],0,"x")) = (double)mouseLocation.x;
                mxSetField(plhs[0],0,"y",mxCreateDoubleMatrix(1,1,mxREAL));
                *(double*)mxGetPr(mxGetField(plhs[0],0,"y")) = (double)mouseLocation.y;
                mxSetField(plhs[0],0,"clickState",mxCreateDoubleMatrix(1,1,mxREAL));
                *(double*)mxGetPr(mxGetField(plhs[0],0,"clickState")) = (double)clickState;
            }
            else {
    // no event found, unlock mutex and return empty
                pthread_mutex_unlock(&mut);
                plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
            }
        }
        else {
            mexPrintf("(mglPrivateListener) mglPrivateListener must be initialized before extracting mouse events\n");
            plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
        }
        
    }
  // GETALLMOUSEEVENTS command --------------------------------------------------------
    else if (command == GETALLMOUSEEVENTS) {
        if (eventTapInstalled) {
      // get all pending events
            pthread_mutex_lock(&mut);
      // see how many events we have
            unsigned count = [gMouseEventQueue count];
      // if we have more than one,
            if (count > 0) {
                int i = 0;
    // return event as a matlab structure
                const char *fieldNames[] =  {"when","buttons","x","y","clickState"};
                int outDims[2] = {1, 1};
                plhs[0] = mxCreateStructArray(1,outDims,5,fieldNames);
                
                mxSetField(plhs[0],0,"when",mxCreateDoubleMatrix(1,count,mxREAL));
                double *when = (double*)mxGetPr(mxGetField(plhs[0],0,"when"));
                mxSetField(plhs[0],0,"buttons",mxCreateDoubleMatrix(1,count,mxREAL));
                double *buttonNumber = (double*)mxGetPr(mxGetField(plhs[0],0,"buttons"));
                mxSetField(plhs[0],0,"x",mxCreateDoubleMatrix(1,count,mxREAL));
                double *x = (double*)mxGetPr(mxGetField(plhs[0],0,"x"));
                mxSetField(plhs[0],0,"y",mxCreateDoubleMatrix(1,count,mxREAL));
                double *y = (double*)mxGetPr(mxGetField(plhs[0],0,"y"));
                mxSetField(plhs[0],0,"clickState",mxCreateDoubleMatrix(1,count,mxREAL));
                double *clickState = (double*)mxGetPr(mxGetField(plhs[0],0,"clickState"));
    // if we have more than one,
                while (count--) {
                    queueEvent *qEvent;
      // get the last event
                    qEvent = [gMouseEventQueue objectAtIndex:0];
      // and get the clickState, buttonNumber, timestamp and location
                    clickState[i] = [qEvent clickState];
                    buttonNumber[i] = [qEvent buttonNumber];
                    when[i] = [qEvent timestamp];
                    CGPoint mouseLocation = [qEvent mouseLocation];
                    x[i] = mouseLocation.x;
                    y[i++] = mouseLocation.y;
      // remove it from the queue
                    [gMouseEventQueue removeObjectAtIndex:0];
                }
    // release the mutex
                pthread_mutex_unlock(&mut);
            }
            else {
    // no event found, unlock mutex and return empty
                pthread_mutex_unlock(&mut);
                plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
            }
        }
        else {
            mexPrintf("(mglPrivateListener) mglPrivateListener must be initialized before extracting mouse events\n");
            plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
        }
        
    }
  // GETKEYS command --------------------------------------------------------
    else if (command == GETKEYS) {
        plhs[0] = mxCreateDoubleMatrix(1,MAXKEYCODES,mxREAL);
        double *outptr = mxGetPr(plhs[0]);
        for (i = 0; i < MAXKEYCODES; i++)
            outptr[i] = gKeyStatus[i];
    }
  // GETKEYEVENT command ----------------------------------------------------------
    else if (command == EATKEYS) {
    // return argument
        plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
    // check if eventTap is installed
        if (eventTapInstalled) {
      // get the keycodes that are to be eaten
            int nkeys = MIN(mxGetNumberOfElements(prhs[1]),MAXEATKEYS);
            double *keyCodesToEat = (double*)mxGetPr(prhs[1]);
      // get the mutex
            pthread_mutex_lock(&mut);
            int i;
            mexPrintf("(mglPrivateListener) Eating all keypresses with keycodes: ");
            for (i = 0;i < nkeys;i++) {
                mexPrintf("%i ",(int)keyCodesToEat[i]);
                gEatKeys[i] = (unsigned char)(int)keyCodesToEat[i];
            }
            mexPrintf("\n");
            gEatKeys[nkeys] = 0;
      // release the mutex
            pthread_mutex_unlock(&mut);
      // return argument set to 1
            *mxGetPr(plhs[0]) = 1;
        }
        else {
            mexPrintf("(mglPrivateListener) Cannot eat keys if listener is not installed\n");
      // return argument set to 0
            *mxGetPr(plhs[0]) = 0;
        }
    }
  // QUIT command -----------------------------------------------------------------
    else if (command == QUIT) {
    // return argument set to 0
        plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
        *mxGetPr(plhs[0]) = 0;
        
    // disable the event tap
        if (eventTapInstalled) {
      // Disable the event tap.
            CGEventTapEnable(gEventTap, false);
            
      // shut down event loop
            CFRunLoopStop(CFRunLoopGetCurrent());
            
      // release the event queue
            [gPool drain];
            
      // set flag to not installed
            eventTapInstalled = FALSE;
            
      // destroy mutex
            pthread_mutex_destroy(&mut);
            
      // message to user
            mexPrintf("(mglPrivateListener) Ending keyboard and mouse event tap\n");
        }
    }
    [pool drain];
    
}


#else// __eventtap__
//-----------------------------------------------------------------------------------///
// ***************************** other-os specific code  **************************** //
//-----------------------------------------------------------------------------------///
// THIS FUNCTION IS ONLY FOR MAC COCOA
//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
    *(double*)mxGetPr(plhs[0]) = 0;
}
#endif

