function mglVisualAngleCoordinates(physicalDistance,physicalSize);
% mglVisualAngleCoordinates(physicalDistance,physicalSize);
% 
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%        $Id$
% Sets view transformation to correspond to visual angles (in degrees)
% given size and distance of display. Display must be open and have 
% valid width and height (retrieved using mglGetParam
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

if mglGetParam('displayNumber') == -1
  disp(sprintf('(mglVisualAngleCoordinates) No open display'));
  return
end

% remember old settings
oldDeviceHDirection = mglGetParam('deviceHDirection');
oldDeviceVDirection = mglGetParam('deviceVDirection');
oldXDeviceToPixels = mglGetParam('xDeviceToPixels');
oldYDeviceToPixels = mglGetParam('yDeviceToPixels');

% get distance and size of screen (either from
% passed in variables or from global
if (exist('physicalDistance','var') & length(physicalDistance)==1)
  mglSetParam('devicePhysicalDistance',physicalDistance);
end
if (exist('physicalSize','var') & length(physicalSize)==2)
  mglSetParam('devicePhysicalSize',physicalSize);
end

% some defaults if they don't exist
if isempty(mglGetParam('devicePhysicalDistance'))
  mglSetParam('devicePhysicalDistance',1);
end
if isempty(mglGetParam('devicePhysicalSize'))
  mglSetParam('devicePhysicalSize',[1 1]);
end
if isempty(mglGetParam('deviceOrigin'))
  mglSetParam('deviceOrigin',[0 0 0]);
end

% set the transforms to identity
mglTransform('GL_MODELVIEW','glLoadIdentity');
mglTransform('GL_PROJECTION','glLoadIdentity')
mglTransform('GL_TEXTURE','glLoadIdentity')

% Set view transformation for 2D display

% We calculate the size of the display in degrees based on the smaller (height) 
% dimension only. While this is not quite correct, it makes for much easier drawing,
% since we can assume that distances are equal in x and y dimensions and do not change
% with viewing angle (which would be true if the screen was spherical, but is 
% increasingly incorrect for a flat screen the greater the eccentricity).
% If we correctly calculated the visual angle subtended separately for each dimension,
% a rectangle defined by (-1,-1) to (1,1) would not be exactly quadratic.


devicePhysicalSize = mglGetParam('devicePhysicalSize');
%mglSetParam('deviceWidth',360*atan(devicePhysicalSize(1)/mglGetParam('devicePhysicalDistance'))/(2*pi));
%mglSetParam('deviceHeight',360*atan(devicePhysicalSize(2)/mglGetParam('devicePhysicalDistance'))/(2*pi));
%mglSetParam('deviceWidth',2*atan(0.5*devicePhysicalSize(1)/mglGetParam('devicePhysicalDistance'))/pi*180);
mglSetParam('deviceHeight',2*atan(0.5*devicePhysicalSize(2)/mglGetParam('devicePhysicalDistance'))/pi*180);
mglSetParam('deviceWidth',mglGetParam('deviceHeight')/mglGetParam('screenHeight')*mglGetParam('screenWidth'));

% display if verbose
if (mglGetParam('verbose'))
  disp(sprintf('(mglVisualAngleCoordinates) %0.2f x %0.2f (deg)',mglGetParam('deviceWidth'),mglGetParam('deviceHeight')));
end

%calculate the number of pixels per degree
mglSetParam('xDeviceToPixels',mglGetParam('screenWidth')/mglGetParam('deviceWidth'));
mglSetParam('yDeviceToPixels',mglGetParam('screenHeight')/mglGetParam('deviceHeight'));

% calculate the opposite
mglSetParam('xPixelsToDevice',1/mglGetParam('xDeviceToPixels'));
mglSetParam('yPixelsToDevice',1/mglGetParam('yDeviceToPixels'));

% Set the device rect, based on the center being 0,0
maxx=mglGetParam('deviceWidth')/2;minx=-maxx;
maxy=mglGetParam('deviceHeight')/2;miny=-maxy;
mglSetParam('deviceRect',[minx miny maxx maxy]);

% set the transforms 
deviceOrigin = mglGetParam('deviceOrigin');
mglTransform('GL_MODELVIEW','glScale',2/mglGetParam('deviceWidth'),2/mglGetParam('deviceHeight'),1);
mglTransform('GL_MODELVIEW','glTranslate',deviceOrigin(1),deviceOrigin(2),deviceOrigin(3));
mglTransform('GL_PROJECTION','glLoadIdentity')

mglSetParam('deviceCoords','visualAngle');
mglSetParam('screenCoordinates',0);
mglSetParam('deviceHDirection',1);
mglSetParam('deviceVDirection',1);

% check to see if textures need to be recreated
if (mglGetParam('numTextures') > 0) && ...
      (oldDeviceHDirection ~= mglGetParam('deviceHDirection')) && ...
      (oldDeviceVDirection ~= mglGetParam('deviceVDirection')) && ...
      (oldXDeviceToPixels ~= mglGetParam('xDeviceToPixels')) && ...
      (oldYDeviceToPixels ~= mglGetParam('yDeviceToPixels'))
  disp(sprintf('(mglVisualAngleCoordinates) All previously created textures will need to be reoptimized with mglReoptimizeTexture'));
end

