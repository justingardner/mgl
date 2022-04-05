% mglPause.m
%
%      usage: mglPause()
%         by: justin gardner
%       date: 04/05/22
%    purpose: pause that checks the keyboard w/out focus
%
function retval = mglPause(waitTime)

% check arguments
if ~any(nargin == [0 1])
  help mglPause
  return
end

if nargin < 1,waitTime = inf;end

startTime = mglGetSecs;

while(isempty(mglGetKeyEvent) && (mglGetSecs(startTime)<waitTime))
end


