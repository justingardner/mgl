% mglGetSecs: Get current or elapsed time
%
%        $Id$
%     Syntax: mglGetSecs([t])
%         By: Jonas Larsson
%       Date: 04/10/06
%    Purpose: Timing events
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%      Usage: Get current time in s 
%             t=mglGetSecs
% 
%             Get elapsed time since t0
%             t=mglGetSecs(t0)
%
%
function secs = mglGetSecs()

global mgl

mgl.s = mglSocketWrite(mgl.s,uint16(mgl.command.getSecs));

% Wait for a return value.
[dataWaiting, mgl.s] = mglSocketDataWaiting(mgl.s);
while ~dataWaiting
    [dataWaiting, mgl.s] = mglSocketDataWaiting(mgl.s);
end

% Read out the return value.
[secs, mgl.s] = mglSocketRead(mgl.s);
