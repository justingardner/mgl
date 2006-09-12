% mglGetKeyEvent.m
%
%        $Id$
%      usage: mglGetKeyEvent(waitTicks)
%         by: justin gardner
%       date: 09/12/06
%    purpose: returns a key down event
%             waitTicks specifies how long to wait for a mouse event
%             in "ticks" which on Mac OS X are approximately 1/60 of
%             a second intervals. The default is 0, which will return
%             immediately with the mouse position regardless of button
%             state
%             NOTE that to get a key event the focus *MUST* be on 
%             the mgl window.
%       e.g.:
%
%mglOpen
%mglGetKeyEvent(300)
%

