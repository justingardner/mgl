% mglMonitorDims.m
%
%        $Id$ 
%      usage: mglMonitorDims(<monitor>)
%         by: justin gardner
%       date: 01/28/09
%    purpose: A display showing monitor dimensions in degrees.
%
%             If monitor is -1, then this just draws to an already open display, does not flush and returns immediately
%             (for use with mglEditScreenParams)
%
function retval = mglMonitorDims(monitor)

% check arguments
if ~any(nargin == [0 1])
  help mglMonitorDims
  return
end

if nargin == 0,monitor = [];end
if ~isequal(monitor,-1)
  % init the screen
  initScreen(monitor);
end

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
% add polar angle lines
for ang = 0:15:360
    rang = d2r(ang);
    x = cos(rang)*diameter;
    y = sin(rang)*diameter;
    mglLines2(0,0,x,y,1,[.5 .5 .5]);
end

% draw labels
yPos = 1;
for r = redDiameters
  mglTextDraw(sprintf('-%0.1f',r),[-r yPos]);
  mglTextDraw(sprintf('+%0.1f',r),[r yPos]);
  yPos = yPos*-1;
end
for r = redDiameters/2
  mglTextDraw(sprintf('-%0.1f',r),[0 -r]);
  mglTextDraw(sprintf('+%0.1f',r),[0 r]);
end

% fixation cross in middle
mglFixationCross(0.5,2);

% draw the size of the display
mglTextDraw(sprintf('[%0.1fx%0.1f deg] at %0.1f cm',width,height,mglGetParam('devicePhysicalDistance')),[-width/2+1 -height/2+height/9],-1,1);
physicalSize = mglGetParam('devicePhysicalSize');
mglTextDraw(sprintf('[%ix%i pix]',mglGetParam('screenWidth'),mglGetParam('screenHeight')),[-width/2+1 -height/2+2*height/9],-1,1);
mglTextDraw(sprintf('[%0.1fx%0.1f cm]',physicalSize(1),physicalSize(2)),[-width/2+1 -height/2+3*height/9],-1,1);

if ~isequal(monitor,-1)

  % flush screen
  mglFlush;

  % Close when the user hits a key
  mglListener('init');
  mglGetKeyEvent([],1);
  keyEvent = [];
  disp(sprintf('(mglMonitorDims) Type ESC to end'));
  while isempty(keyEvent) || (keyEvent.keyCode ~= 54)
    keyEvent = mglGetKeyEvent;
  end
  mglListener('quit');
  mglClose;
end




% convert degrees to radians
%
% usage: radians = d2r(degrees);
function radians = d2r(angle)

radians = (angle/360)*2*pi;
