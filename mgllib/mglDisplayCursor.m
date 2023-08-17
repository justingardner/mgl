% mglDisplayCursor.m
%
%        $Id$
%      usage: mglDisplayCursor()
%         by: Justin Gardner
%       date: 02/10/07
%  copyright: (c) 2007 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: display/hide cursor, note that the cursor will be hidden/unhidden only
%             when the focus is on the mglMetal app
%      usage: mglDisplayCursor(0) hide cursor
%             mglDisplayCursor(1) display cursor
%       e.g.: 
%
%mglOpen();
%mglDisplayCursor(1);
function [ackTime, processedTime] = mglDisplayCursor(dispCursor)

% default values for return variables
ackTime = [];
processedTime = [];

% get socket
global mgl;
socketInfo = mgl.activeSockets;

% send line command
mglSocketWrite(socketInfo, socketInfo(1).command.mglDisplayCursor);
ackTime = mglSocketRead(socketInfo, 'double');

% if restore is set, then send 1, otherwise send 0
if (nargin == 0) || ~isequal(dispCursor,0)
  mglSocketWrite(socketInfo(1), uint32(1));
else
  mglSocketWrite(socketInfo(1), uint32(0));
end
  
% get processed time
processedTime = mglSocketRead(socketInfo, 'double');
