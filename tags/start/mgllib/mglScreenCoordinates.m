% mglScreenCoordinates.m
%
%      usage: mglScreenCoordinates()
%         by: justin gardner
%       date: 05/27/06
%    purpose: Set coordinate frame so that it is in pixels
%             with 0,0 in the top left hand corrner
%
function retval = mglScreenCoordinates()

% check arguments
if ~any(nargin == [0])
  help mglScreenCoordinates
  return
end

global MGL;

% set the transforms to identity
mglTransform('GL_MODELVIEW','glLoadIdentity');
mglTransform('GL_PROJECTION','glLoadIdentity')
mglTransform('GL_TEXTURE','glLoadIdentity')

% now set them for screen coordinates
mglTransform('GL_MODELVIEW','glScale',2.0/MGL.screenWidth,-2.0/MGL.screenHeight,1);
mglTransform('GL_MODELVIEW','glTranslate',-MGL.screenWidth/2.0,-MGL.screenHeight/2.0,0.0);

% set the globals appropriately
MGL.xDeviceToPixels = 1.0;
MGL.yDeviceToPixels = 1.0;
MGL.xPixelsToDevice = 1.0;
MGL.yPixelsToDevice = 1.0;
MGL.deviceCoords = 'screenCoordinates';
MGL.deviceRect = [0 0 MGL.screenWidth MGL.screenHeight];
MGL.deviceWidth = MGL.screenWidth;
MGL.deviceHeight = MGL.screenHeight;
MGL.screenCoordinates = 1;
MGL.deviceHDirection = 1;
MGL.deviceVDirection = -1;

