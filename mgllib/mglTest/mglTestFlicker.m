% mglTestFlicker.m
%
%        $Id:$ 
%      usage: mglTestFlicker(<freq=refreshRate/2>,<screenNumber=[]>)
%         by: justin gardner
%       date: 09/09/10
%    purpose: With no arguments, flickers the screen at maximum rate possible (i.e. refreshRate/2).
%
function retval = mglTestFlicker(varargin)

% check arguments
if ~any(nargin == [0 1 2 3 4 ])
  help mglTestFlicker
  return
end

freq = [];screenNumber = [];
getArgs(varargin,{'freq=[]','screenNumber=[]'});

% get the frame time
mglOpen(screenNumber);
frameTime = 1/mglGetParam('frameRate');

% handle specification of frequency
if isempty(freq)
  waitFrames = 1;
else
  waitFrames = round((1/freq)/frameTime);
end

% display settings
disp(sprintf('(mglTestFlicker) Testing frequency %f: %i frames',1/(waitFrames*frameTime),waitFrames));
disp(sprintf('(mglTestFlicker) Hit any key to end'));

% clear keyboard buffer
mglGetKeyEvent(0,1);

% init variables
currentColor= 1;
mglClearScreen(currentColor);
mglFlush;

% flicker screen
while isempty(mglGetKeyEvent)
  for i = 1:waitFrames
    mglClearScreen(double(currentColor));
    mglFlush;
  end
  currentColor = ~currentColor;
end
mglClose;

