% mglMetalIsRunning: Returns info about any running mglMetal processes
%
%        $Id$
%      usage: [tf, pids, addresses] = mglMetalIsRunning(socketInfo)
%         by: justin gardner
%       date: 09/27/2021
%  copyright: (c) 2021 Justin Gardner (GPL see mgl/COPYING)
%    purpose: Returns whether mglMetal is running, along with process info
%      usage: tf = mglMetalIsRunning;
%
%             By default, this will check for all mglMetal processes that
%             were started via mglMetalStartup.  To search for a specific
%             mglMetal process, pass in its socket info struct, as returned
%             from mglMetalStartup.
%
%             tf = mglMetalIsRunning(socketInfo)
%
%             This can also return an array of process ids and socket
%             addresses for any processes that were found.
%
%             [tf, pids, addresses] = mglMetalIsRunning;
%             [tf, pids, addresses] = mglMetalIsRunning(socketInfo);
%
%             Note: for now, the pids and addresses don't necessarily
%             correspond 1:1.
%
function [tf, pids, addresses] = mglMetalIsRunning(socketInfo)

tf = false;
pids = [];
addresses = {};

if nargin < 1 || isempty(socketInfo)
    [~, mglMetalSandbox] = mglMetalExecutableName();
    addressPattern = fullfile(mglMetalSandbox, 'mglMetal.socket*');
else
    addressPattern = socketInfo.address;
end

% Find processes we own based on the expected socket addresses pattern.
% These should be the process we started recently as with mglMetalStartup.
% The format "-F pn" says:
%  - print each PID on a new line starting with "p"
%  - print socket file name on a new line starting with "n"
[~, processInfo] = system(['lsof -F pn ', addressPattern]);

% Find any PID lines, which look like "p0000" and dig out the PID numbers.
info = strsplit(processInfo, '\n');
pidLines = find(startsWith(info, 'p'));
for ii = pidLines
    pidLine = info{ii};
    pid = sscanf(pidLine, 'p%i');
    pids(end+1) = pid;
end
tf = ~isempty(pids);

% Find any address lines, which look like "nabcd".
addressLines = find(startsWith(info, 'n'));
for ii = addressLines
    addressLine = info{ii};
    address = sscanf(addressLine, 'n%s');
    addresses{end+1} = address;
end
addresses = unique(addresses);
