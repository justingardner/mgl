% mglMetalOpen: Open an mgl metal window (starts a separate standalone app which
%               mgl communicates with via a socket). Typically called from mglOpen
%
%      usage: mglMetalOpen(whichScreen, screenX, screenY, screenWidth, screenHeight)
%         by: justin gardner
%       date: 09/27/2021
%  copyright: (c) 2021 Justin Gardner (GPL see mgl/COPYING)
%    purpose: Opens an mgl Metal window - typically called from mglOpen
%      usage: % Open on secondary monitor fullscreen
%             mglMetalOpen(1)
%
%             % Open on primary monitory in an 800x600 window
%             mglMetalOpen(0, 800, 600);
%
%             % For debugging you might want to connect to an
%             already-running mglMetal app, like one attached to Xcode
%             mglSetParam('reuseMglMetal', 1);
%             mglMetalOpen(0);
%
function mglMetalOpen(whichScreen, screenX, screenY, screenWidth, screenHeight)

if nargin < 1
    whichScreen = 0;
end
isFullscreen = whichScreen > 0;

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

% create the mgl global variable
global mgl

% Get a socket connection to an mglMetal process.
mgl.command = mglSocketCommandTypes();
socketInfo = mglMetalStartup(whichScreen, screenX, screenY, screenWidth, screenHeight);
mgl.s = socketInfo;

% Register a cleanup callback.
% Matlab will call this when deleting the global mgl struct.
% This should happen if you "clear all", or when exiting Matlab.
mgl.onCleanup = onCleanup(@() mglMetalShutdown(socketInfo));

% Configure mgl context to match this mglMetal process.
mglSetParam('displayNumber', whichScreen);
mglSetParam('screenX', screenX);
mglSetParam('screenY', screenY);
mglSetParam('screenWidth', screenWidth);
mglSetParam('screenHeight', screenHeight);

% get new screenWidth and screenHeight for fullscreen
if isFullscreen
  % get display info
  displays = mglDescribeDisplays;
  % get the screen we have been resized to
  if (whichScreen >= 1) && whichScreen <= length(displays)
    % and get it's pixel dimensions
    screenSize = displays(whichScreen).screenSizePixel;
    screenWidth = screenSize(1);
    screenHeight = screenSize(2);
  end
end

mglSetParam('screenWidth', screenWidth);
mglSetParam('screenHeight', screenHeight);
mglSetParam('xPixelsToDevice', 2 / screenWidth);
mglSetParam('yPixelsToDevice', 2 / screenHeight);
mglSetParam('xDeviceToPixels', screenHeight / 2);
mglSetParam('yDeviceToPixels', screenHeight / 2);
mglSetParam('deviceWidth', 2);
mglSetParam('deviceHeight', 2);
mglSetParam('deviceCoords', 'default');
mglSetParam('deviceRect', [-1 -1 1 1]);

% Init the Metal stencil buffer, clearing all stencil planes.
% This is a special case for stencil number 0.
% Normally, selecting stencil number 0 means "no stencil test".
mglStencilCreateBegin(0);
mglStencilCreateEnd();

% mglMetal uses a depth/stencil pixel format called depth32Float_stencil8.
% So, 8 stencil bits.
mglSetParam('stencilBits', 8);

% Make sure Matlab and mglMetal agree on initial coordinate transform.
mglTransform('set', eye(4));
mglFlush();

% Populate several mgl params -- many used to be set in mglPrivateOpen.c.
mglSetParam('numTextures', 0);
