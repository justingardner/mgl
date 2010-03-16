function [] = mglEyelinkClose()
% mglEyelinkClose - Closses a connection to an SR Resarch Eyelink eyetracker
%
% Usage: mglEyelinkClose()

%     program: mglEyelinkClose.m
%          by: eric dewitt
%        date: 08/03/09
%  copyright: (c) 2009,2009 Eric DeWitt, Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%     purpose: close a link connection to an SR Research Eylink
%

    if ~any(nargin == [0 1 2])
        help mglEyelinkClose;
    end
    mglPrivateEyelinkClose();
    
end