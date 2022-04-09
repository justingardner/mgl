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

% get start time
startTime = mglGetSecs;

% check keys
keyEvent = [];
while(isempty(keyEvent) && (mglGetSecs(startTime)<waitTime))
  keyEvent = mglGetKeyEvent;
end

% check for ESC
if ~isempty(keyEvent)
  if keyEvent.keyCode == 54
    disp(sprintf('(mglPause) Breaking out of pause. Type dbcont to continue, dbquit to end'));
    keyboard
  end
end



