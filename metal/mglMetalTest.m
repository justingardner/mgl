% mglMetalTest.m
%
%        $Id:$
%      usage: mglMetalTest()
%         by: justin gardner
%       date: 12/30/19
%    purpose:
%
function retval = mglMetalTest(varargin)

global mgl

runWithXcode = false;

% run only on initial setup
if nargin <= 1
  if (nargin==1) && isequal(varargin{1},1)
    runWithXcode = true;
  end

  mglSetParam('verbose',1);
  if runWithXcode
    disp(sprintf('Startup mglMetal with XCode now...'))
    mglMetalOpen(nan);
  else
    mglMetalOpen;
  end

  % send ping to check communication
  myinput('Hit ENTER to ping: ');
  mgl.s = mglSocketWrite(mgl.s,uint16(mgl.command.ping));
  mglFullscreen(0);

  %testText;

  % clear screen
  myinput('Hit ENTER to clear screen: ');
  mglClearScreen([1 0 0]);
  mglFlush;


elseif isequal(varargin{1},2)
  % go full screen
  mglFullscreen;
  mgl.noask = true;
else
  % go windowed
  mglFullscreen(0);
  mgl.noask = false;
end

% turn off verbose
mglSetParam('verbose',0);

% check profile
%input('Hit ENTER to turn profiling on: ');
%disp(sprintf('setting profile on'));
%mglProfile(true);

% now have command loop read commands until there is a fulsh
mglFullscreen(0);

testLines;
testQuads;
testCoords;
testTexture;
testDots;

mglMetalShutdown;
%%%%%%%%%%%%%%%%%%%%%
% Test text
%%%%%%%%%%%%%%%%%%%%%
function testText

myinput('Hit ENTER to test text: ');
mglClearScreen(0);
mglFlush;
tex = mglText('Hello World');
mglMetalBltTexture(tex);
mglFlush;


%%%%%%%%%%%%%%%%%%%%%
% Test lines
%%%%%%%%%%%%%%%%%%%%%
function testLines

myinput('Hit ENTER to test lines: ');
mglFlush;
mglLines2([-0.1 0], [0 -0.1], [0.1 0], [0 0.1], 5, [0.8 0.8 0.8]);
mglFlush;

%%%%%%%%%%%%%%%%%%%%%
% Test quads
%%%%%%%%%%%%%%%%%%%%%
function testQuads

global mgl

myinput('Hit ENTER to test quads: ');

% make a checkerboard
xWidth = 0.1;yWidth = 0.1;iQuad = 1;

c = 0;
for xStart = -1:xWidth:(1-xWidth)
  c = 1-c;
  for yStart = -1:yWidth:(1-xWidth)
    c = c-(1*c)+(1-c);
    x(iQuad,1:4) = [xStart xStart+xWidth xStart+xWidth xStart];
    y(iQuad,1:4) = [yStart yStart yStart+xWidth yStart+xWidth];
    color(iQuad,1:3) = [c c c];
    inverseColor(iQuad,1:3) = [1-c 1-c 1-c];
    iQuad = iQuad + 1;
  end
end

% draw the quads
mglProfile('on');
mglQuad(x,y,color);
mglProfile('off');
mglFlush;

%%%%%%%%%%%%%%%%%%%%%
% Make flicker
%%%%%%%%%%%%%%%%%%%%%
myinput('Hit ENTER to flicker: ');
nFlicker = 10;nFlush = 10;
for iFlicker = 1:nFlicker
  for iFlush = 1:nFlush
    % draw the quads
    mglQuad(x,y,color);
    mglFlush;
  end
  % flush
  for iFlush = 1:nFlush
    % draw the quads
    mglQuad(x,y,inverseColor);
    mglFlush;
  end
end


%%%%%%%%%%%%%%%%%%%%%
% Test coord xform
%%%%%%%%%%%%%%%%%%%%%
function testCoords

global mgl
myinput('Hit ENTER to test coordinate xform: ');

% write command to send coords
mglProfile('start');
mgl.s = mglSocketWrite(mgl.s,uint16(mgl.command.xform));

% send xform
xform = eye(4);
xform(:,4) = [-0.2 0.2 0 1];
mgl.s = mglSocketWrite(mgl.s,single(xform(:)));
mglProfile('end','testCoords');

% draw traingle points
x = [0 -0.5 0.5];
y = [0.5 -0.5 -0.5];
mglPoints2(x,y,10,[1 1 1])
mglFlush;

% wait for input
myinput('Hit ENTER to test coordinate xform: ');

% write command to send coordinates
mglProfile('start');
mgl.s = mglSocketWrite(mgl.s,uint16(mgl.command.xform));

% set xform back to identity
xform = eye(4);
mgl.s = mglSocketWrite(mgl.s,single(xform(:)));
mglProfile('end','testCoords');

% draw traingle points
mglPoints2(x,y,10,[1 1 1])
mglFlush;

%%%%%%%%%%%%%%%%%%%%%
% Test texture
%%%%%%%%%%%%%%%%%%%%%
function testTexture

global mgl

myinput('Hit ENTER to test texture: ');
mglClearScreen(0.5);mglFlush;mglFlush;

% create a texture
textureWidth = 256;
textureHeight = 256;
maxVal = 1.0;
sigma = 0.5;
[tx ty] = meshgrid(0:2*pi/(textureWidth-1):2*pi,0:2*pi/(textureHeight-1):2*pi);
[ex ey] = meshgrid(-1:2/(textureWidth-1):1,-1:2/(textureHeight-1):1);
clear texture;
sf = 6;
texture(:,:,1) = maxVal*(cos(sf*ty+pi/4)+1)/2;
texture(:,:,2) = maxVal*(cos(sf*ty+pi/4)+1)/2;
texture(:,:,3) = maxVal*(cos(sf*ty+pi/4)+1)/2;
texture(:,:,4) = maxVal*(exp(-((ex.^2+ey.^2)/sigma^2)));

% turn on profiling
mglProfile('on');

% create the texture
tex = mglMetalCreateTexture(texture);

% blt the texture
mglMetalBltTexture(tex);

% turn off profiling
mglProfile('off');

% flush and wait
mglFlush;

myinput('Hit ENTER to test blt (drifting): ');
mglFullscreen;

nFrames = 300;
phase = 0;
for iFrame = 1:nFrames
  frameStart = mglGetSecs;
  mglMetalBltTexture(tex,[0 0],0,0,0,phase);
  phase = phase + (1/60)/4;
  % flush and wait
  mglFlush;
  frameTime(iFrame) = mglGetSecs(frameStart);
end
dispFrameTimes(frameTime);
if ~mgl.noask,mglFullscreen(0);end

myinput('Hit ENTER to test blt (multiple rotating and drifting): ');
mglFullscreen;

nFrames = 300;
phase = 0;rotation = 0;width = 0.25;height = 0.25;
for iFrame = 1:nFrames
  frameStart = mglGetSecs;
  mglMetalBltTexture(tex,[-0.5 -0.5],0,0,rotation,phase,width,height);
  mglMetalBltTexture(tex,[-0.5 0.5],0,0,-rotation,phase,width,height);
  mglMetalBltTexture(tex,[0.5 0.5],0,0,rotation,phase,width,height);
  mglMetalBltTexture(tex,[0.5 -0.5],0,0,-rotation,phase,width,height);
  mglMetalBltTexture(tex,[0 -0.5],0,0,rotation,phase,width,height);
  mglMetalBltTexture(tex,[0 0.5],0,0,-rotation,phase,width,height);
  mglMetalBltTexture(tex,[-0.5 0],0,0,rotation,phase,width,height);
  mglMetalBltTexture(tex,[0.5 0],0,0,-rotation,phase,width,height);

  mglMetalBltTexture(tex,[0 0],1,-1,rotation,phase,width,height);
  mglMetalBltTexture(tex,[0 0],1,1,rotation,phase,width,height);
  mglMetalBltTexture(tex,[0 0],-1,-1,rotation,phase,width,height);
  mglMetalBltTexture(tex,[0 0],-1,1,rotation,phase,width,height);

  phase = phase + (1/60)/4;
  rotation = rotation+360/nFrames;
  % flush and wait
  mglFlush;
  frameTime(iFrame) = mglGetSecs(frameStart);
end
dispFrameTimes(frameTime);
if ~mgl.noask,mglFullscreen(0);end

%%%%%%%%%%%%%%%%%%%%%
% Test dots
%%%%%%%%%%%%%%%%%%%%%
function testDots

global mgl

myinput('Hit ENTER to test dots: ');

% turn on profiling
mglProfile('on');

% make a glass pattern
nDots = 1000;
r = rand(1,nDots);
theta = rand(1,nDots)*2*pi;
x = r.*cos(theta);
y = r.*sin(theta);

deltaTheta = pi*(2/180);
x(end+1:end+nDots) = r.*cos(theta+deltaTheta);
y(end+1:end+nDots) = r.*sin(theta+deltaTheta);

mglFlush;
mglPoints2(x,y,1,[1 1 1])
mglProfile('off');
mglFlush;

myinput('Hit ENTER to test dots: ');
mglClearScreen(0.5);
mglFullscreen;

nVertices = 1000;
deltaX = 0.005;
deltaR = 0.005;
deltaTheta = 0.03;
nFrames = 1000;
vertices = [];
r = 0.25*rand(1,nVertices)+0.01;
theta = rand(1,nVertices)*2*pi;
x = cos(theta).*r;
y = sin(theta).*r;
coherence = 0.8;

for iFrame = 1:nFrames
  frameStart = mglGetSecs;
  mglPoints2(x,y,5,[1 1 1])
  mglFlush;
  r = r + deltaR;
  theta = theta + deltaTheta;
  badpoints = find(r>0.75);
  r(badpoints) = 0.74*rand(1,length(badpoints))+0.01;
  x = cos(theta).*r;
  y = sin(theta).*r;
  frameTime(iFrame) = mglGetSecs(frameStart);
end

dispFrameTimes(frameTime);

mglFullscreen(0);

% send non-blocking command
mglProfile('start');
mgl.s = mglSocketWrite(mgl.s,uint16(mgl.command.nonblocking));
mglProfile('end','non-blocking');

%%%%%%%%%%%%%%%%%%%%%%%%
%    dispFrameTimes    %
%%%%%%%%%%%%%%%%%%%%%%%%
function dispFrameTimes(frameTime)

frameTime = frameTime(30:end);
expectedFrameTime = 1/60;
nFrames = length(frameTime);
disp(sprintf('(mglMetalTest) Median frame time: %0.4f',median(frameTime)));
disp(sprintf('(mglMetalTest) Max frame time: %0.4f',max(frameTime)));
disp(sprintf('(mglMetalTest) Number of frames over %0.4f: %i/%i',expectedFrameTime,sum(frameTime>expectedFrameTime),nFrames));
disp(sprintf('(mglMetalTest) Number of frames 5%% over %0.4f: %i/%i',expectedFrameTime,sum(frameTime>(expectedFrameTime*1.05)),nFrames));
disp(sprintf('(mglMetalTest) Number of frames 10%% over %0.4f: %i/%i',expectedFrameTime,sum(frameTime>(expectedFrameTime*1.1)),nFrames));
disp(sprintf('(mglMetalTest) Number of frames 20%% over %0.4f: %i/%i',expectedFrameTime,sum(frameTime>(expectedFrameTime*1.2)),nFrames));


%%%%%%%%%%%%%%%%%
%    myinput    %
%%%%%%%%%%%%%%%%%
function myinput(str)

global mgl

if ~mgl.noask
  input(str);
end


%%%%%%%%%%%%%%%%%%%%%%%
%    mglFullscreen    %
%%%%%%%%%%%%%%%%%%%%%%%
function mglFullscreen(tf)

if nargin < 1, tf = true;end

global mgl;

if tf
  % go full screen
  mglProfile('start');
  mgl.s = mglSocketWrite(mgl.s,uint16(mgl.command.fullscreen));
  mglProfile('end','mglFullscreen');
else
  mglProfile('start');
  mgl.s = mglSocketWrite(mgl.s,uint16(mgl.command.windowed));
  mglProfile('end','mglWindowed');
end

% do a few flushes to make sure that the screen is actually updated correctly
mglFlush;mglFlush;mglFlush;mglFlush;
mglFlush;mglFlush;mglFlush;mglFlush;
