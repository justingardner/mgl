% mglNoFlushWait.m
%
%        $Id:$ 
%      usage: mglNoFlushWait()
%         by: justin gardner
%       date: 01/20/2013
%    purpose: This just waits for the amount of time a frame update should take but does
%             not actually flush the screen. Made to be used instead of mglFlush. When you
%             want to time like you are flushing the screen but don't actually want to flush.
%             This is useful for the movie mode. 
%
% 
%
function retval = mglNoFlushWait()

% check arguments
if ~any(nargin == [0])
  help mglFlushAndWait
  return
end

% get the last flush time
lastFlushTime = mglGetParam('lastFlushTime');

% get how long the refresh should take
frameRate = mglGetParam('frameRate');
if isempty(frameRate)
  disp(sprintf('(mglFlushAndWait) No framerate set. Need to have an open screen'));
  return
end
frameTime = 1/frameRate;

% wait for however long it should have taken
mglWaitSecs(frameTime-mglGetSecs(lastFlushTime));

% reset the last flush time
mglSetParam('lastFlushTime',mglGetSecs);
