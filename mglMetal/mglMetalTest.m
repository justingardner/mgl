% mglMetalTest.m
%
%        $Id:$ 
%      usage: mglMetalTest()
%         by: justin gardner
%       date: 12/30/19
%    purpose: 
%
function retval = mglMetalTest(varargin)

cd('~/Library/Containers/gru.mglMetal/Data');

global mgl
mgl.command.ping = 0;
mgl.command.clearScreen = 1;
mgl.command.dots = 2;
mgl.command.flush = 3;
mgl.command.texture = 4;
mgl.command.xform = 5;
mgl.command.line = 6;
mgl.command.quad = 7;
mgl.command.test = 256;

if nargin < 1
  mglSetParam('verbose',1);
  mglOpen;
  
  input('Hit ENTER to ping: ');
  mgl.s = mglSocketWrite(mgl.s,uint16(mgl.command.ping));

  input('Hit ENTER to clear screen: ');
  mglClearScreen([1 0 0]);
  mglFlush;mglFlush;
end

mglSetParam('verbose',0);

%%%%%%%%%%%%%%%%%%%%%
% Test quads
%%%%%%%%%%%%%%%%%%%%%
input('Hit ENTER to test lines: ');
mglLines2([-0.5 0], [0 -0.5], [0.5 0], [0 0.5], 5, [0.8 0.8 0.8]);
mglFlush;

%%%%%%%%%%%%%%%%%%%%%
% Test quads
%%%%%%%%%%%%%%%%%%%%%
input('Hit ENTER to test quads: ');
mgl.s = mglSocketWrite(mgl.s,uint16(mgl.command.quad));
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
mglQuad(x,y,color);
mglFlush;

if 0
%%%%%%%%%%%%%%%%%%%%%
% Make flicker
%%%%%%%%%%%%%%%%%%%%%
input('Hit ENTER to flicker: ');
nFlicker = 10;nFlush = 2;
for iFlicker = 1:nFlicker
  % draw the quads
  mglQuad(x,y,color);
  % flush
  for iFlush = 1:nFlush
    mglFlush;
  end
  keyboard
  % draw the quads
  mglQuad(x,y,inverseColor);
  % flush
  for iFlush = 1:nFlush
    mglFlush;
  end
end
end

%%%%%%%%%%%%%%%%%%%%%
% Test coord xform
%%%%%%%%%%%%%%%%%%%%%
input('Hit ENTER to test coordinate xform: ');
mgl.s = mglSocketWrite(mgl.s,uint16(mgl.command.xform));
xform = eye(4);
xform(:,4) = [-0.2 0.2 0 1];
mgl.s = mglSocketWrite(mgl.s,single(xform(:)));

mgl.s = mglSocketWrite(mgl.s,uint16(mgl.command.dots));
nVertices = 3;
mgl.s = mglSocketWrite(mgl.s,uint32(nVertices));
vertices = [0.0 0.5 0.0 -0.5 -0.5 0.0 0.5 -0.5 0.0];
mgl.s = mglSocketWrite(mgl.s,single(vertices));
mglFlush;

%%%%%%%%%%%%%%%%%%%%%
% Test texture
%%%%%%%%%%%%%%%%%%%%%
input('Hit ENTER to test texture: ');
mglClearScreen(0.5);mglFlush;mglFlush;
% send texture command
mgl.s = mglSocketWrite(mgl.s,uint16(mgl.command.texture));

% send three vertices with texture coordinates
verticesWithTextureCoordinates = [...
    -0.5   0.5 0 0 1;
     0.5   0.5 0 1 1;
     0.5  -0.5 0 1 0;
     0.5  -0.5 0 1 0;
    -0.5  -0.5 0 0 0;
    -0.5   0.5 0 0 1]';
nVertices = size(verticesWithTextureCoordinates,2);
mgl.s = mglSocketWrite(mgl.s,uint32(nVertices));
mgl.s = mglSocketWrite(mgl.s,single(verticesWithTextureCoordinates));

% create a texture
textureWidth = 256;
textureHeight = 256;
maxVal = 1.0;
sigma = 0.25;
[tx ty] = meshgrid(0:2*pi/(textureWidth-1):2*pi,0:2*pi/(textureHeight-1):2*pi);
[ex ey] = meshgrid(-1:2/(textureWidth-1):1,-1:2/(textureHeight-1):1);
clear texture;
texture(1,:,:) = maxVal*(cos(2*ty+pi/4)+1)/2;
texture(2,:,:) = maxVal*(cos(2*ty+pi/4)+1)/2;
texture(3,:,:) = maxVal*(cos(2*ty+pi/4)+1)/2;
texture(4,:,:) = maxVal*(exp(-((ex.^2+ey.^2)/sigma^2)));

% send the texture
mgl.s = mglSocketWrite(mgl.s,uint32(textureWidth));
mgl.s = mglSocketWrite(mgl.s,uint32(textureHeight));
mglSetParam('verbose',1);
mgl.s = mglSocketWrite(mgl.s,single(texture(:)));
mglSetParam('verbose',0);

% flush and wait
mglFlush;

%%%%%%%%%%%%%%%%%%%%%
% Test dots
%%%%%%%%%%%%%%%%%%%%%
input('Hit ENTER to test dots: ');
x = [0 -0.5 0.5];
y = [0.5 -0.5 -0.5];
mglPoints2(x,y,10,[1 1 1])

mglFlush;

input('Hit ENTER to test dots: ');
nVertices = 500;
deltaX = 0.005;
deltaR = 0.05;
nFrames = 500;
vertices = [];
r = 0.75*rand(1,nVertices);
theta = rand(1,nVertices)*2*pi;
x = cos(theta).*r;
y = sin(theta).*r;

for iFrame = 1:nFrames
  frameStart = mglGetSecs;
  mglPoints2(x,y,10,[1 1 1])
  mglFlush;
  r = r + deltaR;
  r(r>0.75) = deltaR*rand(1,sum(r>0.75));
  x = cos(theta).*r;
  y = sin(theta).*r;
  frameTime(iFrame) = mglGetSecs(frameStart);
end

expectedFrameTime = 1/60;
disp(sprintf('(testit) Median frame time: %0.4f',median(frameTime)));
disp(sprintf('(testit) Max frame time: %0.4f',max(frameTime)));
disp(sprintf('(testit) Number of frames over %0.4f: %i/%i',expectedFrameTime,sum(frameTime>expectedFrameTime),nFrames));
disp(sprintf('(testit) Number of frames 5%% over %0.4f: %i/%i',expectedFrameTime,sum(frameTime>(expectedFrameTime*1.05)),nFrames));
disp(sprintf('(testit) Number of frames 10%% over %0.4f: %i/%i',expectedFrameTime,sum(frameTime>(expectedFrameTime*1.1)),nFrames));
disp(sprintf('(testit) Number of frames 20%% over %0.4f: %i/%i',expectedFrameTime,sum(frameTime>(expectedFrameTime*1.2)),nFrames));




return


% make a texture as a PNG
textureWidth = 256;
textureHeight = 256;
maxVal = 1.0;
[tx ty] = meshgrid(0:2*pi/(textureWidth-1):2*pi,0:2*pi/(textureHeight-1):2*pi);
clear texture;
texture(:,:,1) = round(maxVal*(cos(2*tx+pi/4)+1)/2);
texture(:,:,2) = maxVal*(55/255);%round(255*(cos(2*tx+pi/4)+1)/2);
texture(:,:,3) = round(maxVal*(cos(2*tx+pi/4)+1)/2);
imwrite(texture,'texture.png','png');


%%%%%%%%%%%%%%%%%%
%    mglFlush    %
%%%%%%%%%%%%%%%%%%
function mglFlush

global mgl

% write
mgl.s = mglSocketWrite(mgl.s,uint16(mgl.command.flush));
[dataWaiting mgl.s] = mglSocketDataWaiting(mgl.s);
while ~dataWaiting, [dataWaiting mgl.s] = mglSocketDataWaiting(mgl.s);end
[val mgl.s] = mglSocketRead(mgl.s);

%%%%%%%%%%%%%%%%%
%    mglOpen    %
%%%%%%%%%%%%%%%%%
function mglOpen

global mgl

if isfield(mgl,'s') mglSocketClose(mgl.s); end
!rm -f testsocket
mgl.s = mglSocketOpen('testsocket');

%%%%%%%%%%%%%%%%%%%%%%%%
%    mglClearScreen    %
%%%%%%%%%%%%%%%%%%%%%%%%
function mglClearScreen(color)

global mgl

if length(color) == 1
  color = [color color color];
end
color = color(:);

mgl.s = mglSocketWrite(mgl.s,uint16(mgl.command.clearScreen));
mgl.s = mglSocketWrite(mgl.s,single(color));

%%%%%%%%%%%%%%%%%%%
%    mglLInes2    %
%%%%%%%%%%%%%%%%%%%
function mglLines2(x0, y0, x1, y1, size, color)

global mgl;

if length(color) == 1
  color = [color color color];
end
color = color(:);

% set up vertices
v = [];
for iLine = 1:length(x0)
  v(end+1:end+12) = [x0(iLine) y0(iLine) 1 color(:)' x1(iLine) y1(iLine) 1 color(:)'];
end

% send line command
mgl.s = mglSocketWrite(mgl.s,uint16(mgl.command.line));

% send vertices
mgl.s = mglSocketWrite(mgl.s,uint32(2*iLine));
mgl.s = mglSocketWrite(mgl.s,single(v));

%%%%%%%%%%%%%%%%%
%    mglQuad    %
%%%%%%%%%%%%%%%%%
function mglQuad(vX, vY, rgbColor)

global mgl;

% convert x and y into vertices
v = [];
for iQuad = 1:size(vX,1)
  
  % one triangle of the quad
  v(end+1:end+3) = [vX(iQuad,1) vY(iQuad,1) 0];
  v(end+1:end+3) = rgbColor(iQuad,:);
  v(end+1:end+3) = [vX(iQuad,2) vY(iQuad,2) 0];
  v(end+1:end+3) = rgbColor(iQuad,:);
  v(end+1:end+3) = [vX(iQuad,3) vY(iQuad,3) 0];
  v(end+1:end+3) = rgbColor(iQuad,:);

  % the other triangle of the quad
  v(end+1:end+3) = [vX(iQuad,3) vY(iQuad,3) 0];
  v(end+1:end+3) = rgbColor(iQuad,:);
  v(end+1:end+3) = [vX(iQuad,4) vY(iQuad,4) 0];
  v(end+1:end+3) = rgbColor(iQuad,:);
  v(end+1:end+3) = [vX(iQuad,1) vY(iQuad,1) 0];
  v(end+1:end+3) = rgbColor(iQuad,:);

end

% number of vertices
nVertices = length(v)/6;
disp(sprintf('(mglQuad) nVertices: %i len: %i',nVertices,length(v)));

% send them
mgl.s = mglSocketWrite(mgl.s,uint32(nVertices));
mgl.s = mglSocketWrite(mgl.s,single(v));


%%%%%%%%%%%%%%%%%%%%
%    mglPoints2    %
%%%%%%%%%%%%%%%%%%%%
function mglPoints2(x,y,size,color)

global mgl;

% create vertices
v = [x(:) y(:)];
v(:,3) = 0;
v = v';

% write dots command
mgl.s = mglSocketWrite(mgl.s,uint16(mgl.command.dots));
% send number of vertices
nVertices = length(x);
mgl.s = mglSocketWrite(mgl.s,uint32(nVertices));
% send vertices
mgl.s = mglSocketWrite(mgl.s,single(v(:)));
