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

devicePhysicalSize = mglGetParam('devicePhysicalSize');

% get what proportion of the screen size should be used for computing visual angle
% note that if this is set to 0.5 then it guarantees that the point at half the height or width will
% be exactly correct and everything else will be an approximation (since visual angles are computed as
% if the screen is spherical around the observers eyes). 0.36 gives the best absolute error over all positions
% 0.37 gives the best sum-squared error.
p = mglGetParam('visualAngleCalibProportion');
if isempty(p),p = 0.5;end

% computed deviceWidth and deviceHeight
mglSetParam('deviceHeight',(1/p)*atan(p*devicePhysicalSize(2)/mglGetParam('devicePhysicalDistance'))/pi*180);
mglSetParam('deviceWidth',(1/p)*atan(p*devicePhysicalSize(1)/mglGetParam('devicePhysicalDistance'))/pi*180);

% It is often convenient to make sure that the pixel to degree scaling factors
% are the same in x and y - i.e. that we have square pixels. This is now an
% explicit option
forceSquarePixels = mglGetParam('visualAngleSquarePixels');
if isempty(forceSquarePixels),forceSquarePixels = 1;end
% compute the best square pixel compromise
if forceSquarePixels
  xpix2deg = mglGetParam('deviceWidth')/mglGetParam('screenWidth');
  ypix2deg = mglGetParam('deviceHeight')/mglGetParam('screenHeight');
  % if they are not the same adjust
  if (xpix2deg ~= ypix2deg)
    pix2deg = (xpix2deg + ypix2deg)/2;
    squareDiscrep = 100*abs(pix2deg-xpix2deg)/xpix2deg;
    if squareDiscrep >= 3.0
      disp(sprintf('(mglVisualAngleCoordinates) !!!!! Assuming square pixels causes an error in the '));
      disp(sprintf('vertical pix2deg of %f percent. To fix, you can either set your monitor to a mode with',squareDiscrep))
      disp(sprintf('square pixel dimensions or turn off squrePixels in mglEditScreenParams !!!!!'));
    end      
    squareDiscrep = 100*abs(pix2deg-ypix2deg)/ypix2deg;
    if squareDiscrep >= 3.0
      disp(sprintf('(mglVisualAngleCoordinates) !!!!! Assuming square pixels causes an error in the '));
      disp(sprintf('vertical pix2deg of %f percent. To fix, you can either set your monitor to a mode with',squareDiscrep))
      disp(sprintf('square pixel dimensions or turn off squrePixels in mglEditScreenParams !!!!!!'));
    end      
    mglSetParam('deviceHeight',pix2deg*mglGetParam('screenHeight'));
    mglSetParam('deviceWidth',pix2deg*mglGetParam('screenWidth'));
  end
end

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

