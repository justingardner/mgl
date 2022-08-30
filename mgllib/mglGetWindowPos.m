% mglGetWindowPos.m
%
%      usage: windowPos = mglGetWindowPos(socketInfo)
%         by: Justin Gardner
%       date: 07/29/17
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Returns the position of a windowed context opened with mglOpen(0)
%             returned position will be in pixels [x y width height]
%
%      usage:
%             % Get position of primary window
%             mglOpen(0);
%             windowPos = mglGetWindowPos()
%
%             % Get position of a mirrored window
%             mglOpen(0);
%             socketInfo = mglMirrorOpen(0);
%             windowPos = mglGetWindowPos(socketInfo)
%
function windowPos = mglGetWindowPos(socketInfo)

if nargin < 1 || isempty(socketInfo)
    global mgl
    socketInfo = mgl.activeSockets;
end

[~, windowPos] = mglMetalGetWindowFrameInDisplay(socketInfo);
