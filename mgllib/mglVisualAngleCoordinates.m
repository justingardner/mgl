function mglVisualAngleCoordinates(physicalDistance,physicalSize);
% mglVisualAngleCoordinates(physicalDistance,physicalSize);
% 
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%        $Id$
% Sets view transformation to correspond to visual angles (in degrees)
% given size and distance of display. Display must be open
%
%       physicalDistance': [distance] <in cm>
%           physicalSize': [xsize ysize] <in cm> 
%
% Note that there are two settings that control how this function works.
% One is whether you want to set the coordinates for square pixels
%
% mglSetParam('visualAngleSquarePixels',1)
%
% What this does is set the transformation to have the same pix2deg in
% the x and y dimension. This is useful for things like rotating a texture with
% mglBltTexture which basically has to assume that pixels are square (i.e. it
% does not scale the texture differently when it is oriented horizontally vs
% vertically, for instance). If you wanted to compensate for non-square pixels
% it would be a bit messy. So visualAngleSquarePixels defaults to 1.
%
% mglSetParam('visualAngleCalibProportion',0.5)
%
% When you calibrate the monitor, you have to decide how to compute the pix2deg.
% Whatever you calibrate on, say half the height or width of the monitor will
% come out exactly right. But, any distance away from that point will be distorted
% This is because visual angles are basically a spherical coordinate frame and
% we are doing a linear transformation (a scale factor in x and y) which is only
% approximately correct. That is, visual angles assumes that the screen is curved
% around the eye, but the screen is actually flat. If you want to see exactly what
% distortion this will cause in the horizontal and vertical dimensions for your
% settings, you can run: mglDispVisualAngleDiscrepancy. This value defaults to 0.5
% which makes the top, bottom, left and right of your screen be accurate, but in
% between be inaccurate. For the minimum absolute distortion across all locations,
% you can set this value to 0.36
%
%e.g.:
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

% get the scaling - this is sometimes used to artificially scale
% the display from the actual computation.
visualAngleScale = mglGetParam('visualAngleScale');
if isempty(visualAngleScale) || (length(visualAngleScale) ~= 2)
  % set back to [1 1] - no scaling, if above conditions are not met
  visualAngleScale = [1 1];
end
  
% computed deviceWidth and deviceHeight
mglSetParam('deviceHeight',visualAngleScale(2)*(1/p)*atan(p*devicePhysicalSize(2)/mglGetParam('devicePhysicalDistance'))/pi*180);
mglSetParam('deviceWidth',visualAngleScale(1)*(1/p)*atan(p*devicePhysicalSize(1)/mglGetParam('devicePhysicalDistance'))/pi*180);

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
    if squareDiscrep >= 5.0
      disp(sprintf('(mglVisualAngleCoordinates) !!!!! Assuming square pixels causes an error in the '));
      disp(sprintf('vertical pix2deg of %f percent. To fix, you can either set your monitor to a mode with',squareDiscrep))
      disp(sprintf('square pixel dimensions or turn off squrePixels in mglEditScreenParams if you are'));
      disp(sprintf('using mglEditScreenParams or set mglSetParam(''visualAngleSquarePixels'',0,1) if not!!!!!!'));
    end      
    squareDiscrep = 100*abs(pix2deg-ypix2deg)/ypix2deg;
    if squareDiscrep >= 5.0
      disp(sprintf('(mglVisualAngleCoordinates) !!!!! Assuming square pixels causes an error in the '));
      disp(sprintf('vertical pix2deg of %f percent. To fix, you can either set your monitor to a mode with',squareDiscrep))
      disp(sprintf('square pixel dimensions or turn off squrePixels in mglEditScreenParams if you are'));
      disp(sprintf('using mglEditScreenParams or set mglSetParam(''visualAngleSquarePixels'',0,1) if not!!!!!!'));
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

