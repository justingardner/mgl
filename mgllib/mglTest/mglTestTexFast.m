% mglTestTexFast.m
%
%        $Id:$ 
%      usage: mglTestTexFast()
%         by: justin gardner
%       date: 05/17/12
%    purpose: 
%
function retval = mglTestTexFast()

% check arguments
if ~any(nargin == [0])
  help mglTestTexFast
  return
end

% open screen
mglOpen(0.8);
mglScreenCoordinates;

% size of image to blt
imageWidth = 800;
imageHeight = 600;

% number of refershes to test for
n = 100;

% array that keeps the time it takes to run various things
times = nan(5,n);

% use mglBindText instead of creating
% a texture every time. This keeps the
% same memory buffer for the texture
bindtex = true;

% set whether to use quick preformatted uint8 input to mglCreateTexture or not
preformat = true;

% initialize the image array
if preformat
  r = zeros(4,imageWidth,imageHeight);
  r(4,:) = 255;
  r = uint8(r);
else
  r = zeros(imageWidth,imageHeight,4);
  r(:,:,4) = 255;
end

% compute position to display
imageX = mglGetParam('screenWidth')/2;
imageY = mglGetParam('screenHeight')/2;

% set profile names
profileName{1} = 'rand';
profileName{2} = 'mglCreateTexture';
profileName{3} = 'mglBltTexture';
profileName{4} = 'mglFlush';
profileName{5} = 'mglDeleteTexture';

if bindtex
  tex = mglCreateTexture(r,[],1);
  profileName{2} = 'mglBindTexture';
end

for i = 1:n
  % clear screen
  mglClearScreen;

  % make random matrix
  startTime = mglGetSecs;
  if preformat
    r(1:3,:,:) = uint8(rand(3,imageWidth,imageHeight)*255);
  else
    r(:,:,1:3) = rand(imageWidth,imageHeight,3)*255;
  end
  times(1,i) = mglGetSecs(startTime);
  startTime = mglGetSecs;

  % create texture from random matrix
  if bindtex
    mglBindTexture(tex,r);
  else
    tex = mglCreateTexture(r,'yx');
  end
  times(2,i) = mglGetSecs(startTime);
  startTime = mglGetSecs;
  
  % blt texture
  mglBltTexture(tex,[imageX imageY imageWidth imageHeight]);
  times(3,i) = mglGetSecs(startTime);
  startTime = mglGetSecs;

  % flush
  mglFlush;
  times(4,i) = mglGetSecs(startTime);
  startTime = mglGetSecs;

  % delete texture
  if ~bindtex,mglDeleteTexture(tex);end

  times(5,i) = mglGetSecs(startTime);
  startTime = mglGetSecs;
end

% delete texture
if bindtex,mglDeleteTexture(tex);end

% display the median time 
for i = 1:size(times,1)
  disp(sprintf('%s: %0.2fms',profileName{i},1000*median(times(i,:))));
end

mglClose;
