% mglLines2.m
%
%       usage: mglLines(x0, y0, x1, y1,size,color,<anti-aliasing>)
%          by: justin gardner
%        date: 09/28/2021 adapted from previous version created on 04/03/06
%  copyright: (c) 2021 Justin Gardner (GPL see mgl/COPYING)
%     purpose: Function to plot lines on mglMetal screen opened with mglOpen.
%              x0 and y0 are starting and x1 and y1 are ending point of line
%              size is line width and color is an color value (usually an array
%              of three number between 0 and 1).
%              Set anti-alising to 1 (defaults to 0) if you want the line to be antialiased.
%       e.g.:
%
%mglOpen
%mglVisualAngleCoordinates(57,[16 12]);
%mglLines2(-4, -4, 4, 4, 2, [1 0.6 1]);
%mglFlush
%
%To draw multiple lines at once:
%mglOpen
%mglVisualAngleCoordinates(57,[16 12]);
%mglLines2(rand(1,100)*5-2.5, rand(1,100)*10-5, rand(1,100)*5-2.5, rand(1,100)*3-1.5, 3, [0 0.6 1],1);
%mglFlush
function [ackTime, processedTime] = mglLines2(x0, y0, x1, y1, size, color)

global mgl;

if length(color) == 1
  color = [color color color];
end
color = color(:);

% set up vertices
v = [];
for iLine = 1:length(x0)
  v(end+1:end+12) = [x0(iLine) y0(iLine) 1 color(:)' x1(iLine) y1(iLine) 1 color(:)'];
end

% send line command
mglSocketWrite(mgl.s, mgl.command.mglLine);
ackTime = mglSocketRead(mgl.s, 'double');
mglSocketWrite(mgl.s, uint32(2*iLine));
mglSocketWrite(mgl.s, single(v));
processedTime = mglSocketRead(mgl.s, 'double');
