% mglCameraCapture.m
%
%      usage: mglCameraThread(<commands>)
%         by: justin gardner
%       date: 10/14/2019
%    purpose: Function that starts and interacts with a thread so that we can interact
%             with an FLIR camera asynchronously.
% 
%             First you start the thread which initializes the camera and gets it ready to go
%
%             mglCameraThread('init');
%
%             Then you can capture a set of frames
%
%             mglCameraThread('capture',100);
%
%             When that is done you can get the frames into a buffer
%
%             im = mglCameraThread('get');
%
%             To quit the thread
%
%             mglCameraThread('quit');
% 
%
function retval = mglCameraThread(command,varargin)

% check arguments
if nargin < 1
  help mglCameraThread
  return
end

% parse arguments
getArgs(varargin,{'cameraNum=1','maxFrames=100000','timeToCapture=1'});

switch (lower(command))
 
 case 'init'

  % init the thread
  mglPrivateCameraThread(1,cameraNum,maxFrames);
  
 case 'capture'
  currentTime = mglGetSecs;
  dispHeader(sprintf('(mglCameraThread) Capture begin at: %5.3f',currentTime));
  % set to capture images
  mglPrivateCameraThread(3,currentTime+timeToCapture);
  
 case 'get'
  % get the images
  [im w h t cameraStart cameraEnd systemStart systemEnd] = mglPrivateCameraThread(4);
  % reshape and return as struct
  retval.im = reshape(im,w,h,size(im,2));
  % figure out slope and offset of relationship to system time
  m = (systemEnd-systemStart)/(cameraEnd-cameraStart);
  offset = systemStart-cameraStart*m;
  % convert camera time to system time based on these
  retval.t = t*m+offset;
 
 case 'quit'
  % quit thread
  mglPrivateCameraThread(2);
  
end

