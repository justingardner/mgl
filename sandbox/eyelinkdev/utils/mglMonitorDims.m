% mglMonitorDims.m
%
%        $Id:$ 
%      usage: mglMonitorDims(<monitor>)
%         by: justin gardner
%       date: 01/28/09
%    purpose: A display showing monitor dimensions in degrees
%
function retval = mglMonitorDims(monitor)

% check arguments
if ~any(nargin == [0 1])
  help mglMonitorDims
  return
end

if nargin == 0,monitor = [];end
% init the screen
initScreen(monitor);

% get monitor resolution
resolution = mglResolution(mglGetParam('displayNumber'));

% get width and height of monitor
width = round(mglGetParam('deviceWidth')*10)/10;
height = round(mglGetParam('deviceHeight')*10)/10;
maxdim = ceil(sqrt((width/2).^2+(height/2).^2))*2;

% set diameters to drap
diameter = maxdim:-1:1;
redDiameters = 5:5:maxdim;
% draw circles
for d = diameter
  % get color
  if mod(find(d==diameter),2) == 0
    c = 0.2;
  else
    c = 0.3;
  end
  % draw ovals
  if any(d==redDiameters)
    mglFillOval(0,0,[d+0.5 d],[c 0 0]);
  else
    mglFillOval(0,0,[d+0.5 d],c);
  end
end
% draw labels
for r = redDiameters/2
  mglTextDraw(sprintf('-%0.1f',r),[-r 0]);
  mglTextDraw(sprintf('+%0.1f',r),[r 0]);
  mglTextDraw(sprintf('-%0.1f',r),[0 -r]);
  mglTextDraw(sprintf('+%0.1f',r),[0 r]);
end

% fixation cross in middle
mglFixationCross(0.5,2);

% draw the size of the display
mglTextDraw(sprintf('[%0.1fx%0.1f deg] at %0.1f cm',width,height,mglGetParam('devicePhysicalDistance')),[-width/2+1 -height/2+3],-1,1);
physicalSize = mglGetParam('devicePhysicalSize');
mglTextDraw(sprintf('[%ix%i pix]',mglGetParam('screenWidth'),mglGetParam('screenHeight')),[-width/2+1 -height/2+2],-1,1);
mglTextDraw(sprintf('[%0.1fx%0.1f cm]',physicalSize(1),physicalSize(2)),[-width/2+1 -height/2+1],-1,1);

% flush screen
mglFlush;

% Close when the user hits a key
mglListener('init');
mglGetKeyEvent([],1);
mglGetMouseEvent([],1);
disp(sprintf('(mglMonitorDims) Type any key to end'));
mouseEvent = mglGetMouseEvent;
while(isempty(mglGetKeyEvent) && (mouseEvent.buttons == 0))
  mouseEvent = mglGetMouseEvent;
end
mglListener('quit');
mglClose;





