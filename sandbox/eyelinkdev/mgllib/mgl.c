#include "mgl.h"

/////////////////////////
//   mglIsWindowOpen   //
/////////////////////////
int mglIsWindowOpen()
{
  // check global variable for whether display number exisits
  // or if it is set to -1
    if ((mglIsGlobal("displayNumber")==-1) || (mglGetGlobalDouble("displayNumber") == -1)) 
        return 0;
    else
        return 1;
}



////////////////////
//   usageError   //
////////////////////
void usageError(char *functionName) 
{
    mxArray *callInput[] = {mxCreateString(functionName)};
    mexCallMATLAB(0,NULL,1,callInput,"help");
}

/////////////////////////
//   mglCreateGlobal   //
/////////////////////////
void mglCreateGlobal(void)
{
    int ndims[] = {1};int nfields = 1;
    const char *field_names[] = {"version"};

  // create the global with version number set
    mexPutVariable("global",MGL_GLOBAL_NAME,mxCreateStructArray(1,ndims,nfields, field_names));

  // set the version number
    mglSetGlobalDouble("version",MGL_VERSION);
}

//////////////////////////
//   mglGetGlobalDouble //
//////////////////////////
int mglIsGlobal(char *field)
{
    mxArray *MGL, *tmp;
    int ifield;

  // check if MGL exists in global workspace - if not return right away
    if ((mexGetVariablePtr("global", MGL_GLOBAL_NAME) == NULL)) 
    {
        mexPrintf("(mglIsGlobal) MGL global variable does not seem to exist.\n");
        return -1;
    }
  // now get the variable
    MGL = mexGetVariable("global",MGL_GLOBAL_NAME);

  // get value field by number (via name)

  // if MGL is not struct array then there is trouble
    if ( mxGetClassID(MGL) != mxSTRUCT_CLASS)
    {
        mexPrintf("(mglIsGlobal) MGL variable is not a struct array.\n");
        return -1;
    }
  // get field number by name; returns -1 if field does not exist
    ifield = mxGetFieldNumber(MGL,field);

  // check whether it is empty:
    tmp = mxGetFieldByNumber(MGL, (mwIndex)0, ifield);

  // check to see if field exists and not empty
    if ((ifield != -1) && (tmp != NULL))
    {  // [present and full]
        return  1;
    } 
    if ((ifield != -1) && (tmp == NULL)) 
    { // [present but empty]
        return  0;
    }
    else { // [not present]    
        return 0;
    }

}
//////////////////////////
//   mglGetGlobalDouble //
//////////////////////////
double mglGetGlobalDouble(char *varname)
{
    mxArray *MGL, *value;
    double tmpvalue,
        defaultValue = 0.0;;

    MGL = mexGetVariable("global",MGL_GLOBAL_NAME);

  // default value for when variable has not been set
    if (strcmp(varname,"displayNumber")==0) defaultValue = -1.0;

  // global has not been created
    if ( (mexGetVariablePtr("global", MGL_GLOBAL_NAME) == NULL) || ( mxGetClassID(MGL) != mxSTRUCT_CLASS)) {
    // create the global
        mglCreateGlobal();
    // now create the asked for variable
        mglSetGlobalDouble(varname,defaultValue);
        return defaultValue; // initialize new fields with -1
    }

  // check to see if field exists
    if (mglCheckGlobalField(varname) == 2){
    // if it does return the value
    // suggested change for macintel
        value = mxGetField(MGL,0,varname);
        tmpvalue = mxGetScalar(value); 
        return tmpvalue;
    }
    else {
    // does not exist, set asked for variable
        mglSetGlobalDouble(varname,defaultValue);
        return defaultValue;
    }
}

/////////////////////////
//   mglGetGlobalField //
/////////////////////////
mxArray *mglGetGlobalField(char *varname)
{
    mxArray *MGL = mexGetVariable("global",MGL_GLOBAL_NAME);

  // global has not been created
    if ( (mexGetVariablePtr("global", MGL_GLOBAL_NAME) == NULL) || ( mxGetClassID(MGL) != mxSTRUCT_CLASS)){
    // create the global
        mglCreateGlobal();
    }

  // check to see if field exists
    if (mglCheckGlobalField(varname) == 2)
    // if it does return the value
        return mxGetField(MGL,0,varname);
    else {
        return NULL;
    }
}

//////////////////////////
//   mglSetGlobalDouble //
//////////////////////////
void mglSetGlobalDouble(char *varname,double value)
{
    mxArray *MGL, *tmpvalue; 
  //double *mglFieldPointer;

    MGL = mexGetVariable("global",MGL_GLOBAL_NAME);

  // global has not been created
  // if ((MGL == 0)) { // || (mxGetPr(MGL) == 0)){
    if ( (mexGetVariablePtr("global", MGL_GLOBAL_NAME) == NULL) || (MGL == 0) ){
    // create the global
        mglCreateGlobal();
        MGL = mexGetVariable("global",MGL_GLOBAL_NAME);
    }

  // check to see if field exists
    if (mglCheckGlobalField(varname) == 0){
    // if it doesn't then add it.
        mxAddField(MGL,varname);
        mxSetField(MGL,0,varname,mxCreateDoubleMatrix(1, 1, mxREAL));
    }

  // check if field is empty
    if (mglCheckGlobalField(varname) == 1){
    // if so resize it
        mxSetField(MGL,0,varname,mxCreateDoubleMatrix(1, 1, mxREAL));    
    }  


  // suggested change for macintel
    tmpvalue = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(tmpvalue) = value; // pass value into it.
    mxSetField(MGL,0,varname,tmpvalue);

  /*
  // replaces this code
  // now get the field pointer
    mglFieldPointer = (double*)mxGetPr(mxGetField(MGL, 0, varname));
  // and set it
    *mglFieldPointer = value;
    mexPrintf("varname: %s, value: %e\n", varname, value);
  */

  // write the global variable back
    mexPutVariable("global",MGL_GLOBAL_NAME,MGL);
}

/////////////////////////
//   mglSetGlobalField //
/////////////////////////
void mglSetGlobalField(char *varname, mxArray *value)
{
    mxArray *MGL = mexGetVariable("global",MGL_GLOBAL_NAME);

  // global has not been created
    if ((MGL == 0) || (mexGetVariablePtr("global", MGL_GLOBAL_NAME) == NULL)){
    // create the global
        mglCreateGlobal();
        MGL = mexGetVariable("global",MGL_GLOBAL_NAME);
    }

  // check to see if field exists
    if (mglCheckGlobalField(varname) == 0){
    // if it doesn't then add it.
        mxAddField(MGL,varname);
    }
  // now set the field 
    mxSetField(MGL,0,varname,value);

  // write the global variable back
    mexPutVariable("global",MGL_GLOBAL_NAME,MGL);
}

///////////////////////////////////////////
//   get color from passed in argument   //
///////////////////////////////////////////
int mglGetColor(const mxArray *colorArray, double *color)
{
    double *colorPtr;

    switch (mxGetN(colorArray)) {
    // if the argument is a single number
    // then set to that level of gray
        case 1:
        colorPtr = (double*)mxGetPr(colorArray);
        if (colorPtr[0] > 1) colorPtr[0] = colorPtr[0]/255.0;
        color[0] = colorPtr[0];
        color[1] = colorPtr[0];
        color[2] = colorPtr[0];
        color[3] = 1;
        break;
    // if the argument is an array of 3
    // then set to that color triplet
        case 3:
        colorPtr = (double*)mxGetPr(colorArray);
        if ((colorPtr[0] > 1) || (colorPtr[1] > 1) || (colorPtr[2] > 1)) {
            colorPtr[0] = colorPtr[0]/255.0;
            colorPtr[1] = colorPtr[1]/255.0;
            colorPtr[2] = colorPtr[2]/255.0;
        }
        color[0] = colorPtr[0];
        color[1] = colorPtr[1];
        color[2] = colorPtr[2];
        color[3] = 1;
        break;
    // if the argument is an array of 4
    // then set to that color triplet plus alpha
        case 4:
        colorPtr = (double*)mxGetPr(colorArray);
        if ((colorPtr[0] > 1) || (colorPtr[1] > 1) || (colorPtr[2] > 1)) {
            colorPtr[0] = colorPtr[0]/255.0;
            colorPtr[1] = colorPtr[1]/255.0;
            colorPtr[2] = colorPtr[2]/255.0;
        }
        color[0] = colorPtr[0];
        color[1] = colorPtr[1];
        color[2] = colorPtr[2];
        color[3] = colorPtr[3];
        break;
        default:
      // strange, return 0 since this isn't a known color format
        mexPrintf("(mglGetColor) UHOH: Color input should be [g], [r g b] or [r g b a]\n");
        return 0;
        break;
    }
    return 1;
}


// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ //
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ //
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ //
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ //

int mglCheckGlobalField(char* varname) {

  /*  this function replaces a chunk of code that checks whether a
    field in a struct array exists and is empty:

    if ((mxGetField(MGL,0,varname) != 0) &&  \
        (mxGetPr(mxGetField(MGL,0,varname)) != NULL))

        on macintel the above code causes a crash in matlab/

        returns 
        0 if the global is not a struct array
        0 if the asked for field does not exist
        1 if the field is present but empty
        2 if the field is present and filled


        ds 2006-10-13
*/

        mxArray *MGL, *tmp;
    int ifield;

  // check if MGL exists in global workspace - if not create it
    if ((mexGetVariablePtr("global", MGL_GLOBAL_NAME) == NULL) ){
        mglCreateGlobal();
    }

    MGL = mexGetVariable("global",MGL_GLOBAL_NAME);

  // check that the global is a struct array
    if ( mxGetClassID(MGL) != mxSTRUCT_CLASS) {
        mglCreateGlobal();
        return 0; 
    }

  // get field number by name; mxGetFieldNumber returns -1 if field does not exist
    ifield = mxGetFieldNumber(MGL,varname);
  // return if field doesn't exist
    if (ifield < 0)  return 0;

  // otherwise check whether it is empty:
    tmp = mxGetFieldByNumber(MGL, (mwIndex)0, ifield);

  // check to see if field exists and not empty
    if ((ifield != -1) && (tmp != NULL))
    { // present and field full
        return  2;
    } 
    else if (tmp != NULL) 
    { // present but field empty 
        return  1;
    }
    else { // field does not exist
        return 0;
    }
} // end function

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ //
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ //
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ //
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ //


// ==================================================================
// = This is the location of c functions that are used in mex files =
// ==================================================================

// =================
// = EVENTTAP Code =
// =================
#ifdef __eventtap__

///////////////////////
//   setupEventTap   //
///////////////////////
void* setupEventTap(void *data)
{
    CGEventMask        eventMask;
    CFRunLoopSourceRef runLoopSource;

  // Create an event tap. We are interested in key presses and mouse presses
    eventMask = ((1 << kCGEventKeyDown) | (1 << kCGEventKeyUp) | (1 << kCGEventLeftMouseDown) | (1 << kCGEventRightMouseDown));
  //  gEventTap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, kCGEventTapOptionListenOnly, eventMask, myCGEventCallback, NULL);
    gEventTap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, kCGEventTapOptionDefault, eventMask, myCGEventCallback, NULL);

  // see if it was created properly
    if (!gEventTap) {
        mexPrintf("(mglPrivateListener) Failed to create event tap\n");
        return NULL;
    }

  // Create a run loop source.
    runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, gEventTap, 0);

  // Add to the current run loop.
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);

  // Enable the event tap.
    CGEventTapEnable(gEventTap, true);

  // see if it is enable
    if (!CGEventTapIsEnabled(gEventTap)) {
        mexPrintf("(mglPrivateListener) Failed to enable event tap\n");
        return NULL;
    }


  // set up run loop
    CFRunLoopRun();

    return NULL;
}

////////////////////////
//   event callback   //
////////////////////////
CGEventRef myCGEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon)
{
  // check for keyboard event
    if (type == kCGEventKeyDown) {
    // record the event in the globals, first lock the mutex
    // to avoid concurrent access to the global variables
        pthread_mutex_lock(&mut);
    // save the event in the queue
        queueEvent *qEvent;
        qEvent = [[queueEvent alloc] initWithEventAndType:event :type];
        [gKeyboardEventQueue addObject:qEvent];
    // also save the keystatus
        if ([qEvent keycode] <= MAXKEYCODES)
            gKeyStatus[[qEvent keycode]-1] = [qEvent timestamp];
    // check for edible keycode (i.e. one that we don't want to return)
        event = eatEvent(event,qEvent);
    // release qEvent as it is now in the keyboard event queue
        [qEvent release];
    // unlock mutex
        pthread_mutex_unlock(&mut);

    }
    else if (type == kCGEventKeyUp) {
    // remove the key from the gKeyStatus
        pthread_mutex_lock(&mut);
    // convert to a queueEvent to get fields easier
        queueEvent *qEvent;
        qEvent = [[queueEvent alloc] initWithEventAndType:event :type];
    // set the gKeyStatus back to 0
        if ([qEvent keycode] <= MAXKEYCODES)
            gKeyStatus[[qEvent keycode]-1] = 0;
    // check for edible keycode (i.e. one that we don't want to return)
        event = eatEvent(event,qEvent);
    // release qEvent
        [qEvent release];
    // unlock mutex
        pthread_mutex_unlock(&mut);
    }
    else if ((type == kCGEventLeftMouseDown) || (type == kCGEventRightMouseDown)){
    // record the event in the globals, first lock the mutex
    // to avoid concurrent access to the global variables
        pthread_mutex_lock(&mut);
    // save the event in the queue
        queueEvent *qEvent;
        qEvent = [[queueEvent alloc] initWithEventAndType:event :type];
        [gMouseEventQueue addObject:qEvent];
    // unlock mutex
        pthread_mutex_unlock(&mut);
    }

  // return the event for normal OS processing
    return event;
}

//////////////////
//   eatEvent   //
//////////////////
CGEventRef eatEvent(CGEventRef event, queueEvent *qEvent)
{
    int i = 0;
  // check if keyup or keydown event
    if (([qEvent type] == kCGEventKeyDown) || ([qEvent type] == kCGEventKeyDown)) {
    // now check to make sure there is no modifier flag (i.e. always
    // let key events when a modifier key is down through)
        if (!([qEvent eventFlags] & (kCGEventFlagMaskShift | kCGEventFlagMaskControl | kCGEventFlagMaskAlternate | kCGEventFlagMaskCommand | kCGEventFlagMaskAlphaShift))) {
      // now check to see if the keyCode matches one that we are
      // supposed to eat.
            while (gEatKeys[i] && (i < MAXEATKEYS)) {
                if (gEatKeys[i++] == (unsigned char)[qEvent keycode]){
      // then eat the event (i.e. it will not be sent to any application)
                    event = NULL;
                }
            }
        }
    // if we are not going to eat the key event, then we should stop eating keys
        if (event != NULL) gEatKeys[0] = 0;
    }
  // return the event (this may be NULL if we have decided to eat the event)
    return event;
}
/////////////////////////////////////
//   launchSetupEventTapAsThread   //
/////////////////////////////////////
void launchSetupEventTapAsThread()
{
  // Create the thread using POSIX routines.
    pthread_attr_t  attr;
    pthread_t       posixThreadID;

    pthread_attr_init(&attr);
    pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);

    int threadError = pthread_create(&posixThreadID, &attr, &setupEventTap, NULL);

    pthread_attr_destroy(&attr);
    if (threadError != 0)
        mexPrintf("(mglPrivateListener) Error could not setup event tap thread: error %i\n",threadError);
}

///////////////////////////////////
//   queue event implementation  //
///////////////////////////////////
@implementation queueEvent 
- (id)initWithEventAndType:(CGEventRef)initEvent :(CGEventType)initType
{
  // init parent
    [super init];
  // set internals
    event = CGEventCreateCopy(initEvent);
    type = initType;
  //return self
    return self;
}
- (CGEventRef)event
{
    return event;
}
- (CGEventType)type
{
    return type;
}
- (CGKeyCode)keycode
{
    return (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode)+1;
}
- (int)keyboardType
{
    return (int)CGEventGetIntegerValueField(event, kCGKeyboardEventKeyboardType);
}
- (double)timestamp
{
    return (double)CGEventGetTimestamp(event)/1e9;
}
- (CGEventFlags)eventFlags
{
    return (double)CGEventGetFlags(event);
}
- (int)clickState
{
    return CGEventGetIntegerValueField(event, kCGMouseEventClickState);
}
- (int)buttonNumber
{
    return CGEventGetIntegerValueField(event, kCGMouseEventButtonNumber)+1;
}
- (CGPoint)mouseLocation
{
    return CGEventGetLocation(event);
}
- (void)dealloc
{
    CFRelease(event);
    [super dealloc];
}
@end

#endif