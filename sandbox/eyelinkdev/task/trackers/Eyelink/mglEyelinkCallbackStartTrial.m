function [task myscreen] = mglEyelinkCallbackStartTrial(task, myscreen)
% mglEyelinkCallbackStartTrial - Assigns eye position to myscreen
%
% Usage: mglEyelinkCallbackStartTrial(IP, conntype)
%   IP - the ip address of the eyelink eye tracker, defaults to 100.1.1.1
%   conntype - the connection type: 0 opens a direct link, 1 initializes a
%              dummy connection

%     program: mglEyelinkCallbackStartTrial.m
%          by: eric dewitt
%        date: 04/03/06
%  copyright: (c) 2009,2006 Eric DeWitt, Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%     purpose: open a link connection to an SR Research Eylink
%

    mglEyelinkEDFPrintF(sprintf('BEGIN TRIAL %i'), task.trialnum);
    
end