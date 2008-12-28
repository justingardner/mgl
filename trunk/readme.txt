============================================================================
MGL (Matlab GL): A suite of mex/m files for displaying psychophysics stimuli.
                 Runs on Mac OS X and Linux. Version 1.0
============================================================================

The text in this file is not necessarily up to date. 
Please refer to the wiki for up to date information.

http://justingardner.net/mgl

****************************************************************************
How to get started
****************************************************************************
1.0 A quick overview
1.1 What is in this directory
1.2 How do I use this?
1.3 These programs are free to distribute under the GNU General Public License
1.4 How do I recompile
1.5 If all else fails, how can I get back control over the display
1.6 Can I get access to all OpenGL functions?

============================================================================
1.0 A quick overview
============================================================================

mgl is a set of matlab functions for dispalying full screen visual stimuli
from matlab. It is based on OpenGL functions, but abstracts these into
more simple functions that can be used to code various kinds of visual
stimuli. It can be used on both Linux and Mac OS X systems. Stimuli can
be displayed full screen or in a window (helpful for debugging on a system
that only has one display). With a single command that specifies the
distance to and size of a monitor, the coordinate system can be specified
in degrees of visual angle, thus obviating the need to explicitly convert
from the natural coordinate frame of psychophysics experiments into
pixels. The best way to see whether it will be useful to you is to try
out the mglTest programs (see 1.2 below) and also the sample experiment
testExperiment. A basic "hello world" program can be written in four lines:

%Open the screen, 0 specifies to draw in a window. 1 would be full screen
%in the main display, 2 would be full screen in a secondary display, etc...
mglOpen(0);

%Select the coordinate frame for drawing (e.g. for a monitor 57 cm away,
%which has width and height of 16 and 12 cm).
mglVisualAngleCoordinates(57,[16 12]);

% draw the text in the center (i.e. at 0,0)
mglTextDraw('Hello World!',[0 0]);

% The above is drawn on the back-buffer of the double-buffered display
% so to make it show up you flush the display (this function will wait
% till the end of the screen refresh)
mglFlush;

To close an open screen:

mglClose;

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
where MYPATH should be replaced by the directory where you have placed
this library.

You can see what functions are available by doing:

>> help mgl

There are a bunch of test programs (names start with mglTest) that you can
use to test the distribution and see how things are done.

============================================================================
1.3 These programs are free to distribute under the GNU General Public License
============================================================================
See the file mgl/COPYING for details

============================================================================
1.4 How do I recompile
============================================================================

If you need to recompile the distribution:

>> mglMake(1);

============================================================================
1.5 If all else fails, how can I get back control over the display
============================================================================
If you can't do mglClose, you can always press:

option-open apple-esc

this will quit your matlab session as well.

============================================================================
1.6 Can I get access to all OpenGL functions?
============================================================================
We have only exposed parts of the OpenGL functionality. If you need to dig
deeper to code your stimulus, consider writing your own mex file. This will
allow you to use the full functionality of the OpenGL library. To do this,
you could start by modifying one of our mex functions (e.g. mglClearScreen.c)
and add your own GL code to do what you want and compile. 

touch
