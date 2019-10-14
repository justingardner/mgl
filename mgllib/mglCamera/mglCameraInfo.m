% mglCameraInfo.m
%
%      usage: cameraInfo = mglCameraInfo;
%         by: justin gardner
%       date: 10/07/19
%    purpose: Function to get information about connected FLIR cameras
% 
%
function retval = mglCameraInfo()

% check arguments
if ~any(nargin == [0])
  help mglCameraInfo
  return
end

% call private function
retval = mglPrivateCameraInfo;
retval.info{1}


