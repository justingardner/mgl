% mglCameraCapture.m
%
%      usage: cameraImage = mglCameraCapture;
%         by: justin gardner
%       date: 10/07/19
%    purpose: Function to get an image from a connected FLIR cameras, if you 
%             specify a number, you can get that many consecutive images
%       e.g.: image = mglCameraCapture
%       e.g.: image = mglCameraCapture(100);
% 
%
function retval = mglCameraCapture(nImages)

% check arguments
if ~any(nargin == [0 1])
  help mglCameraCapture
  return
end

% default argument
if nargin < 1
  nImages = 1;
end

% which camera to get data from
cameraNum = 1;

% call private function
[retval imageWidth imageHeight] = mglPrivateCameraCapture(cameraNum,nImages);

% reshape output matrix 
if ~isempty(retval)
  retval = reshape(retval, imageWidth, imageHeight, size(retval,2));
end



