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
[metalAppName metalDir] = mglMetalExecutableName;
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

% close socket if one is already opened
cd(metalDir);
if isfield(mgl,'s') mglSocketClose(mgl.s); end
!rm -f testsocket

% open a new socket for communication
mgl.s = mglSocketOpen('testsocket');

% check if mglMetal is running
if mglMetalIsRunning
  disp(sprintf('(mglMetalOpen) mglMetal executable is already running'));
  % then kill it
  mglMetalShutdown;
end

%start up mglMetal
if ~isnan(whichScreen)
  disp(sprintf('(mglMetalOpen) Starting up mglMetal executable: %s',metalAppName));
  system(sprintf('open %s',metalAppName));
end
