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

% Get supported command codes from a header that's shared with mglMetal.
mgl.command = mglSocketCommandTypes();

% Get the full path to the mglMetal.app dir and its runtime sandbox.
[mglMetalApp, mglMetalSandbox] = mglMetalExecutableName;
if ~isfolder(mglMetalApp)
    fprintf('(mglMetalOpen) mglMetal executable seems not to exist: %s\n', mglMetalApp);
    return
end

% check if mglMetal is running
if mglMetalIsRunning && ~isnan(whichScreen)
    fprintf('(mglMetalOpen) mglMetal executable is already running\n');
    % then kill it
    mglMetalShutdown;
end

% Choose a socket address that's inside the mglMetal.app runtime sandbox.
socketAddress = fullfile(mglMetalSandbox, 'mglMetal.socket');
fprintf('(mglMetalOpen) Using socket address: %s\n', socketAddress);

% Start up mglMetal!
if ~isnan(whichScreen)
    fprintf('(mglMetalOpen) Starting up mglMetal executable: %s\n', mglMetalApp);
    system(sprintf('open %s --args -mglConnectionAddress %s', mglMetalApp, socketAddress));
end

% close socket if one is already opened
if isfield(mgl, 's')
    mglSocketClose(mgl.s);
end

% Open a new socket and wait for a connection to the mglMetal server.
timeout = 10;
fprintf('(mglMetalOpen) Trying to connect to mglMetal with timeout %d seconds.\n', timeout);
timer = tic();
mgl.s = mglSocketCreateClient(socketAddress);
while toc(timer) < timeout && isempty(mgl.s)
  fprintf('.');
  mgl.s = mglSocketCreateClient(socketAddress);
end
fprintf('\n');

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
