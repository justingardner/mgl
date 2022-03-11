% mglGetWindowPos.m
%
%      usage: windowPos = mglGetWindowPos
%         by: Justin Gardner
%       date: 07/29/17
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Returns the position of a windowed context opened with mglOpen(0)
%             returned position will be in pixels [x y width height]
%
%      usage: windowPos = mglGetWindowPos
%             
%
% mglOpen(0);
% windowPos = mglGetWindowPos
% 
function windowPos = mglGetWindowPos()
[~, windowPos] = mglMetalGetWindowFrameInDisplay();
