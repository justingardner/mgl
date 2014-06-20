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

// 64 bit OSes shouldn't define these so turn them off for certain systems.
#ifndef _WIN64
#define mwIndex int
#define mwSize int
#endif
    
// 64 bit Windows a 64 bit size value to store any context pointers, e.g. OpenGL, hardware, etc.
// Other platforms seem currently happy with a 32 bit value.
#ifdef _WIN64
#define MGL_CONTEXT_PTR INT64
#else
#define MGL_CONTEXT_PTR unsigned long
#endif
    
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
#ifndef __cocoa__
#define __cocoa__
#endif // ifndef __cocoa__
#endif // ifndef __carbon__
#endif // ifdef __x86_64__
#ifndef __eventtap__
#define __eventtap__
#endif

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

// used for time function
#include <mach/mach.h>
#include <mach/mach_time.h>

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

#ifdef _WIN32
#include <windows.h>
#include <GL\glew.h>
#include <GL\gl.h>
#include <GL\glu.h>
#include <GL\wglew.h>
#include <math.h>
#include <io.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <share.h>
#include <stdint.h>
#include <Dwmapi.h>

// Load the OpenGL libs.  We do this here so that people
// don't need to modify their mexopts file.
#pragma comment(lib, "glu32.lib")
#pragma comment(lib, "opengl32.lib")
#pragma comment(lib, "glew32.lib")

#define strcasecmp _stricmp
#define round(x) floor(x+0.5)

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
    // MacOS X versions <= 10.4 do not have this default defined
    // and it is needed for mglPrivateListener
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
  mwSize ndims[] = {1};
  int nfields = 1;
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
  if ((mexGetVariablePtr("global", MGL_GLOBAL_NAME) == NULL)){
    mexPrintf("(mglIsGlobal) MGL global variable does not seem to exist.\n");
    return -1;
  }
  // now get the variable
  MGL = mexGetVariable("global",MGL_GLOBAL_NAME);
  
  // get value field by number (via name)
  
  // if MGL is not struct array then there is trouble
  if ( mxGetClassID(MGL) != mxSTRUCT_CLASS){
    mexPrintf("(mglIsGlobal) MGL variable is not a struct array.\n");
    return -1;
  }
  // get field number by name; returns -1 if field does not exist
  ifield = mxGetFieldNumber(MGL,field);
  if (ifield == -1) return 0;

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
  
  // old code
  /*   // no global variable, then it ceratinly does not exist
  if (MGL == 0) return 0;
  // check to see if we have no field
  if (mxGetField(MGL,0,field) == 0) return 0;
  // or field is empty
  if (mxGetPr(mxGetField(MGL,0,field)) == NULL) return 0;
  // if we made it this far, then the field exists
  return 1; */

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

  // check to make sure it is not a cell array
  if (mxIsCell(colorArray)) {
    mexPrintf("(mglGetColor) Color input should be [g], [r g b] or [r g b a] not a cell array\n");
    return 0;
  }
      
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



#endif // #ifndef MGL_H

