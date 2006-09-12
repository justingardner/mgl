% mglGetMouseEvent.m
%
%        $Id$
%      usage: mglGetMouseEvent(waitTicks)
%         by: justin gardner
%       date: 09/12/06
%    purpose: returns a mouse down event
%             waitTicks specifies how long to wait for a mouse event
%             in "ticks" which on Mac OS X are approximately 1/60 of
%             a second intervals. The default is 0, which will return
%             immediately with the mouse position regardless of button
%             state
%             NOTE that the mouse down event has to be *ON* the mgl window
%             for this to work with waitTicks not equal to 0
%       e.g.:
%
%mglOpen
%mglGetMouseEvent(300)
%

