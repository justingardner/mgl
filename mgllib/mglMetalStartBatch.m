% mglMetalStartBatch: start queueing up Metal commands to process later.
%
%      usage: ackTime = mglMetalStartBatch()
%         by: ben heasly
%       date: 01/12/2024
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Put the Mgl Metal app into its batch "building" state.
%      usage: ackTime = mglMetalStartBatch()
%
%             Returns:
%               - ackTime, a timestamp confirming the state change
%
%             In batch "building" state, the MglMetal is focused on
%             communicating with Matlab but not command processing or
%             rendering. Commands sent to the app will be fully read, then
%             saved in a queue for later processing.  For each command, the
%             client will get an immediate placeholder reponse, so that it
%             doesn't block waiting for the real response.  Real responses
%             will be sent back all at once at the end of the batch, after
%             mglMetalProcessBatch() and mglMetalFinishBatch().
%
%             % Here's a command batch example.
%             mglOpen();
%             mglMetalStartBatch();
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
%             mglMetalProcessBatch();
%
%             % Potentially do other things while the batch is going.
%             disp('A batch is running asynchronously!')
%
%             % Wait for the batch to finish.
%             % This should give us 6 results, one for each queued command.
%             results = mglMetalFinishBatch()
%
%             mglClose();
function ackTime = mglMetalStartBatch(socketInfo)

global mgl
if nargin < 1 || isempty(socketInfo)
    socketInfo = mgl.activeSockets;
end

mglSocketWrite(socketInfo, socketInfo(1).command.mglStartBatch);
ackTime = mglSocketRead(socketInfo, 'double');
