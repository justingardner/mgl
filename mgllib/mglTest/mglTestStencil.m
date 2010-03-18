% mglTestStencil 
%
%        $Id: mglTestStencil.m 380 2008-12-31 04:39:55Z justin $
%      usage: mglTestStencil(screenNumber)
%         by: justin gardner
%       date: 05/26/2006
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: test stencils
%
%       e.g.:
%      
function mglTestStencil(screenNumber)

% check arguments
if ~any(nargin == [0 1])
  help mglTestStencil
  return
end

if ~exist('screenNumber','var'), screenNumber = [];,end

% open the screen and set to visual angle
mglOpen(screenNumber);
mglVisualAngleCoordinates(57,[40 30]);

% Draw another oval stencil
mglStencilCreateBegin(1);
if (mglGetParam('stencilBits')==0)
  disp('Stencils not supported on this platform.. sorry!')
  mglClose;
  return
  end
mglFillOval(0,0,[5 4]);
mglStencilCreateEnd;
mglClearScreen;

% Draw an oval stencil
mglStencilCreateBegin(2,1);
mglFillOval(0,0,[8 8]);
mglStencilCreateEnd;
mglClearScreen;

nDots=2500;
dotSize=5;
% get some random points
deviceRect = mglGetParam('deviceRect');
dots(1).x = deviceRect(1)+rand(1,nDots)*mglGetParam('deviceWidth');
dots(1).y = deviceRect(2)+rand(1,nDots)*mglGetParam('deviceHeight');
dots(2).x = deviceRect(1)+rand(1,nDots)*mglGetParam('deviceWidth');
dots(2).y = deviceRect(2)+rand(1,nDots)*mglGetParam('deviceHeight');

% set dot speed to 10 deg/sec
dx = 10/mglGetParam('frameRate');

numsec = 5;
starttime = mglGetSecs;
for i = 1:mglGetParam('frameRate')*numsec
  % now draw the dots using the two stencil's we'ver created
  mglStencilSelect(1);
  mglPoints2(dots(1).x,dots(1).y,dotSize,[0.8 0.4 0.5]);
  mglStencilSelect(2);
  mglPoints2(dots(2).x,dots(2).y,dotSize,[0.2 0.8 0.4]);
  % flush the buffer
  mglFlush;
  mglClearScreen;
  % upate the dot position
  dots(1).x = dots(1).x-dx;
  dots(1).x(dots(1).x<deviceRect(1)) = dots(1).x(dots(1).x<deviceRect(1))+mglGetParam('deviceWidth');
  dots(2).x = dots(2).x+dx;
  dots(2).x(dots(2).x>deviceRect(3)) = dots(2).x(dots(2).x>deviceRect(3))-mglGetParam('deviceWidth');
end
endtime=mglGetSecs;


mglStencilSelect(0);
mglClose;

% check how long it ran for
disp(sprintf('Ran for: %0.8f sec Intended: %0.8f sec',endtime-starttime,numsec));
disp(sprintf('Difference from intended: %0.8f ms',1000*((endtime-starttime)-numsec)));
disp(sprintf('Number of frames lost: %i/%i (%0.2f%%)',round(((endtime-starttime)-numsec)*mglGetParam('frameRate')),numsec*mglGetParam('frameRate'),100*(((endtime-starttime)-numsec)*mglGetParam('frameRate'))/(mglGetParam('frameRate')*numsec)));


