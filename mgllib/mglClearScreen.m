% mglClearScreen.m
%
%        $Id$
%      usage: mglClearScreen([clearColor], [clearBits])
%         by: Jonas Larsson
%       date: 04/10/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Sets the background color and clears the buffer.  'clearBits'
%             is an optional parameter that lets you specify which buffers
%             are cleared.  The buffers are specifed by a 1x4 array of 1's
%             and 0's which toggle the buffer bits, where the bits are
%             [color buffer, depth buffer, accum buffer, stencil buffer].
%             By default the color buffer is cleared if 'clearBits' isn't
%             specified.
%      usage: sets to whatever previous background color was set
%             mglClearScreen()     
%
%             set to the level of gray (0-1)
%             mglClearScreen(gray) 
%
%             set to the given [r g b]
%             mglClearScreen([r g b]) 
%  
%             set the clear color and clear the color and depth buffers.
%             mglClearScreen([r g b], [1 1 0 0]);
%       e.g.: 
%
% mglOpen();
% mglClearScreen([0.7 0.2 0.5]);
% mglFlush();
%