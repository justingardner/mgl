% mglMetalTest.m
%
%        $Id:$
%      usage: mglMetalTest()
%         by: justin gardner
%       date: 12/30/19
%    purpose:
%
function retval = mglMetalTest()

global mgl

mglMetalOpen();

% send ping to check communication
mglSetParam('verbose',1);

input('Hit ENTER to ping: ');

mglSocketWrite(mgl.s, mgl.command.mglPing);
ackTime = mglSocketRead(mgl.s, 'double');
pong = mglSocketRead(mgl.s, 'uint16');
processedTime = mglSocketRead(mgl.s, 'double');
fprintf('Ping ackTime %f pong %d processedTime %f\n', ackTime, pong, processedTime);

mglSetParam('verbose',0);

input('Hit ENTER to clear screen: ');
mglClearScreen([1 0 0]);
mglFlush;
mglFlush;

testText;
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

input('Hit ENTER to test text: ');
mglFlush;
tex = mglText('Hello World');
mglMetalBltTexture(tex);
mglFlush;


%%%%%%%%%%%%%%%%%%%%%
% Test lines
%%%%%%%%%%%%%%%%%%%%%
function testLines

input('Hit ENTER to test lines: ');
mglFlush;
mglLines2([-0.1 0], [0 -0.1], [0.1 0], [0 0.1], 5, [0.8 0.8 0.8]);
mglFlush;

%%%%%%%%%%%%%%%%%%%%%
% Test quads
%%%%%%%%%%%%%%%%%%%%%
function testQuads

input('Hit ENTER to test quads: ');

% make a checkerboard
xWidth = 0.1;yWidth = 0.1;iQuad = 1;

c = 0;
for xStart = -1:xWidth:(1-xWidth)
    c = 1-c;
    for yStart = -1:yWidth:(1-xWidth)
        c = c-(1*c)+(1-c);
        x(1:4, iQuad) = [xStart xStart+xWidth xStart+xWidth xStart];
        y(1:4, iQuad) = [yStart yStart yStart+xWidth yStart+xWidth];
        color(1:3, iQuad) = [c c c];
        inverseColor(1:3, iQuad) = [1-c 1-c 1-c];
        iQuad = iQuad + 1;
    end
end

% draw the quads
mglQuad(x,y,color);
mglFlush;

%%%%%%%%%%%%%%%%%%%%%
% Make flicker
%%%%%%%%%%%%%%%%%%%%%
input('Hit ENTER to flicker: ');
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

input('Hit ENTER to test coordinate xform: ');

% send xform
xform = eye(4);
xform(:,4) = [-0.2 0.2 0 1];
mglTransform('set', xform);

% draw traingle points
x = [0 -0.5 0.5];
y = [0.5 -0.5 -0.5];
mglPoints2(x,y,10,[1 1 1])
mglFlush;

% wait for input
input('Hit ENTER to test a different coordinate xform: ');

% write command to send coordinates
% set xform back to identity
xform = eye(4);
mglTransform('set', xform);

% draw traingle points
mglPoints2(x,y,10,[1 1 1])
mglFlush;

%%%%%%%%%%%%%%%%%%%%%
% Test texture
%%%%%%%%%%%%%%%%%%%%%
function testTexture

input('Hit ENTER to test texture: ');
mglClearScreen(0.5);
mglFlush;
mglFlush;

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

% create the texture
tex = mglMetalCreateTexture(texture);

% blt the texture
mglMetalBltTexture(tex);

% flush and wait
mglFlush;

input('Hit ENTER to test blt with drifting phase (fullscreen): ');
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
mglFullscreen(0);

input('Hit ENTER to test multiple blt with rotation and drifting phase (fullscreen): ');
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
mglFullscreen(0);

%%%%%%%%%%%%%%%%%%%%%
% Test dots
%%%%%%%%%%%%%%%%%%%%%
function testDots

input('Hit ENTER to test dots: ');

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
mglPoints2(x,y,1,[1 1 1]);
mglFlush;

input('Hit ENTER to test moving dots (fullscreen): ');
mglClearScreen(0.5);
mglFlush;
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
    mglPoints2(x,y,5,[1 1 1]);
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


%%%%%%%%%%%%%%%%%%%%%%%
%    mglFullscreen    %
%%%%%%%%%%%%%%%%%%%%%%%
function mglFullscreen(tf)

if nargin < 1
  tf = true;
end

global mgl;

if tf
    % go full screen
    mglSocketWrite(mgl.s, mgl.command.mglFullscreen);
    ackTime = mglSocketRead(mgl.s, 'double');
    processedTime = mglSocketRead(mgl.s, 'double');
    fprintf('Fullscreen ackTime %f processedTime %f\n', ackTime, processedTime);
else
    mglSocketWrite(mgl.s, mgl.command.mglWindowed);
    ackTime = mglSocketRead(mgl.s, 'double');
    processedTime = mglSocketRead(mgl.s, 'double');
    fprintf('Windowed ackTime %f processedTime %f\n', ackTime, processedTime);
end
