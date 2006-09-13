% mglTestLUTAnimation.m
%
%        $Id$
%      usage: mglTestLUTAnimation(screenNumber)
%         by: justin gardner
%       date: 05/27/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: do a LUT animation using gammaTables
%
function retval = mglTestLUTAnimation(screenNumber)

% check arguments
if ~any(nargin == [0 1])
  help mglTestLUTAnimation
  return
end

if ~exist('screenNumber','var'), screenNumber = [];,end

% open the screen
mglOpen(screenNumber);
mglScreenCoordinates;

% get the current gammaTable
gammaTable = mglGetGammaTable;

% get global variable
global MGL;

% make a whole screen grating
[xMesh yMesh] = meshgrid(1:MGL.screenWidth,1:MGL.screenHeight);
ang = 75/180*pi;
f = 0.03*2*pi;
a=cos(ang)*f;
b=sin(ang)*f;
phase = 0;
% grating will have phase of each point as values from 0 to 255
grating = round(255*mod((a*xMesh + b*yMesh+phase),2*pi)/(2*pi));

% make the texture from the grating
gratingTexture = mglCreateTexture(grating);

% set the gamma table so nothing is visible
mglSetGammaTable(0,0,1,0,0,1,0,0,1);

% blt the textures to both front and back buffers
mglBltTexture(gratingTexture,[0 0],-1,-1);mglFlush;
mglBltTexture(gratingTexture,[0 0],-1,-1);mglFlush;

numsec = 5;
starttime = GetSecs;
% now do the animation
for i = 1:MGL.frameRate*numsec
  % now create a lut that looks into the gamma tables to
  % set the phase values in the bitmap to a sine wave grating
  % first get the phase values for this frame
  phaseValues = circshift((1:255)',4*round(255*(i/MGL.frameRate)))';
  % convert those phase values into intensity values
  intensityValues = sin(2*pi*phaseValues/255);
  % convert these into values that can reference the LUT
  lutValues = ceil(255*(intensityValues+1)/2+1);
  % now set the gamma table
  mglSetGammaTable(gammaTable.redTable(lutValues),gammaTable.greenTable(lutValues),gammaTable.blueTable(lutValues));
  % wait for a frame refresh
  mglFlush;
end
endtime = GetSecs;

% clear the screen, reset gammaTable and close
mglClearScreen;mglFlush;
mglSetGammaTable(gammaTable.redTable,gammaTable.greenTable,gammaTable.blueTable);
mglClose;

% check how long it ran for
disp(sprintf('Ran for: %0.8f sec Intended: %0.8f sec',endtime-starttime,numsec));
disp(sprintf('Difference from intended: %0.8f ms',1000*((endtime-starttime)-numsec)));
disp(sprintf('Number of frames lost: %i/%i (%0.2f%%)',round(((endtime-starttime)-numsec)*MGL.frameRate),numsec*MGL.frameRate,100*(((endtime-starttime)-numsec)*MGL.frameRate)/(MGL.frameRate*numsec)));
