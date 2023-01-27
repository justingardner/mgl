% mglFLush: Commit a frame of drawing commands and wait for the next frame.
%
%      usage: [ackTime, processedTime] = mglFlush(socketInfo)
%         by: justin gardner
%       date: 09/27/2021
%  copyright: (c) 2021 Justin Gardner (GPL see mgl/COPYING)
%    purpose: Commit recent drawing commands and wait for the next frame.
%      usage: waitTime = mglFlush();
%       e.g.: mglOpen;
%             mglClearScreen([1 0 0]);
%             mglFlush;
%             mglClearScreen([0 1 0]);
%             mglFlush;
function [ackTime, processedTime] = mglFlush(socketInfo)

if nargin < 1 || isempty(socketInfo)
    global mgl
    socketInfo = mgl.activeSockets;
end

% write flush comnand and wait for return value.
mglSocketWrite(socketInfo, socketInfo(1).command.mglFlush);
ackTime = mglSocketRead(socketInfo, 'double');
processedTime = mglSocketRead(socketInfo, 'double');

% check if processedTime is negative which indicates an error
if processedTime < 0
  % display error
  mglPrivateDisplayProcessingError(socketInfo, ackTime, processedTime, mfilename);
end



