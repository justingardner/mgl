% mglMinimize.m
%
%      usage: mglMinimize()
%         by: justin gardner
%       date: 08/11/2023
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: minimize the mglMetal window
%      usage: mglMinimize 
%             To restore: mglMinimze(1);
%
% mglOpen;
% mglMinimize;
% 
function [ackTime, processedTime] = mglMinimize(restore)

% default values for return variables
ackTime = [];
processedTime = [];

% get socket
global mgl;
socketInfo = mgl.activeSockets;

% send line command
mglSocketWrite(socketInfo, socketInfo(1).command.mglMinimize);
ackTime = mglSocketRead(socketInfo, 'double');

% if restore is set, then send 1, otherwise send 0
if (nargin == 0) || ~isequal(restore,1)
  mglSocketWrite(socketInfo(1), uint32(0));
else
  mglSocketWrite(socketInfo(1), uint32(1));
end
  
% get processed time
processedTime = mglSocketRead(socketInfo, 'double');
