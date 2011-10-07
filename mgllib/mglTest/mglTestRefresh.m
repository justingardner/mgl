% mglTestRefresh.m
%
%        $Id:$ 
%      usage: mglTestRefresh()
%         by: justin gardner
%       date: 10/06/11
%    purpose: 
%
function retval = mglTestRefresh(screenNum)

% check arguments
if ~any(nargin == [0 1])
  help mglTestRefresh
  return
end

if nargin == 0, screenNum = [];end
mglOpen(screenNum);

% set test length to 5 seconds
testLen = 5;
disp(sprintf('(mglTestRefresh) Testing refresh rate for %0.1f secs',testLen));

% checking refresh rate
startTime = mglGetSecs;
numRefresh = 0;
while(mglGetSecs(startTime) < testLen)
  mglFlush;
  numRefresh = numRefresh+1;
end

disp(sprintf('(mglTestRefresh) Refresh rate: %f Hz',numRefresh/testLen));
mglClose;


