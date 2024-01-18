% mglFrameGrab.m
%
%        $Id$
%      usage: mglFrameGrab()
%         by: justin gardner
%       date: 08/09/2023
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: does a frame grab of the current mgl screen and
%             returns it as matrix of dimensions widthxheightx3
%             This only works when running mgl with an off-screen texture
%             so, you need to first call init on thsi fucntion to create an off-screen
%             and then drawing commands will draw to a texture that is created rather
%             than the screen (so you won't see updates to the screen). 
%      usage: mglFrameGrab('init'); % starts mglFrameGrab
%             frame = mglFrameGrab; % grabs a frame (run this after drawing and doing mglFlush)
%             mglFrameGrab('end')   % ends frame grab mode so you can draw to the screen again
% 
%       e.g.: 
% % open screen
% mglOpen(0);
%
% % initialize mglFrameGrab (this causes drawing commands to be rendered to a texture, rather
% % than the screen, so you will not see what you draw on the screen)
% mglFrameGrab('init');
%
% % draw some things
% mglScreenCoordinates;
% mglClearScreen([0 0 0]);
% mglPoints2(mglGetParam('screenWidth')*rand(5000,1),mglGetParam('screenHeight')*rand(5000,1));
% mglPolygon([0 0 mglGetParam('screenWidth') mglGetParam('screenWidth')],[mglGetParam('screenHeight')/3 mglGetParam('screenHeight')*2/3 mglGetParam('screenHeight')*2/3 mglGetParam('screenHeight')/3],0);
% mglTextSet('Helvetica',32,[1 1 1]);
% mglTextDraw('Frame Grab',[mglGetParam('screenWidth')/2 mglGetParam('screenHeight')/2]);
% mglFlush;
%
% % grab the frame
% frame = mglFrameGrab;
%
% % display it
% image(frame(:,:,1:3))
function [frame, results] = mglFrameGrab(grabMode)

% default values for return variables
frame = [];
results = [];

% check whether mgl is running
if ~mglMetalIsRunning
  fprintf('(mglFrameGrab) mgl is not running.\n')
  return
end

% default arguments
if nargin < 1
  grabMode = 'grab';
end

% decide what to do
switch (grabMode)
  case {'init',0}
    initFrameGrab;
  case {'grab',1}
    frame = getFrameGrab;
  case {'end',2}
    endFrameGrab;
  otherwise
    fprintf('(mglFrameGrab) Unknown mode: ');
    disp(grabMode)
    return
end

return

%%%%%%%%%%%%%%%%%%%%%%%%
% init the frame grab
%%%%%%%%%%%%%%%%%%%%%%%%
function initFrameGrab

% first get the width and height of the mgl screen
screenWidth = mglGetParam('screenWidth');
screenHeight = mglGetParam('screenHeight');

% check to see if we already have a render texture
mglFrameGrabTex = mglGetParam('mglFrameGrabTex');
if isempty(mglFrameGrabTex)
  % now create a texture this size, this texture will be rendered into
  mglFrameGrabTex = mglMetalCreateTexture(zeros(screenWidth,screenHeight,4));
end

% store the texture handle for later use
mglSetParam('mglFrameGrabTex',mglFrameGrabTex)

% set it as the render target
mglMetalSetRenderTarget(mglFrameGrabTex);

%%%%%%%%%%%%%%%%%%%%%%%%
% get the frame
%%%%%%%%%%%%%%%%%%%%%%%%
function frame = getFrameGrab

% default
frame = [];

% get socket
global mgl;
socketInfo = mgl.activeSockets;

% send line command
mglSocketWrite(socketInfo, socketInfo(1).command.mglFrameGrab);
ackTime = mglSocketRead(socketInfo, 'double');

% read width and height
dataWidth = mglSocketRead(socketInfo,'uint32');
dataHeight = mglSocketRead(socketInfo,'uint32');

% display
fprintf('(mglFrameGrab) width x height: %i x %i\n',dataWidth,dataHeight);

% read the length in bytes
dataLength = mglSocketRead(socketInfo,'uint32');

% then read that many bytes
frame = mglSocketRead(socketInfo,'single',4,dataWidth,dataHeight);
frame = permute(frame,[2 3 1]);

%mglSocketWrite(socketInfo, single(v));
results = mglReadCommandResults(socketInfo, ackTime);


%%%%%%%%%%%%%%%%%%%%%%%%
% end the frame grab
%%%%%%%%%%%%%%%%%%%%%%%%
function endFrameGrab

% set the window as the render target
mglMetalSetRenderTarget;

% delete the texture
mglFrameGrabTex = mglGetParam('mglFrameGrabTex');
if ~isempty(mglFrameGrabTex)
  mglDeleteTexture(mglFrameGrabTex);
  mglSetParam('mglFrameGrabTex',[])
end


