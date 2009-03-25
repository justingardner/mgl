function [myscreen] = initEyeLinkEyeTracker(myscreen, conntype)
% initEyeLinkEyeTracker - initializes a the myscreen and tracker for use
%
%

% initEyeLinkEyeTracker.m
%
%        $Id: initEyeLinkEyeTracker.m 203 2007-03-19 15:41:00Z justin $
%      usage: myscreen = initEyeLinkEyeTracker(myscreen, [tracker])
%         by: eric dewitt
%       date: 2009-03-10
%  copyright: (c) 2006 Justin Gardner (GPL see mgl/COPYING)
%             (c) Copyright 2009 Eric DeWitt. All Rights Reserved. 
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

    if nargin < 2 || conntype == 0
        conntype = 0;
        myscreen.eyetracker.dummymode = 0;
        fprintf('(initEyeLinkEyeTracker) Initializing Eyelink eye tracker.\n');
    elseif conntype == 1
        fprintf('(initEyeLinkEyeTracker) Initializing Eyelink in dummy mode.\n');
        myscreen.eyetracker.dummymode = 1;
    else
        error('(initEyeLinkEyeTracker) Unknown connection type.\n');
    end
        
    % open the connection,
    % TODO: allow IP to be specified in myscreen.eyetracker
    mglEyelinkOpen('100.1.1.1', conntype);
    % pixels [left top width height]
    mglEyelinkCMDPrintF('screen_pixel_coords = 0, 0, %d, %d',...
        mglGetParam('screenWidth'), mglGetParam('screenHeight'));
    % physical size from center, starting with center to left edge dist,
    % proceeding clockwise (all physical values are in mm)
    mglEyelinkCMDPrintF('screen_phys_coords = %6.2f, %6.2f, %6.2f, %6.2f', ...
        -(myscreen.displaySize(1)/2)*10, (myscreen.displaySize(2)/2)*10, ...
         (myscreen.displaySize(1)/2)*10, -(myscreen.displaySize(2)/2)*10);
    % distance between the eye and the top and bottom center of the display
    % (to allow for angled displays)
    mglEyelinkCMDPrintF('screen_distance = %6.2f, %6.2f', ...
        ((myscreen.displayDistance^2 + (myscreen.displaySize(2)/2)^2)^0.5)*10,...
        ((myscreen.displayDistance^2 + (myscreen.displaySize(2)/2)^2)^0.5)*10);
    % select calibration type
    % TODO: allow calibration type to be specified in myscreen.eyetracker
    mglEyelinkCMDPrintF('calibration_type = HV9');
    % select events to save
    % TODO: allow events to be specified in myscreen.eyetracker
    mglEyelinkCMDPrintF('file_event_filter = RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON'); 
    % select data to save
    % TODO: allow data to be specified in myscreen.eyetracker
    mglEyelinkCMDPrintF('file_sample_data = RIGHT,GAZE,AREA,GAZERES,STATUS');
    % set the sample rate
    % TODO: allow sample rate to be specified in myscreen.eyetracker
    mglEyelinkCMDPrintF('sample_rate = 500');

    myscreen.eyetracker.callback.getPosition    = @mglEyelinkCallbackGetPosition;
    myscreen.eyetracker.callback.nextTask       = @mglEyelinkCallbackNextTask;
    myscreen.eyetracker.callback.startBlock     = @mglEyelinkCallbackStartBlock;
    myscreen.eyetracker.callback.startTrial     = @mglEyelinkCallbackTrialStart;
    myscreen.eyetracker.callback.endTrial       = @mglEyelinkCallbackTrialEnd;
    myscreen.eyetracker.callback.startSegment   = @mglEyelinkCallbackStartSegment;
    myscreen.eyetracker.callback.saveEyeData    = @mglEyelinkCallbackSaveData;
    myscreen.eyetracker.callback.endTracking    = @mglEyelinkCallbackCloseTracker;
    
    % if save then get file, default to saving
    %% TODO: this is a hack and should be improved
    if ~isfield(myscreen.eyetracker, 'savedata') || myscreen.eyetracker.savedata
        if isfield(myscreen.eyetracker, 'data')
            myscreen.eyetracker.data = myscreen.eyetracker.data | [0 0 1 1];
        else
            myscreen.eyetracker.data = [1 0 1 1];
        end
        global gNumSaves;
        % update the numsaves variable
        if (isempty(gNumSaves))
          stimnamenum = 1;
        else
          stimnamenum = gNumSaves+1;
        end
        % get filename
        thedate = [datestr(now,'yy') datestr(now,'mm') datestr(now,'dd')];
        myscreen.eyetracker.datafilename = sprintf('%s%02i',thedate,stimnamenum);
    
        % get a data file
        mglPrivateEyelinkOpenEDF(sprintf('%s.edf', myscreen.eyetracker.datafilename));
        % Basic data file info
        mglEyelinkEDFPrintF('DISPLAY_COORDS 0 0 %d %d',...
            mglGetParam('screenWidth'), mglGetParam('screenHeight'));
        mglEyelinkEDFPrintF('FRAMERATE %f4.2', 1/mglGetParam('frameRate'));
        
    end
    
    myscreen.eyetracker.init = 1;
    
end