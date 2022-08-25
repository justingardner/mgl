% mglMetalIsRunning: Returns whether the mglMetal application is running
%
%        $Id$
%      usage: mglMetalIsRunning
%         by: justin gardner
%       date: 09/27/2021
%  copyright: (c) 2021 Justin Gardner (GPL see mgl/COPYING)
%    purpose: Returns whether mglMetal processes are running, and any pids
%      usage: tf = mglMetalIsRunning;
%
%             to get the process ids for the mglMetal processes
%             [tf pids] = mglMetalIsRunning;
%
function [tf, pids] = mglMetalIsRunning

tf = false;
pids = [];

global mgl
if isempty(mgl) || ~isfield(mgl, 's') || isempty(mgl.s)
    return;
end

% Find the PID of processes we own, which are using known socket addresses.
% These should be the mglMetal process we started recently as with mglOpen.
% The format "-F p" says to print each PID on a new line starting with "p".
[status, processInfo] = system(['lsof -F p ', mgl.s.address]);
if status
    return;
end

% Find any PID lines, which look like "p0000".
info = strsplit(processInfo, '\n');
pidLines = find(startsWith(info, 'p'));
if isempty(pidLines)
    return;
end

% Dig out integer pids from the "p0000" lines we found.
tf = true;
for ii = pidLines
    pidLine = info{ii};
    pid = sscanf(pidLine, 'p%i');
    pids = [pids; pid];
end
