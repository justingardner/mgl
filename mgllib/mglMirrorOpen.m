% mglMirrorOpen: Open a new mgl window in the same context as the primary window.
%
%        $Id$
%      usage: mglMirrorOpen(whichScreen, screenX, screenY, screenWidth, screenHeight)
%         by: ben heasly
%       date: 08/29/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Open a new mgl window in the same context as the primary window.
%      usage:
%             The first parameter, whichScreen, determines which display to
%             open on:
%              - mglMirrorOpen() - open on the last currently connected display fullscreen
%              - mglMirrorOpen(1) - open on the primary display fullscreen
%              - mglMirrorOpen(2) - open on the 2nd screen on a two display fullscreen
%              - mglMirrorOpen(0) - open in a window
%
%             % Use last connected monitor.
%             mglMirrorOpen();
%
%             The last four parameters control the screen location and size
%             of the new window:
%              - screenX, screenY: position of window bottom left corner
%              - screenWidth, screenHeight: size of the window
%
%             % Use last connected monitor.
%             mglMirrorOpen(0, 100, 100, 640, 480)
%
%             Returns a socket infor struct for the connection to the new
%             mglMetal process that controls the new window.
function socketInfo = mglMirrorOpen(whichScreen, screenX, screenY, screenWidth, screenHeight)

% Check arguments.
if nargin < 1 || isempty(whichScreen)
    displayResolution = mglResolution();
    whichScreen = displayResolution.displayNumber;
end

if nargin < 2
    screenX = 100;
end

if nargin < 3
    screenY = 100;
end

if nargin < 4
    screenWidth = 800;
end

if nargin < 5
    screenHeight = 600;
end

% Launch a new mglMetal process with its own window and socket connection.
socketInfo = mglMetalStartup(whichScreen, screenX, screenY, screenWidth, screenHeight);

% Register a cleanup callback.
% Matlab will call this when deleting the global mgl struct.
% This should happen if you "clear all", or when exiting Matlab.
socketInfo.onCleanup = onCleanup(@() mglMetalShutdown(socketInfo));

% Initial setup for the new metal process.
% TODO: these want to take a socketInfo arg for the new one.
% mglStencilCreateBegin(0);
% mglStencilCreateEnd();
% mglTransform('set', eye(4));
% mglFlush();

% Add this new "mirrored" window to the global mgl context.
global mgl
mgl.activeSockets(end+1) = socketInfo;
if isempty(mgl.mirrorSockets)
    mgl.mirrorSockets = socketInfo;
else
    mgl.mirrorSockets(end+1) = socketInfo;
end
