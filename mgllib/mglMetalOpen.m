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

% Get supported command codes from a header that's shared with mglMetal.
mgl.command = mglSocketCommandTypes();

% Get the full path to the mglMetal.app dir and its runtime sandbox.
[mglMetalApp, mglMetalSandbox] = mglMetalExecutableName;
if ~isfolder(mglMetalApp)
    fprintf('(mglMetalOpen) mglMetal executable seems not to exist: %s\n', mglMetalApp);
    return
end

% check if mglMetal is running
reuseMglMetal = mglGetParam('reuseMglMetal');
if isempty(reuseMglMetal)
    reuseMglMetal = false;
end
if mglMetalIsRunning && ~reuseMglMetal
    fprintf('(mglMetalOpen) mglMetal executable is already running\n');
    % then kill it
    mglMetalShutdown;
end

% Register a cleanup callback.
% Matlab will call this when deleting the global mgl struct.
% This should happen if you "clear all", or when exiting Matlab.
mgl.onCleanup = onCleanup(@mglMetalShutdown);

% Choose a socket address that's inside the mglMetal.app runtime sandbox.
socketAddress = fullfile(mglMetalSandbox, 'mglMetal.socket');
fprintf('(mglMetalOpen) Using socket address: %s\n', socketAddress);

% Start up mglMetal!
if ~reuseMglMetal
    fprintf('(mglMetalOpen) Starting up mglMetal executable: %s\n', mglMetalApp);
    fprintf('(mglMetalOpen) You can tail the app log with "log stream --level info --process mglMetal"\n');
    fprintf('(mglMetalOpen) You can also try the macOS Console app and search for PROCESS "mglMetal"\n');
    system(sprintf('open %s --args -mglConnectionAddress %s', mglMetalApp, socketAddress));
end

% close socket if one is already opened
if isfield(mgl, 's')
    mgl.s = mglSocketClose(mgl.s);
end

% Open a new socket and wait for a connection to the mglMetal server.
timeout = 10;
fprintf('(mglMetalOpen) Trying to connect to mglMetal with timeout %d seconds.\n', timeout);
timer = tic();
mgl.s = mglSocketCreateClient(socketAddress);
while toc(timer) < timeout && isempty(mgl.s)
  pause(0.1);
  fprintf('.');
  mgl.s = mglSocketCreateClient(socketAddress);
end
fprintf('\n');

if isempty(mgl.s)
    fprintf('(mglMetalOpen) Socket connection to mglMetal timed out after %d seconds\n', timeout);
    return;
else
    fprintf('(mglMetalOpen) Socket connection to mglMetal established in %f seconds\n', toc(timer));
end

% Move to the desired display and window location.
mglMetalSetWindowFrameInDisplay(whichScreen, [screenX, screenY, screenWidth, screenHeight]);
mglMetalFullscreen(isFullscreen);

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
