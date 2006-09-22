% mglWaitSecs.m
%
%        $Id$
%      usage: mglWaitSecs()
%         by: justin gardner
%       date: 09/22/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Wait for a certain time
%       e.g.:
%mglWaitSecs(1);
%
function mglWaitSecs(waitTime)

% check arguments
if ~any(nargin == [1])
  help mglWaitSecs
  return
end

startTime = mglGetSecs;
while (mglGetSecs(startTime) < waitTime),end

