% mglTextDraw.m
%
%        $Id$
%      usage: mglTextDraw(str,pos,hAlignment,vAlignment)
%         by: justin gardner
%       date: 05/13/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: wrapper around mglText and mglBltTexture to
%             draw some text on the string. If you need
%             to draw text more quickly, you will have to
%             pre-make the text textures with mglText and
%             then use mglBltTexture when you want it 
%             str = desired string
%             pos = [x y] - position on screen
%             hAlignment = {-1 = left,0 = center,1 = right}
%                          defaults to center
%             vAlignment = {-1 = top,0 = center,1 = bottom}
%                          defaults to center
%
%
%       e.g.:
%mglOpen;
%mglVisualAngleCoordinates(57,[16 12]);
%mglTextSet('Helvetica',32,[0 0.5 1 1],0,0,0,0,0,0,0);
%mglTextDraw('Hello There',[0 0]);
%mglFlush;

function retval = mglTextDraw(str,pos,hAlignment,vAlignment)

% check arguments
if ~any(nargin == [2:4])
  help mglTextDraw
  return
end

% default alignment
if ~exist('hAlignment'),hAlignment = 0;,end
if ~exist('vAlignment'),vAlignment = 0;,end

% make the text texture and blt it to the screen
textTexture = mglText(str);
mglBltTexture(textTexture,pos,hAlignment,vAlignment);
mglDeleteTexture(textTexture);
