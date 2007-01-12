% sdtdemo.m
%
%      usage: sdtdemo()
%         by: justin gardner
%       date: 09/14/06
%    purpose: 
%
function retval = sdtdemo()

% check arguments
if ~any(nargin == [0])
  help sdtdemo
  return
end

% open screen
mglOpen;

% set to visual angle coordinates
mglVisualAngleCoordinates(57,[16 12]);

% and invert monitor gamma
gamma = 1;
mglSetGammaTable(0,1,1/gamma,0,1,1/gamma,0,1,1/gamma);

% create two orthogonal gratings and their plaid
grating1 = makeGrating(5,5,2);
grating2 = makeGrating(5,5,2,90);
plaid = 255*(grating1 + 0.2*grating2 + 2)/4;
grating1 = 255*(grating1+1)/2;
grating2 = 255*(grating1+1)/2;

% create a gaussian window
gaussian = 255*makeGaussian(5,5,0.5,0.5);

% now fill out the rgb and alpha channels
grating1(:,:,2) = grating1(:,:,1);
grating1(:,:,3) = grating1(:,:,1);
grating1(:,:,4) = gaussian;

% now fill out the rgb and alpha channels
grating2(:,:,2) = grating2(:,:,1);
grating2(:,:,3) = grating2(:,:,1);
grating2(:,:,4) = gaussian;

% now fill out the rgb and alpha channels
plaid(:,:,2) = plaid(:,:,1);
plaid(:,:,3) = plaid(:,:,1);
plaid(:,:,4) = gaussian;

% make them into textures
grating1tex = mglCreateTexture(grating1);
grating2tex = mglCreateTexture(grating2);
plaidtex = mglCreateTexture(plaid);

% clear the screen and draw the plaid
mglClearScreen(0.5);
mglBltTexture(plaidtex,[0 0]);
mglFlush;

keyboard