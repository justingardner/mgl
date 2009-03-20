#include "mgl.h"
#include <CarbonEvents.h>

////////////////////////
//   define section   //
////////////////////////
pascal OSStatus KeyboardHandler (EventHandlerCallRef  nextHandler,
                                 EventRef             theEvent
                                 void*                userData);

//////////////
//   main   //
//////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

    double waittime;
    if (nrhs==0) {
      waittime = 0.0;
    } else if (nrhs == 1) {
      // get the input argument
      if (mxGetPr(prhs[0]) != NULL)
        waittime = *mxGetPr(prhs[0]);
    }
    else {
      usageError("mglGetKeyEvent");
    }
    
    EventTypeSpec    eventTypes[1];
    EventHandlerUPP  handlerUPP;
    
    eventTypes[0].eventClass = kEventClassKeyboard;
    eventTypes[0].eventKind  = kEventRawKeyDown;
    
    handlerUPP = NewEventHandlerUPP(KeyboardHandler);
    
    InstallApplicationEventHandler (handlerUPP,
                                    1, eventTypes,
                                    NULL, NULL);

}

pascal OSStatus KeyboardHandler (EventHandlerCallRef  nextHandler,
                                 EventRef             theEvent
                                 void*                userData)
{
    
    
}                                 
