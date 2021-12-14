% mglMetalOpen: Open an mgl metal window (starts a separate standalone app which
%               mgl communicates with via a socket). Typically called from mglOpen
%
%      usage: mglMetalOpen(whichScreen, screenWidth,screenHeight)
%         by: justin gardner
%       date: 09/27/2021
%  copyright: (c) 2021 Justin Gardner (GPL see mgl/COPYING)
%    purpose: Opens an mgl Metal window - typically called from mglOpen
%      usage: open 2nd monitor
%             mglMetalOpen(2)
%
%             Open with resolution 800x600 in a windowed context
%             mglMetalOpen(0,800,600);
function mglMetalOpen(whichScreen,screenWidth,screenHeight)

if nargin == 0
    whichScreen = 1;
end

% create the mgl global variable
global mgl

mglSetParam('noask',false);
mglSetParam('profile',false);

% set command numbers
mgl.command.ping = 0;
mgl.command.clearScreen = 1;
mgl.command.dots = 2;
mgl.command.flush = 3;
mgl.command.xform = 4;
mgl.command.line = 5;
mgl.command.quad = 6;
mgl.command.createTexture = 7;
mgl.command.bltTexture = 8;
mgl.command.test = 9;
mgl.command.fullscreen = 10;
mgl.command.windowed = 11;
mgl.command.blocking = 12;
mgl.command.nonblocking = 13;
mgl.command.profileon = 14;
mgl.command.profileoff = 15;
mgl.command.polygon = 16;
mgl.command.getSecs = 17;

% get mglMetal application name
[metalAppName, metalDir] = mglMetalExecutableName;
if isempty(metalAppName)
    return
end

% check if mglMetal is running
if mglMetalIsRunning && ~isnan(whichScreen)
    fprintf('(mglMetalOpen) mglMetal executable is already running\n');
    % then kill it
    mglMetalShutdown;
end

%start up mglMetal
socketAddress = fullfile(metalDir, 'mglMetalSocket');
fprintf('(mglMetalOpen) Using socket address: %s\n', socketAddress);
if ~isnan(whichScreen)
    fprintf('(mglMetalOpen) Starting up mglMetal executable: %s\n', metalAppName);
    system(sprintf('open %s --args -mglConnectionAddress %s', metalAppName, socketAddress));
end

% close socket if one is already opened
if isfield(mgl, 's')
    mglSocketClose(mgl.s);
end

% Open a new socket and wait for a connection to the mglMetal server.
timer = tic();
tiemeout = 10;
mgl.s = mglSocketOpen(socketAddress);
while toc(timer) < tiemeout && isempty(mgl.s)
  mgl.s = mglSocketOpen(socketAddress);
end

if isempty(mgl.s)
    fprintf('(mglMetalOpen) Socket connection to mglMetal timed out after %d seconds\n', timeout);
else
    fprintf('(mglMetalOpen) Socket connection to mglMetal established in %f seconds\n', toc(timer));
end

% Make sure Matlab and metal agree on initial coordinate transform.
mglTransform('set', eye(4));

% BSH stubbing these out for now
mglSetParam('displayNumber', 0);
mglSetParam('screenWidth', 400);
mglSetParam('screenHeight', 400);
mglSetParam('numTextures', 0);
