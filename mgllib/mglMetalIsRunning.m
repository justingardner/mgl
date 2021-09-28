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
function [tf psid] = mglMetalIsRunning

tf = false;

% check if mglMetal is running
[status isMetalRunning] = system('ps aux | grep -i mglMetal | grep -v grep');

if ~isempty(isMetalRunning)
  tf = true;
  [~,isMetalRunning] = strtok(isMetalRunning);
  [psid] = strtok(isMetalRunning);
  psid = str2num(psid);
end
