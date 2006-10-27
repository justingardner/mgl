% mglGetMouseEvent.m
%
%        $Id$
%      usage: mglGetMouseEvent(waitTicks)
%         by: justin gardner
%       date: 09/12/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: returns a mouse down event
%             waitTicks specifies how long to wait for a mouse event
%             in seconds. Note that the timing precision is system-dependent:
%             - Mac OS X: about 1/60 s
%             - Linux: 1/HZ s where HZ is the system kernel tick frequency
%               (HZ=100 on older systems, HZ=250 or 500 on more modern systems)
%             The default wait time is 0, which will return immediately with
%             the mouse position regardless of button state.
%             The return structure contains the x,y coordinates of the mouse,
%             the button identifier if pressed (on the button-challenged Mac 
%             this is always 1) and 0 otherwise, and the time (in secs) of 
%             the mouse event.
%             NOTE that the mouse down event has to be *ON* the mgl window
%             for this to work with waitTicks not equal to 0
%       e.g.:
%
%mglOpen
%mglGetMouseEvent(0.5)
%

