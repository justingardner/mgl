% mglClearScreen.m
%
%        $Id$
%      usage: mglClearScreen()
%         by: Jonas Larsson
%       date: 04/10/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: sets the background color
%      usage: sets to whatever previous background color was set
%             mglClearScreen()     
%
%             set to the level of gray (0-1)
%             mglClearScreen(gray) 
%
%             set to the given [r g b]
%             mglClearScreen([r g b]) 
%  
%       e.g.: 
%
%mglOpen();
%mglClearScreen([0.7 0.2 0.5]);
%mglFlush();

