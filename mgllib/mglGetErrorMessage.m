% mglGetErrorMessage.m
%
%      usage: msg = mglGetErrorMessage()
%         by: justin gardner
%       date: 01/26/23
%    purpose: Gets an error message from the mglMetal app
%
function [msg, results] = mglGetErrorMessage(socketInfo)

if nargin < 1 || isempty(socketInfo)
    global mgl
    socketInfo = mgl.activeSockets;
end

% write command
mglSocketWrite(socketInfo, socketInfo(1).command.mglGetErrorMessage);
ackTime = mglSocketRead(socketInfo, 'double');

% wait till there is data
while ~mglSocketDataWaiting(socketInfo),end

% read the error message
msg = mglSocketReadString(socketInfo);

% get the processed Time
results = mglReadCommandResults(socketInfo, ackTime);
if any([results.processedTime] < 0)
  disp(sprintf('(mglGetErrorMessage) Error processing command.'));
end
