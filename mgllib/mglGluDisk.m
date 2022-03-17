% mglGluDisk - draw disk(s) at location x,y; alternative to glPoints for circular dots
%
%        $Id$
%      usage: [ackTime, processedTime] = mglGluDisk(x, y, size, color)
%         by: Benjamin Heasly
%       date: 03-17-2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%     inputs: x,y - position
%             size - radius
%             color - rgb or rgba
%             antialiasing - width of edge to smooth with alpha
%
%             Note: old params nslices and nloops are no longer used.
%             See also mglPoints2 with additional functionality.
%
%
%mglOpen(0);
%mglVisualAngleCoordinates(57,[16 12]);
%x = 16*rand(100,1)-8;
%y = 12*rand(100,1)-6;
%mglGluDisk(x, y, 0.1,  [0.1 0.6 1], 24, 2);
%mglFlush();
function [ackTime, processedTime] = mglGluDisk(x, y, size, color, varargin)

% Warn about deprecated function, but try not to spam on every frame.
persistent mglGluDiskDeprecationWarning
if (nargin > 4) && isempty(mglGluDiskDeprecationWarning)
    mglGluDiskDeprecationWarning = true;
    fprintf("(mglGluDisk) nslices and nloops are longer supported, the last param is for antialiasing now.\n")
end

[ackTime, processedTime] = mglPoints2(x, y, size, color);
