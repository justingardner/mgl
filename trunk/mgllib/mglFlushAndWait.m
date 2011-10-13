% mglFlushAndWait.m
%
%        $Id:$ 
%      usage: mglFlushAndWait()
%         by: justin gardner
%       date: 10/13/11
%    purpose: Normally mglFlush waits till the vertical blank and so you will only refresh once
%             every video frame. But with some video cards, notably ATI Radeon HD 5xxx series, 
%             this is broken. This function is like mglFlush but will use mglWaitSecs to wait
%             the appropriate amount of time after an mglFlush. See here for more info
%
% http://gru.brain.riken.jp/doku.php/mgl/knownIssues#vertical_blanking_using_ati_videocards_radeon_hd
%
function retval = mglFlushAndWait()

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

% flush the screen
mglFlush;

% wait for however long it should have taken
mglWaitSecs(frameTime-mglGetSecs(lastFlushTime));

% reset the last flush time
mglSetParam('lastFlushTime',mglGetSecs);
