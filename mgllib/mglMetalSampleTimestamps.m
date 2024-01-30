% mglMetalSampleTimestamps.m
%
%      usage: [cpu, gpu, results] = mglMetalSampleTimestamps(socketInfo)
%         by: Benjamin Heasly
%       date: 01/30/2024
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Get a CPU-GPU timestamp pair from the same moment.
%
%             Returns:
%               cpu: a CPU timestamp in seconds, comparable to mglGetSecs
%               gpu: a GPU timestamp in unspecified units (GPU nanos?)
%
%             % Get some samples!
%             mglOpen();
%             [cpu, gpu] = mglMetalSampleTimestamps()
function [cpu, gpu, results] = mglMetalSampleTimestamps(socketInfo)

global mgl
if nargin < 1 || isempty(socketInfo)
    socketInfo = mgl.activeSockets;
end

% Request a timestamp pair.
mglSocketWrite(socketInfo, socketInfo(1).command.mglSampleTimestamps);
ackTime = mglSocketRead(socketInfo, 'double');
cpu = mglSocketRead(socketInfo, 'double');
gpu = mglSocketRead(socketInfo, 'double');
results = mglReadCommandResults(socketInfo, ackTime);
