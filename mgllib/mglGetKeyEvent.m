% mglGetKeyEvent.m
%
%        $Id$
%      usage: mglGetKeyEvent(waitTicks)
%         by: justin gardner
%       date: 09/12/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: returns a key down event
%             waitTicks specifies how long to wait for a key press event
%             in seconds. Note that the timing precision is system-dependent:
%             - Mac OS X: about 1/60 s
%             - Linux: 1/HZ s where HZ is the system kernel tick frequency
%               (HZ=100 on older systems, HZ=250 or 500 on more modern systems)
%             The default wait time is 0, which will return immediately and if
%             no keypress event is found, will return an empty array [].
%             The return structure contains the character (ASCII) code of the
%             pressed key, the system-specific keycode, a keyboard identifier
%             (on Linux, this is the keyboard state, or modifier field), and 
%             and the time (in secs) of the key press event.
%             NOTE that to get a key event the focus *MUST* be on 
%             the mgl window. 
%             For faster timing, try mglGetKeys
%       e.g.:
%
%mglOpen
%mglGetKeyEvent(0.5)
%

