% mglMetalFinishBatch: await results from a completed command batch.
%
%      usage: [results, batchInfo]= mglMetalFinishBatch(batchInfo)
%         by: ben heasly
%       date: 01/12/2024
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Returns the Mgl Metal to its normal state
%      usage: [results, batchInfo]= mglMetalFinishBatch(batchInfo)
%
%             Inputs:
%               - batchInfo - a struct of batch info and timestamps, as
%                             from mglMetalStartBatch()
%
%             Returns:
%               - results - an array of timing results with one element per
%                          command in the processed batch
%               - batchInfo - the given struct with a processing finish
%                             timestamp
%
%             After processing a command batch, following
%             mglMetalStartBatch() and mglMetalProcessBatch(), the Mgl
%             Metal app will send back a number indicating the number of
%             command reponses that are waiting.  Use this function to
%             wait for that number and retrieve the pending responses.
%
%             % Here's a command batch example.
%             mglOpen();
%             batchInfo = mglMetalStartBatch();
%
%             % Queue up three frames, each with a different clear color.
%             % This part is all communication and no processing.
%             mglClearScreen([1 0 0]);
%             mglFlush();
%             mglClearScreen([0 1 0]);
%             mglFlush();
%             mglClearScreen([0 0 1]);
%             mglFlush();
%
%             % Let the Mgl Metal app process the batch as fast as if can.
%             % This part is all processing and no communication.
%             batchInfo = mglMetalProcessBatch(batchInfo);
%
%             % Potentially do other things while the batch is going.
%             disp('A batch is running asynchronously!')
%
%             % Wait for the batch to finish.
%             % This should give us 6 results, one for each queued command.
%             % Passing in batchInfo converts GPU timestamps to CPU time.
%             results = mglMetalFinishBatch(batchInfo)
%
%             mglClose();
function [results, batchInfo] = mglMetalFinishBatch(batchInfo, socketInfo)

global mgl
if nargin < 2 || isempty(socketInfo)
    socketInfo = mgl.activeSockets;
end

% Await the signal that asynchronous batch processing is complete.
commandCount = mglSocketRead(socketInfo, 'uint32');

% Request all the command results.
mglSocketWrite(socketInfo, socketInfo(1).command.mglFinishBatch);
batchInfo.finishAckTime = mglSocketRead(socketInfo, 'double');
results = mglReadCommandResults(socketInfo, [], [], commandCount);

% Convert GPU timestamp results to CPU time.
if isfield(batchInfo, 'cpuBefore') && isfield(batchInfo, 'gpuBefore')
    [cpuAfter, gpuAfter] = mglMetalSampleTimestamps(socketInfo);
    batchInfo.cpuAfter = cpuAfter;
    batchInfo.gpuAfter = gpuAfter;
    results = mglConvertCommandResults( ...
        results, ...
        batchInfo.cpuBefore, ...
        batchInfo.gpuBefore, ...
        batchInfo.cpuAfter, ...
        batchInfo.gpuAfter);
end
