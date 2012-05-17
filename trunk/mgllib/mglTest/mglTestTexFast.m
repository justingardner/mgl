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
imageWidth = 300;
imageHeight = 200;

% number of refershes to test for
n = 100;

% array that keeps the time it takes to run various things
times = nan(5,n);

% initialize the image array
r = zeros(4,imageWidth,imageHeight);
r(4,:) = 255;
r = uint8(r);
r(1,1:5:imageWidth,:) = 255;
r(2,1:5:imageWidth,:) = 0;
r(3,1:5:imageWidth,:) = 0;

% compute position to display
imageX = mglGetParam('screenWidth')/2;
imageY = mglGetParam('screenHeight')/2;

for i = 1:n
  % clear screen
  mglClearScreen;

  % make random matrix
  startTime = mglGetSecs;
  r(1:3,:,:) = uint8(rand(3,imageWidth,imageHeight)*255);
  times(1,i) = mglGetSecs(startTime);
  profileName{1} = 'rand';
  startTime = mglGetSecs;

  % create texture from random matrix
  tex = mglCreateTexture(r);
  times(2,i) = mglGetSecs(startTime);
  profileName{2} = 'mglCreateTexture';
  startTime = mglGetSecs;
  
  % blt texture
  mglBltTexture(tex,[imageX imageY imageWidth imageHeight]);
  times(3,i) = mglGetSecs(startTime);
  profileName{3} = 'mglBltTexture';
  startTime = mglGetSecs;

  % flush
  mglFlush;
  times(4,i) = mglGetSecs(startTime);
  profileName{4} = 'mglFlush';
  startTime = mglGetSecs;

  % delete texture
  mglDeleteTexture(tex);
  times(5,i) = mglGetSecs(startTime);
  profileName{5} = 'mglDeleteTexture';
  startTime = mglGetSecs;
end

% display the median time 
for i = 1:size(times,1)
  disp(sprintf('%s: %0.2fms',profileName{i},1000*median(times(i,:))));
end

mglClose;
