% mglCameraInfo.m
%
%      usage: cameraInfo = mglCameraInfo;
%         by: justin gardner
%       date: 10/07/19
%    purpose: Function to get information about connected FLIR cameras
%             For verbose info
%
%             cameraInfo = mglCameraInfo('verbose=1');
%
%             For more detailed info:
%
%             cameraInfo = mglCameraInfo('detailedInfo=1');
% 
%
function retval = mglCameraInfo(varargin)


getArgs(varargin,{'verbose=0','detailedInfo=0'});
if nargout == 0,verbose=1;end

retval = [];
retval = mglPrivateCameraInfo(verbose,detailedInfo);


