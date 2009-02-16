function [] = mglEyelinkOpen(ip)
% mglEyelinkOpen - Opens a connection to an SR Resarch Eyelink eyetracker
%
% Usage: mglEyelinkOpen(IP)
%   IP - the ip address of the eyelink eye tracker, defaults to 100.1.1.1
%

%     program: mglEyelinkOpen.m
%          by: eric dewitt
%        date: 04/03/06
%  copyright: (c) 2009,2006 Eric DeWitt, Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%     purpose: open a link connection to an SR Research Eylink
%

    if ~any(nargin == [0 1])
        help mglEyelinkOpen;
    end
    if nargin < 1
        ip = '100.1.1.1';
    elseif ~ischar(ip) && numel(strfind(ip,'.')) ~= 3
        error('Please pass in an IP address in the form of a string.');
    end
    mglPrivateEyelinkOpen(ip);
end