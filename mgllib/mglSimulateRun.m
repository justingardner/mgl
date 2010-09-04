% mglSimulateRun.m
%
%        $Id: mglOpen.m 385 2009-01-03 20:34:37Z justin $
%      usage: mglSimulateRun(framePeriod,numFrames,<startDelay>,<char>)
%         by: justin gardner
%       date: 01/10/09
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: This function simulates a run (currently only available on Mac)
%             it does this by posting periodic backtick keypresses using
%             mglPostEvent. For example if you want to have 375 backticks
%             occur spaced 1.5 seconds apart:
%
%             mglSimulateRun(1.5,375);
% 
%             Also, you can delay the start of the backticks, by doing
%
%             mglSimulateRun(1.5,375,10);
% 
%             Instead of sending the backtick character, send the character 'a'
%            
%             mglSimulateRun(1.5,375,0,'a');
%
%             Note that if you want to stop the keyboard events in the middle,
%             you need to do OR press the ESC key.
%
%             mglPostEvent('quit');
%
function mglSimulateRun(framePeriod,numFrames,startDelay,char)

% check arguments
if ~any(nargin == [2 3 4])
  help mglSimulateRun;
  return
end

if ieNotDefined('startDelay'),startDelay = 0;end
if ieNotDefined('char'),char = '`';end

startTime = mglGetSecs+startDelay;
for i = 1:numFrames
  mglPostEvent('keypress',startTime+i*framePeriod,char);
end
