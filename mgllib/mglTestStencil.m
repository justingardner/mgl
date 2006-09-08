% mglTestStencil 
%
%        $Id$
%      usage: mglTestStencil(screenNumber)
%         by: justin gardner
%       date: 05/26/2006
%    purpose: test stencils
%
%       e.g.:
%      
function mglTestStencil(screenNumber)

  global MGL
  
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
if (MGL.stencilBits==0)
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

global MGL;

% get some random points
dots(1).x = MGL.deviceRect(1)+rand(1,5000)*MGL.deviceWidth;
dots(1).y = MGL.deviceRect(2)+rand(1,5000)*MGL.deviceHeight;
dots(2).x = MGL.deviceRect(1)+rand(1,5000)*MGL.deviceWidth;
dots(2).y = MGL.deviceRect(2)+rand(1,5000)*MGL.deviceHeight;

% set dot speed to 10 deg/sec
dx = 10/MGL.frameRate;

numsec = 5;
starttime = GetSecs;
for i = 1:MGL.frameRate*numsec
  % now draw the dots using the two stencil's we'ver created
  mglStencilSelect(1);
  mglPoints2(dots(1).x,dots(1).y,2,[0.8 0.4 0.5]);
  mglStencilSelect(2);
  mglPoints2(dots(2).x,dots(2).y,2,[0.2 0.8 0.4]);
  % flush the buffer
  mglFlush;
  mglClearScreen;
  % upate the dot position
  dots(1).x = dots(1).x-dx;
  dots(1).x(dots(1).x<MGL.deviceRect(1)) = dots(1).x(dots(1).x<MGL.deviceRect(1))+MGL.deviceWidth;
  dots(2).x = dots(2).x+dx;
  dots(2).x(dots(2).x>MGL.deviceRect(3)) = dots(2).x(dots(2).x>MGL.deviceRect(3))-MGL.deviceWidth;
end
endtime=GetSecs;

mglClose;

% check how long it ran for
disp(sprintf('Ran for: %0.8f sec Intended: %0.8f sec',endtime-starttime,numsec));
disp(sprintf('Difference from intended: %0.8f ms',1000*((endtime-starttime)-numsec)));
disp(sprintf('Number of frames lost: %i/%i (%0.2f%%)',round(((endtime-starttime)-numsec)*MGL.frameRate),numsec*MGL.frameRate,100*(((endtime-starttime)-numsec)*MGL.frameRate)/(MGL.frameRate*numsec)));


