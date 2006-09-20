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

if (strcmp(lower(computer),'mac'))
  % change the gamma of the monitor
  gamma = mglGetGammaTable;
  mglSetGammaTable([0 1 1.7 0 1 1.7 0 1 1.7]);
end

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

% get size in pixels
texWidthPixels = round(texWidth*MGL.xDeviceToPixels);
texHeightPixels = round(texHeight*MGL.yDeviceToPixels);

% get a grid of x and y coordinates that has 
% the correct number of pixels
x = -texWidth/2:texWidth/(texWidthPixels-1):texWidth/2;
y = -texHeight/2:texHeight/(texHeightPixels-1):texHeight/2;
[xMesh,yMesh] = meshgrid(x,y);

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
  % calculate image parameters
  phase = i*2*pi/nsteps;
  angle = pi*55/180;
  f=0.8*2*pi; 
  a=cos(angle)*f;
  b=sin(angle)*f;
  % compute grating
  m = sin(a*xMesh+b*yMesh+phase);
  % compute gaussian window
  win = exp(-((xMesh.^2)/((texWidth/5)^2)+(yMesh.^2)/((texHeight/5)^2)));
  win=win./max(max(win));
  % clamp small values to 0 so that we fade completely to gray.
  win(win(:)<0.01) = 0;
  % now create and RGB + alpha image with the gaussian window
  % as the alpha channel
  if (strcmp(lower(computer),'mac'))
    m = 255*(m+1)/2;
    m4(:,:,1) = m;
    m4(:,:,2) = m;
    m4(:,:,3) = m;
    m4(:,:,4) = 255*win;
  else
    m=m*128;
    m4(:,:,1) = m.*win+127;
    m4(:,:,2) = m.*win+127;
    m4(:,:,3) = m.*win+127;    
  end
  % now create the texture
  tex(i) = mglCreateTexture(m4);
end

% display each texture to back buffer, to make sure
% everything is cached properly
for i = 1:nsteps
  mglBltTexture(tex(i),[0 0]);
end

% this is the main display loop
numsec = 5;
starttime = mglGetSecs;
for i = 1:MGL.frameRate*numsec
  % calculate next phase step to display
  thisPhase = mod(i,nsteps)+1;
  % clear the screen
  mglClearScreen;
  % and display the gabor patch
  mglBltTexture(tex(thisPhase),[0 0]);
  % flush buffers
  mglFlush;
end  
endtime = mglGetSecs;

if (strcmp(lower(computer),'mac'))
  % reset gamma and close screen
  mglSetGammaTable(gamma.redTable,gamma.greenTable,gamma.blueTable);
end
mglClose;

% check how long it ran for
disp(sprintf('Ran for: %0.8f sec Intended: %0.8f sec',endtime-starttime,numsec));
disp(sprintf('Difference from intended: %0.8f ms',1000*((endtime-starttime)-numsec)));
disp(sprintf('Number of frames lost: %i/%i (%0.2f%%)',round(((endtime-starttime)-numsec)*MGL.frameRate),numsec*MGL.frameRate,100*(((endtime-starttime)-numsec)*MGL.frameRate)/(MGL.frameRate*numsec)));



