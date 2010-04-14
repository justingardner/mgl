function [task myscreen] = mglEyelinkCallbackNextTask(task, myscreen)
% mglEyelinkCallbackNextTask 
%
% Usage: mglEyelinkCallbackNextTask
%   IP - the ip address of the eyelink eye tracker, defaults to 100.1.1.1
%   conntype - the connection type: 0 opens a direct link, 1 initializes a
%              dummy connection

%     program: mglEyelinkCallbackNextTask.m
%          by: eric dewitt
%        date: 04/03/06
%  copyright: (c) 2009,2006 Eric DeWitt, Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%     purpose: open a link connection to an SR Research Eylink
%
    
    
if isfield(task, 'collectEyeData')
  mglEyelinkEDFPrintF('MGL NEXT PHASE');
        
  if (~task.collectEyeData) && (~mglEyelinkRecordingCheck())
    % if we are recording, stop
    mglEyelinkRecordingStop();
  end
end
    
