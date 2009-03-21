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
        
    mglEyelinkOpen('100.1.1.1', conntype);
    mglEyelinkCMDPrintF('screen_pixel_coords = 0 0 %d %d', mglGetParam('screenWidth'), mglGetParam('screenHeight')); 
    mglEyelinkCMDPrintF('calibration_type = HV9');
    mglEyelinkCMDPrintF('file_event_filter = RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON'); 
    mglEyelinkCMDPrintF('file_sample_data = RIGHT,GAZE,AREA,GAZERES,STATUS'); 
    mglEyelinkCMDPrintF('sample_rate = 500');

    myscreen.eyetracker.callback.getposition    = @mglEyelinkCallbackGetPosition;
    % myscreen.eyetracker.callback.nextTask       = @mglEyelinkCallbackNextTask;
    % myscreen.eyetracker.callback.startBlock     = @mglEyelinkCallbackStartBlock;
    myscreen.eyetracker.callback.startTrial     = @mglEyelinkCallbackStartTrial;
    % myscreen.eyetracker.callback.startSegment   = @mglEyelinkCallbackStartSegment;
    myscreen.eyetracker.init = 1;
    
end