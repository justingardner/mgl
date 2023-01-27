% mglPrivateDisplayProcessingError.m
%
%        $Id:$ 
%      usage: mglPrivateDisplayProcessingError(socketInfo, ackTime, processedTime, functionName)
%         by: justin gardner
%       date: 01/27/23
%    purpose: Private function that is used to handle errors that mglMetal returns
%             when processing a command. These are signaled by a negative processedTime
%             In this code, the error message is retrieved by querying mglMetal
%             and displayed.
%
function retval =   mglPrivateDisplayProcessingError(socketInfo, ackTime, processedTime, functionName)

% check arguments
if ~any(nargin == [4])
  help mglPrivateDisplayProcessingError
  return
end

% get error message from mglMetal and display
msg = mglGetErrorMessage(socketInfo);
disp(sprintf('mglMetal: %s',msg));

% display error message from the command that failed (i.e. the one calling this function)
disp(sprintf('(%s) mglMetal application reported error: took %0.3fs to process',functionName,-processedTime-ackTime));

