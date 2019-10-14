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
function retval = mglCameraThread(command,auxArg)

% check arguments
if ~any(nargin == [0 1 2])
  help mglCameraThread
  return
end


switch (lower(command))
 case 'init'
  % init the thread
  mglPrivateCameraThread(1);
 case 'capture'
  if nargin < 2,nFrames = 1;else,nFrames = auxArg;end
  % set to capture images
  mglPrivateCameraThread(3,nFrames);
 case 'get'
  % get the images
  [retval w h] = mglPrivateCameraThread(4);
  retval = reshape(retval,w,h,size(retval,2));
 case 'quit'
  % quit thread
  mglPrivateCameraThread(2);
end

