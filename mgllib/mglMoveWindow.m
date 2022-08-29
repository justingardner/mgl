% mglMoveWindow.m
%
%        $Id$
%      usage: mglMoveWindow(leftPos, topPos, socketInfo)
%         by: Christopher Broussard
%       date: 10/23/07
%    purpose: Moves the current AGL window with the left edge of the window
%	      at 'leftPos', the top edge at 'topPos'.
%
%            % move the primary window
%            mglOpen(0);
%            mglMoveWindow(100, 100);
%
%            % move a mirrored window
%            mglOpen(0);
%            socketInfo = mglMirrorOpen(0);
%            mglMoveWindow(100, 100, socketInfo);
%
function mglMoveWindow(leftPos, topPos, socketInfo)

if nargin < 2 || nargin > 3
    help mglMoveWindow
    return
end

if ~isscalar(leftPos) || ~isscalar(topPos)
    help mglMoveWindow
    return
end

if nargin < 3 || isempty(socketInfo)
    global mgl
    socketInfo = mgl.s;
end

% Get the current window position.
[displayNumber, rect] = mglMetalGetWindowFrameInDisplay(socketInfo);

% Modify the position of the rect.
rect(1) = leftPos;
rect(2) = topPos - rect(4);
mglMetalSetWindowFrameInDisplay(displayNumber, rect, socketInfo);
