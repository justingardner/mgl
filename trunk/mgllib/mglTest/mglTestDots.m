% mglTestDots.m
%
%        $Id: mglTestDots.m 380 2008-12-31 04:39:55Z justin $
%      usage: mglTestDots(screenNumber,numsec)
%         by: justin gardner
%       date: 04/05/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: test OpenGL dots
%
function retval = mglTestDots(screenNumber,numsec)

% check arguments
if ~any(nargin == [0 1 2])
  help testdots
  return
end

% parameters
if exist('numsec')~=1,numsec = 5;,end
if ~exist('screenNumber','var'),screenNumber = [];end

% other parameters
numdots = 5000;

% open the mgl screen in visual angle coordinates
mglOpen(screenNumber);
mglVisualAngleCoordinates(57,[40 30]);

% create random dot positions that start from the left top of 
% screen (mglGetParam('deviceRect')(1,2)) and go to the right bottom of screen
deviceRect = mglGetParam('deviceRect');
dots.x = deviceRect(1)+rand(1,numdots)*mglGetParam('deviceWidth');
dots.y = deviceRect(2)+rand(1,numdots)*mglGetParam('deviceHeight');

% get start time
starttime = mglGetSecs;

% set dot speed to 10 deg/sec
dx = 10/mglGetParam('frameRate');

% run it
for i = 1:mglGetParam('frameRate')*numsec
  % clear the screen to gray
  mglClearScreen([0.2 0.2 0.2]);
  % draw points with size 2 and color white
  mglPoints2(dots.x,dots.y,2,[1 1 1]);
%   mglGluDisk(dots.x,dots.y,2*mglGetParam('xPixelsToDevice'),[1 1 1]);
  % flush the buffer to display the dots and
  % wait for a screen update
  mglFlush;
  % upate the dot position
  dots.x = dots.x-dx;
  % if the dots have gone off the left hand portion of the screen
  % move them to the other side
  dots.x(dots.x<deviceRect(1)) = dots.x(dots.x<deviceRect(1))+mglGetParam('deviceWidth');
end
endtime = mglGetSecs;

% display how long the program took to run
disp(sprintf('Ran for: %0.8f sec Intended: %0.8f sec',endtime-starttime,numsec));
disp(sprintf('Difference from intended: %0.8f ms',1000*((endtime-starttime)-numsec)));
disp(sprintf('Number of frames lost: %i/%i (%0.2f%%)',round(((endtime-starttime)-numsec)*mglGetParam('frameRate')),numsec*mglGetParam('frameRate'),100*(((endtime-starttime)-numsec)*mglGetParam('frameRate'))/(mglGetParam('frameRate')*numsec)));

%close screen
mglClose;
