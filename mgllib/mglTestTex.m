% mglTestTex.m
%
%        $Id$
%      usage: mglTestTex(screenNum)
%         by: justin gardner
%       date: 04/11/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: 
%
function retval = mglTestTex(screenNumber)

% get MGL global
global MGL;

% check arguments
if ~any(nargin == [0 1])
  help mglTestTex
  return
end

% check for screenNum
if exist('screenNumber')~=1,screenNumber = [];,end

% open up mgl window
mglOpen(screenNumber);
mglVisualAngleCoordinates(57,[40 30]);

% clear both buffers to gray
mglClearScreen(0.5);mglFlush;
mglClearScreen;mglFlush;

if (strcmp(lower(computer),'mac'))
  % display wait text
  mglTextSet('Helvetica',32,[1 1 1],0,0,0,0,0,0,0);
  mglTextDraw('Calculating textures (0% done)',[0 0]);mglFlush;
else
  mglStrokeText('Calculating textures (0 percent done)',-8,0,0.5,0.8,2);mglFlush;
end

% size of textures in degrees
texWidth = 10;
texHeight = 10;

% now create each image with a different phase (use nsteps of phase)
nsteps = 30;
for i = 1:nsteps;
  % display percent done
  mglClearScreen;
  if (strcmp(lower(computer),'mac'))
    mglTextDraw(sprintf('Calculating textures (%0.0f%% done)',99*i/nsteps),[0 0]);
  else
    msg=sprintf('Calculating textures (%i percent done)',round(99*i/nsteps));
    mglStrokeText(msg,-8,0,0.5,0.8,2);
  end
  mglFlush;
  % calculate grating and gaussian window
  m = makeSquareGrating(texWidth,texHeight,0.8,0,i*360/nsteps);
  win = makeGaussian(texWidth,texHeight,texWidth/7,texHeight/7);
  % now create and RGB + alpha image with the gaussian window
  % as the alpha channel
  if (strcmp(lower(computer),'mac'))
    m = 255*(m+1)/2;
    m4(:,:,1) = m;
    m4(:,:,2) = m;
    m4(:,:,3) = m;
    m4(:,:,4) = 255*win;
  % on linux, if we don't have alpha channel then explicitly
  % make the gabor, then the texture will be a simple grayscale one
  else
    m4=m*128.*win+127;
  end
  % now create the texture
  tex(i) = mglCreateTexture(m4);
end

% display each texture to back buffer, to make sure
% everything is cached properly
for i = 1:nsteps
  mglBltTexture(tex(i),[0 0]);
end

% calculate tex positions, making sure they are offset
% from each other by atleast 1/2 height and width
texPos = [-1 1;1 1;1 -1;-1 -1];
texPos(:,1) = texPos(:,1)*(texWidth/2+2);
texPos(:,2) = texPos(:,2)*(texHeight/2+2);

% this is the main display loop
numsec = 5;
starttime = mglGetSecs;
for i = 1:MGL.frameRate*numsec
  % calculate next phase step to display
  thisPhase = mod(i,nsteps)+1;
  thisPhase2 = mod(nsteps-i,nsteps)+1;
  % clear the screen
  mglClearScreen;
  %startBlt = mglGetSecs;
  % and display four gabor patches
  mglBltTexture(tex([thisPhase thisPhase2 thisPhase thisPhase2]),texPos,0,0,[0 45 90 135]);
  % and the rotating one at the center
  mglBltTexture(tex(1),[0 0],0,0,360*i/(MGL.frameRate*numsec));
  %disp(sprintf('mglBltTexture: %f',(mglGetSecs-startBlt)*1000));
  % flush buffers
  mglFlush;
end  
endtime = mglGetSecs;

% close the screen
mglClose;

% check how long it ran for
disp(sprintf('Ran for: %0.8f sec Intended: %0.8f sec',endtime-starttime,numsec));
disp(sprintf('Difference from intended: %0.8f ms',1000*((endtime-starttime)-numsec)));
disp(sprintf('Number of frames lost: %i/%i (%0.2f%%)',round(((endtime-starttime)-numsec)*MGL.frameRate),numsec*MGL.frameRate,100*(((endtime-starttime)-numsec)*MGL.frameRate)/(MGL.frameRate*numsec)));



