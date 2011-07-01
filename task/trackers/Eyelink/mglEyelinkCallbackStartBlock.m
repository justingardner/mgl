function [task myscreen] = mglEyelinkCallbackStartBlock(task, myscreen)
% mglEyelinkCallbackStartBlock - Assigns eye position to myscreen
%
% Usage: mglEyelinkCallbackStartBlock(task, myscreen)

%     program: mglEyelinkCallbackStartBlock.m
%          by: eric dewitt
%        date: 04/03/06
%  copyright: (c) 2009,2006 Eric DeWitt, Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%     purpose: open a link connection to an SR Research Eylink
%
    
if task.collectEyeData
  if all(eq(task.collectEyeData, 'block')) && (~mglEyelinkRecordingCheck)
    % if we are recording & we want to reset at blocks, stop
    mglEyelinkRecordingStop();
  end
  mglEyelinkRecordingStart(myscreen.eyetracker.data);
  mglEyelinkEDFPrintF('MGL BEGIN BLOCK %i', task.blocknum);
end

