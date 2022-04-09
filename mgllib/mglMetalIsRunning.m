% mglMetalIsRunning: Returns whether the mglMetal application is running
%
%        $Id$
%      usage: mglMetalIsRunning
%         by: justin gardner
%       date: 09/27/2021
%  copyright: (c) 2021 Justin Gardner (GPL see mgl/COPYING)
%    purpose: Returns the name of the mglMetal application
%      usage: tf = mglMetalIsRunning;
%
%             to get the process ids for the mglMetal application
%             [tf psid] = mglMetalIsRunning;
%
function [tf, psid] = mglMetalIsRunning

tf = false;
psid = [];

% check if mglMetal is running
[status, isMetalRunning] = system('ps aux | grep -i mglMetal | grep -v grep');

% check whether the string mglMetal.app is in the return - this
% is necessary because the system command also returns anything
% that is in the text buffer - for example, if you copy and
% paste a set of commands, for some reason that is in the return of system
if ~isempty(strfind(isMetalRunning,'mglMetal.app'))
  tf = true;
  [~,isMetalRunning] = strtok(isMetalRunning);
  [psid] = strtok(isMetalRunning);
  psid = str2num(psid);
end
