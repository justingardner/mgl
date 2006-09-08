% mglTestAlignment.m
%
%      usage: mglTestAlignment(screenNumber)
%         by: justin gardner
%       date: 09/05/06
%    purpose: 
%
function retval = mglTestAlignment(screenNumber,noClose)

% check arguments
if ~any(nargin == [0 1 2])
  help mglTestAlignment
  return
end

% check for screenNum
if ~exist('screenNumber','var'),screenNumber = [];,end
if ~exist('noClose','var'),noClose = 0;,end

global MGL;

% open up mgl window
mglTextSet('Helvetica',32,[1 1 1],0,0,0,0,0,0,0);
mglOpen(screenNumber);
mglVisualAngleCoordinates(57,[16 12]);
mglClearScreen;
mglTextDraw('Visual angle coordinates',[0 1]);
drawAlignment(12,8,[0 0]);
if noClose
  input('Press enter to continue: ');
else
  pause(5);
end
mglClose;

% open up mgl window
mglOpen(screenNumber);
mglScreenCoordinates;
mglClearScreen;
mglTextDraw('Screen coordinates',[MGL.deviceWidth/2 5*MGL.deviceHeight/8]);
drawAlignment(3*MGL.deviceWidth/4,3*MGL.deviceHeight/4,[MGL.deviceWidth/2 MGL.deviceHeight/2]);

% auto close the screen after two seconds
if ~noClose
  pause(5);
  mglClose;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function to draw the alignment screen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function drawAlignment(width,height,center)

% get MGL global
global MGL;

width = width/2;height = height/2;

% create a random texture
texWidth = width/8; texHeight = height/4;
tex = mglCreateTexture(rand(round(texWidth*MGL.xDeviceToPixels),round(texHeight*MGL.yDeviceToPixels))*255,'xy');

% display texture on alignment points
mglBltTexture(tex,center,0,0);

if (MGL.deviceVDirection > 0)
  mglBltTexture(tex,[-width -height]+center,-1,1);
  mglBltTexture(tex,[width height]+center,1,-1);
  mglBltTexture(tex,[-width height]+center,-1,-1);
  mglBltTexture(tex,[width -height]+center,1,1);
else
  mglBltTexture(tex,[-width -height]+center,-1,-1);
  mglBltTexture(tex,[width height]+center,1,1);
  mglBltTexture(tex,[-width height]+center,-1,1);
  mglBltTexture(tex,[width -height]+center,1,-1);
end  

% plot alignment points
pointSize = 10;
mglPoints2(-width+center(1),center(2),pointSize,[1 1 0]);
mglPoints2(center(1),center(2),pointSize,[1 1 0]);
mglPoints2(width+center(1),center(2),pointSize,[1 1 0]);

mglPoints2(-width+center(1),-height+center(2),pointSize,[1 1 0]);
mglPoints2(center(1),-height+center(2),pointSize,[1 1 0]);
mglPoints2(width+center(1),-height+center(2),pointSize,[1 1 0]);

mglPoints2(-width+center(1),height+center(2),pointSize,[1 1 0]);
mglPoints2(center(1),height+center(2),pointSize,[1 1 0]);
mglPoints2(width+center(1),height+center(2),pointSize,[1 1 0]);

% draw some text to test text alignment
overhangText = mglText('aligned with this text');
noOverhangText = mglText('this text should be--');
mglBltTexture(overhangText',[center(1) center(2)-width/2],-1,0);
mglBltTexture(noOverhangText',[center(1) center(2)-width/2],1,0);
if (MGL.deviceVDirection > 0)
  mglBltTexture(overhangText',[center(1) center(2)-width/2+overhangText.imageHeight*MGL.yPixelsToDevice],-1,1);
  mglBltTexture(noOverhangText',[center(1) center(2)-width/2+noOverhangText.imageHeight*MGL.yPixelsToDevice],1,1);

  mglBltTexture(overhangText',[center(1) center(2)-width/2-overhangText.imageHeight*MGL.yPixelsToDevice],-1,-1);
  mglBltTexture(noOverhangText',[center(1) center(2)-width/2-noOverhangText.imageHeight*MGL.yPixelsToDevice],1,-1);
else 
  mglBltTexture(overhangText',[center(1) center(2)-width/2+overhangText.imageHeight*MGL.yPixelsToDevice],-1,-1);
  mglBltTexture(noOverhangText',[center(1) center(2)-width/2+noOverhangText.imageHeight*MGL.yPixelsToDevice],1,-1);

  mglBltTexture(overhangText',[center(1) center(2)-width/2-overhangText.imageHeight*MGL.yPixelsToDevice],-1,1);
  mglBltTexture(noOverhangText',[center(1) center(2)-width/2-noOverhangText.imageHeight*MGL.yPixelsToDevice],1,1);
end
% flush screen
mglFlush;

