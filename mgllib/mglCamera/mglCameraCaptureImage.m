% mglCameraCaptureImage.m
%
%      usage: cameraImage = mglCameraCaptureImage;
%         by: justin gardner
%       date: 10/07/19
%    purpose: Function to get an image from a connected FLIR cameras, if you 
%             specify a number, you can get that many consecutive images
%       e.g.: image = mglCameraCaptureImage
%       e.g.: image = mglCameraCaptureImage(100);
% 
%
function retval = mglCameraCaptureImage(nImages)

% check arguments
if ~any(nargin == [0 1])
  help mglCameraInfo
  return
end

% default argument
if nargin < 1
  nImages = 1;
end

% call private function
[retval imageWidth imageHeight] = mglPrivateCameraCaptureMovie(nImages);

% reshape output matrix 
retval = reshape(retval, imageWidth, imageHeight, size(retval,2));



