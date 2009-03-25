function [task myscreen] = mglEyelinkCallbackTrialStart(task, myscreen)
% mglEyelinkCallbackTrialStart - 
%
% Usage: mglEyelinkCallbackTrialStart(task, myscreen)

%     program: mglEyelinkCallbackTrialStart.m
%          by: eric dewitt
%        date: 04/03/06
%  copyright: (c) 2009,2006 Eric DeWitt, Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%     purpose: open a link connection to an SR Research Eylink
%

    mglEyelinkCMDPrintF('record_status_message ''Task phase %d, block %d, trial %d.''', ...
        task.thistrial.thisphase, task.blocknum, task.trialnum);
    mglEyelinkEDFPrintF('TRIALID %d%d%d', ...
        task.thistrial.thisphase, task.blocknum, task.trialnum);
    mglEyelinkEDFPrintF('MGL BEGIN TRIAL %i', task.trialnum);
    mglEyelinkEDFPrintF('SYNCTIME');
    
end