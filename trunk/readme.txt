============================================================================
MGL (Matlab GL): A suite of mex/m files for displaying psychophysics stimuli.
                 Runs on Mac OS X and Linux.
============================================================================

****************************************************************************
How to get started
****************************************************************************
1.1 What is in this directory
1.2 How do I use this?
1.3 How do I recompile
1.4 If all else fails, how can I get back control over the display

****************************************************************************
Known issues that you should be aware of
****************************************************************************
2.1 Matlab license manager causes timing glitches every 30 seconds
2.2 Some functions not supported yet on Linux
2.3 This distribution is intended to work with Mac OS 10.4 or greater

============================================================================
1.1 What is in this directory
============================================================================

mgl/mgllib: The main distribution that has all functions for displaying to
            the screen.
mgl/task: A set of higher level routines that set up a structure for running
          tasks and trials. Relies on functions in mgl/mgllib. You do not
	  need to use any of these functions if you just want to use this
	  library for drawing to the screen.
mgl/utils: Various utility functions.
         
============================================================================
1.2 How do I use this?
============================================================================

Simply add this directory to your path, and you are ready to go.

>> addpath(genpath('MYPATH/mgl'));
where MYPATH should be replaced by the directory where you have built this library

You can see what functions are available by doing

>> help mgl

There are a bunch of test programs (names start with mglTest) that you can
use to test the distribution and see how things are done.

============================================================================
1.3 How do I recompile
============================================================================

If you need to recompile the distribution, switch to the mgl/core directory
and run:

>> mglMake(1);

============================================================================
1.4 If all else fails, how can I get back control over the display
============================================================================
If you can't do mglClose, you can always press:

option-open apple-esc

this will quit your matlab session as well.

============================================================================
2.1 Matlab license manager causes timing glitches every 30 seconds
============================================================================

The Matlab license manager checks every 30 seconds for the license. This can
cause there to be an apparent frame glitch in your stimulus code, especially
if you are using a network license (on our machines it can take ~200 ms to
check for the license). The only known workaround to this is to run on a
machine that has a local copy of the license.

============================================================================
2.2 Some functions not supported yet on Linux
============================================================================

Not all functions are currently supported on the Linux platform. The list
of funcitons not supported yet are:

mglGetGammaTable
mglSetGammaTable
mglText

If you want to use text under the linux operating system, you can use
mglStrokeText.

============================================================================
2.3 This distribution is intended to work with Mac OS 10.4 or greater
============================================================================

In particular opening in a window (mglOpen(0)) is unstable for versions before
Mac OS 10.4
