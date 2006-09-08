function mglVisualAngleCoordinates(physicalDistance,physicalSize);
% mglVisualAngleCoordinates(physicalDistance,physicalSize);
% 
% Sets view transformation to correspond to visual angles (in degrees)
% given size and distance of display. Display must be open and have 
% valid width and height (defined in MGL variable)
%
%       physicalDistance': [distance] <in cm>
%           physicalSize': [xsize ysize] <in cm> 
%    e.g.:
%
%mglOpen
%mglVisualAngleCoordinates(57,[16 12]);

% check input arguments
if ~any(nargin==[2])
  help mglVisualAngleCoordinates;
  return
end

% declare MGL global
global MGL

% get distance and size of screen (either from
% passed in variables or from global
if (exist('physicalDistance','var') & length(physicalDistance)==1)
  MGL.devicePhysicalDistance=physicalDistance;
end
if (exist('physicalSize','var') & length(physicalSize)==2)
  MGL.devicePhysicalSize=physicalSize;
end

% some defaults if they don't exist
if (~isfield(MGL,'devicePhysicalDistance') | isempty(MGL.devicePhysicalDistance))
  MGL.devicePhysicalDistance=1;
end
if (~isfield(MGL,'devicePhysicalSize') | isempty(MGL.devicePhysicalSize))
  MGL.devicePhysicalSize=[1 1];
end
if (~isfield(MGL,'deviceOrigin') | isempty(MGL.deviceOrigin))
  MGL.deviceOrigin=[0 0 0];
end

% set the transforms to identity
mglTransform('GL_MODELVIEW','glLoadIdentity');
mglTransform('GL_PROJECTION','glLoadIdentity')
mglTransform('GL_TEXTURE','glLoadIdentity')

% Set view transformation for 2D display
% Calculate pixels/deg based on x direction only - we assume
% isotropic pixels and screens

MGL.deviceWidth=360*atan(MGL.devicePhysicalSize(1)/MGL.devicePhysicalDistance)/(2*pi);
MGL.deviceHeight=360*atan(MGL.devicePhysicalSize(2)/MGL.devicePhysicalDistance)/(2*pi);

% display if verbose
if (MGL.verbose)
  disp(sprintf('(mglVisualAngleCoordinates) %0.2f x %0.2f (deg)',MGL.deviceWidth,MGL.deviceHeight));
end

%calculate the number of pixels per degree
MGL.xDeviceToPixels=MGL.screenWidth/MGL.deviceWidth;
MGL.yDeviceToPixels=MGL.screenHeight/MGL.deviceHeight;

% calculate the opposite
MGL.xPixelsToDevice=1/MGL.xDeviceToPixels;
MGL.yPixelsToDevice=1/MGL.yDeviceToPixels;

% Set the device rect, based on the center being 0,0
maxx=MGL.deviceWidth/2;minx=-maxx;
maxy=MGL.deviceHeight/2;miny=-maxy;
MGL.deviceRect=[minx miny maxx maxy];

% set the transforms 
mglTransform('GL_MODELVIEW','glScale',2/MGL.deviceWidth,2/MGL.deviceHeight,1);
mglTransform('GL_MODELVIEW','glTranslate',MGL.deviceOrigin(1),MGL.deviceOrigin(2),MGL.deviceOrigin(3));
mglTransform('GL_PROJECTION','glLoadIdentity')

MGL.deviceCoords = 'visualAngle';
MGL.screenCoordinates=0;
MGL.deviceHDirection = 1;
MGL.deviceVDirection = 1;

