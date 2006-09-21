/*********************************************************************
*
* C Example program:
*    readDigPort.c
*
* Example Category:
*    DI
*
* Description:
*    This example demonstrates how to read values from a digital input
*    channel.
*
* Instructions for Running:
*    1. Select the digital ports on the DAQ device to be read.
*
* Steps:
*    1. Create a task.
*    2. Create a Digital Input channel.
*    3. Call the Start function to start the task.
*    4. Read the digital uInt8 array data. This read function
*       reads a single sample of digital data on demand, so no timeout
*       is necessary.
*    5. Call the Clear Task function to clear the Task.
*    6. Display an error if any..
*
*********************************************************************/
/////////////////////////
//   include section   //
/////////////////////////
#include "/Applications/National Instruments/NI-DAQmx Base/includes/NIDAQmxBase.h"
#include <stdio.h>
#include "mex.h"

////////////////////////
//   define section   //
////////////////////////
#define DAQmxErrChk(functionCall) { if( DAQmxFailed(error=(functionCall)) ) { goto Error; } }

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   // Task parameters
   int32       error = 0;
   TaskHandle  taskHandle = 0;
   char        errBuff[2048];

   // Channel parameters
   const char  chan[] = "Dev1/port2";

   // write variables
   int32       written;

   // pointer to output data
   double *outptr;
   uInt32 val;

   // set up return value
   plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
   outptr = mxGetPr(plhs[0]);

   // Create Digital Output (DO) Task and Channel
   DAQmxErrChk (DAQmxBaseCreateTask ("", &taskHandle));
   DAQmxErrChk (DAQmxBaseCreateDOChan(taskHandle,chan,"",DAQmx_Val_ChanForAllLines));
   // Start Task (configure port)
   DAQmxErrChk (DAQmxBaseStartTask (taskHandle));

   // get input value
   val = (uInt32)*mxGetPr(prhs[0]);

   mexPrintf("Data to write: 0x%X\n", val);

   DAQmxErrChk (DAQmxBaseWriteDigitalU32(taskHandle,1,1,10.0,DAQmx_Val_GroupByChannel,&val,&written,NULL));

   // end task
   DAQmxBaseStopTask (taskHandle);
   DAQmxBaseClearTask (taskHandle);

   // return success
   *outptr = (double)1;

   return;

 Error:

   if (DAQmxFailed (error))
     DAQmxBaseGetExtendedErrorInfo (errBuff, 2048);

   if (taskHandle != 0)
   {
      DAQmxBaseStopTask (taskHandle);
      DAQmxBaseClearTask (taskHandle);
   }

   if (error)
     printf ("DAQmxBase Error %d: %s\n", error, errBuff);

   *outptr = (double)-1;

   return;
}

