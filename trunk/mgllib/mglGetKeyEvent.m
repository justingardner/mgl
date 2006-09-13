% mglGetKeyEvent.m
%
%        $Id$
%      usage: mglGetKeyEvent(waitTicks)
%         by: justin gardner
%       date: 09/12/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: returns a key down event
%             waitTicks specifies how long to wait for a mouse event
%             in "ticks" which on Mac OS X are approximately 1/60 of
%             a second intervals. The default is 0, which will return
%             immediately.
%             NOTE that to get a key event the focus *MUST* be on 
%             the mgl window. Also, this function can only get
%             key events in tick (1/60 sec) intervals, so if you
%             need faster timing, try mglGetKeys
%       e.g.:
%
%mglOpen
%mglGetKeyEvent(300)
%

