function [] = mglEyelinkOpen(ip, conntype)
% mglEyelinkOpen - Opens a connection to an SR Resarch Eyelink eyetracker
%
% Usage: mglEyelinkOpen(IP, conntype)
%   IP - the ip address of the eyelink eye tracker, defaults to 100.1.1.1
%   conntype - the connection type: 0 opens a direct link, 1 initializes a
%              dummy connection

%     program: mglEyelinkOpen.m
%          by: eric dewitt
%        date: 04/03/06
%  copyright: (c) 2009,2006 Eric DeWitt, Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%     purpose: open a link connection to an SR Research Eylink
%

    if ~any(nargin == [0 1 2])
        help mglEyelinkOpen;
    end
    if nargin < 1
        ip = '100.1.1.1';
    elseif ~ischar(ip) && numel(strfind(ip,'.')) ~= 3
        error('Please pass in an IP address in the form of a string.');
    end
    if nargin < 2
        conntype = 0; % open live connection
    end
    mglPrivateEyelinkOpen(ip, conntype);
    
end