% mglMetalProcessBatch: start processing Metal commands enqueued earlier.
%
%      usage: batchInfo = mglMetalProcessBatch(batchInfo)
%         by: ben heasly
%       date: 01/12/2024
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Put the Mgl Metal app into its batch "processing" state.
%      usage: batchInfo = mglMetalProcessBatch(batchInfo)
%
%             Inputs:
%               - batchInfo - a struct of batch info and timestamps, as
%                             from mglMetalStartBatch()
%
%             Returns:
%               - batchInfo - the given struct with a processing start
%                             timestamp
%
%             In batch "processing" state, the MglMetal is focused on
%             command processing and rendering but not communicating with
%             Matlab. Commands that were queued up previously, following
%             mglMetalStartBatch(), will be processed as fast as the app is
%             able to.  Command responses will be queued up in the same
%             order, to be returned later via mglMetalFinishBatch().
%
%             During batch processing, the Mgl Metal app will operate
%             asynchronously -- it's possible to do other things in Matlab
%             at the same time.
%
%             When batch processing is complete the Mgl Metal app will
%             send back a number indicating how many command reponses are
%             waiting.  Use mglMetalFinishBatch() to wait for this number
%             and retrieve the pending responses.
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
function batchInfo = mglMetalProcessBatch(batchInfo, socketInfo)

global mgl
if nargin < 2 || isempty(socketInfo)
    socketInfo = mgl.activeSockets;
end

mglSocketWrite(socketInfo, socketInfo(1).command.mglProcessBatch);
batchInfo.processAckTime = mglSocketRead(socketInfo, 'double');
