function [task myscreen] = mglEyelinkCallbackSaveData(task, myscreen)
% mglEyelinkCallbackSaveData - Assigns eye position to myscreen
%
% Usage: mglEyelinkCallbackSaveData(IP, conntype)
%   IP - the ip address of the eyelink eye tracker, defaults to 100.1.1.1
%   conntype - the connection type: 0 opens a direct link, 1 initializes a
%              dummy connection

%     program: mglEyelinkCallbackSaveData.m
%          by: eric dewitt
%        date: 04/03/06
%  copyright: (c) 2009,2006 Eric DeWitt, Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%     purpose: open a link connection to an SR Research Eylink
%

if (~mglEyelinkRecordingCheck())
  %% if we are recording, stop
  mglEyelinkRecordingStop();
end

% close the datafile
mglEyelinkCMDPrintF('close_data_file');

% go offline
mglPrivateEyelinkGoOffline();

% transfer the datafile
curdir = pwd;
cd(myscreen.datadir);
mglPrivateEyelinkEDFGetFile(sprintf('%s.edf', myscreen.eyetracker.datafilename));
cd(curdir);
