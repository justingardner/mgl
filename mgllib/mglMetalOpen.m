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

% get mglMetal application name
[metalAppName, metalDir] = mglMetalExecutableName;
if isempty(metalAppName)
    return
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

% close socket if one is already opened
cd(metalDir);
if isfield(mgl,'s')
    mglSocketClose(mgl.s);
end
!rm -f testsocket

% open a new socket for communication
mgl.s = mglSocketOpen('testsocket');

% check if mglMetal is running
if mglMetalIsRunning
    fprintf('(mglMetalOpen) mglMetal executable is already running\n');
    % then kill it
    mglMetalShutdown;
end

%start up mglMetal
if ~isnan(whichScreen)
    fprintf('(mglMetalOpen) Starting up mglMetal executable: %s\n',metalAppName);
    system(sprintf('open %s',metalAppName));
end

% Wait until a connection is established with the mglMetal proecess.
timer = tic();
tiemeout = 10;
while toc(timer) < tiemeout && mgl.s.connectionDescriptor == -1
    mgl.s = mglSocketWrite(mgl.s,uint16(mgl.command.ping));
end

if mgl.s.connectionDescriptor == -1
    fprintf('(mglMetalOpen) Socket connection to mglMetal timed out after %d seconds\n', timeout);
else
    fprintf('(mglMetalOpen) Socket connection to mglMetal established in %f seconds\n', toc(timer));
end
