% mglClearScreen.m
%
%        $Id$
%      usage: [ackTime, processedTime] = mglClearScreen([clearColor], [clearBits])
%         by: Justin Gardner
%       date: 09/27/2021
%  copyright: (c) 2021 Justin Gardner (GPL see mgl/COPYING)
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
function [ackTime, processedTime] = mglClearScreen(clearColor, clearBits)

if nargin == 2
  disp(sprintf('(mglClearScreen) clearBits not implemented in mgl 3.0'));
  keyboard
end

global mgl

% if no clear color is given, then...
if nargin < 1 || numel(clearColor) == 0
  % set to the last clear color
  clearColor = mglGetParam('clearColor');
  % or if no clear color has ever been set, then
  % set to black
  if isempty(clearColor)
    clearColor = [0, 0, 0];
  end
elseif numel(clearColor) == 1
  clearColor = [clearColor clearColor clearColor];
end
clearColor = clearColor(:);
mglSetParam('clearColor',clearColor);

% write clear screen command
mglSocketWrite(mgl.s, mgl.command.mglSetClearColor);
ackTime = mglSocketRead(mgl.s, 'double');
mglSocketWrite(mgl.s, single(clearColor));
processedTime = mglSocketRead(mgl.s, 'double');
