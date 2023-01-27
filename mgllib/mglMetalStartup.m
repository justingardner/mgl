% mglMetalStartup: Open an mgl metal window (starts a separate standalone
%                  app which mgl communicates with via a socket).
%
%      usage: mglMetalStartup(whichScreen, screenX, screenY, screenWidth, screenHeight)
%         by: ben heasly
%       date: 08/26/2022
%  copyright: (c) 2021 Justin Gardner (GPL see mgl/COPYING)
%    purpose: Opens an mgl Metal window and returns a connected socket
%      usage: % Open on secondary monitor fullscreen
%             socket = mglMetalOpen(1)
%
%             % Open on primary monitory in an 800x600 window
%             socket = mglMetalOpen(0, 800, 600);
%
%             % For debugging you might want to connect to an
%             already-running mglMetal app, like one attached to Xcode
%             mglSetParam('reuseMglMetal', 1);
%             socket = mglMetalOpen(0);
%
%             This function returns a socket info struct, with the socket
%             connected to a running mglMetal process.  This function does
%             not affect the overall mgl context -- ie the "global mgl"
%             variable.
%
function socketInfo = mglMetalStartup(whichScreen, screenX, screenY, screenWidth, screenHeight)

socketInfo = [];

if nargin < 1 || isempty(whichScreen)
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

[mglMetalApp, mglMetalSandbox] = mglMetalExecutableName;
if ~isfolder(mglMetalApp)
    fprintf('(mglMetalStartup) mglMetal executable seems not to exist: %s\n', mglMetalApp);
    return
end

% Find the socket address of an existing mglMetal process, or make a fresh one.
[alreadyRunning, ~, addresses] = mglMetalIsRunning();
reuseMglMetal = mglGetParam('reuseMglMetal');
if alreadyRunning && ~isempty(reuseMglMetal) && reuseMglMetal
    % Reuse the first address we found, we'll try to connect to that process.
    socketAddress = addresses{1};
    fprintf('(mglMetalStartup) Reusing existing socket address: %s\n', socketAddress);
else
    % Make up a brand new address and we launch a new process for it.
    alphaNums = [char(48:57) char(65:90) char(97:122)];
    unique = alphaNums(randi([1 numel(alphaNums)], 1, 10));
    socketAddress = fullfile(mglMetalSandbox, ['mglMetal.socket.' unique]);
    fprintf('(mglMetalStartup) Using new socket address: %s\n', socketAddress);

    fprintf('(mglMetalStartup) Starting up mglMetal executable: %s\n', mglMetalApp);
    fprintf('(mglMetalStartup) You can tail the app log with "log stream --level info --process mglMetal"\n');
    fprintf('(mglMetalStartup) You can also try the macOS Console app and search for PROCESS "mglMetal"\n');
    system(sprintf('open -n %s --args -mglConnectionAddress %s', mglMetalApp, socketAddress));
end

% Open a new socket and wait for a connection to the mglMetal server.
timeout = 10;
fprintf('(mglMetalStartup) Trying to connect to mglMetal with timeout %d seconds', timeout);
timer = tic();
socketInfo = mglSocketCreateClient(socketAddress);
while toc(timer) < timeout && isempty(socketInfo)
    pause(0.1);
    fprintf('.');
    socketInfo = mglSocketCreateClient(socketAddress);
end
fprintf('\n');

if isempty(socketInfo)
    fprintf('(mglMetalStartup) Socket connection to mglMetal timed out after %d seconds\n', timeout);
    return;
else
    fprintf('(mglMetalStartup) Socket connection to mglMetal established in %f seconds\n', toc(timer));
end

% Register a cleanup callback.
% Matlab will call this when deleting the returned socketInfo struct.
% This will happen whenever you exit or clear the caller's workspace -- in
% particular, when you "clear all", mglClose(), or exit Matlab.
socketInfo.onCleanup = onCleanup(@() mglMetalShutdown(socketInfo));

% Now we have a socket connected to an mglMetal process, so we can configure it.
socketInfo.command = mglSocketCommandTypes();
mglMetalSetWindowFrameInDisplay(whichScreen, [screenX, screenY, screenWidth, screenHeight], socketInfo);
mglMetalFullscreen(isFullscreen, socketInfo);
