function [task myscreen] = mglEyelinkCallbackStartSegment(task, myscreen)
% mglEyelinkCallbackStartSegment - 
%
% Usage: mglEyelinkCallbackStartSegment(task, myscreen)

%     program: mglEyelinkCallbackStartSegment.m
%          by: eric dewitt
%        date: 04/03/06
%  copyright: (c) 2009,2006 Eric DeWitt, Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%     purpose: open a link connection to an SR Research Eylink
%

    mglEyelinkEDFPrintF('MGL BEGIN SEGMENT %i', task.thistrial.thisseg);
    
end