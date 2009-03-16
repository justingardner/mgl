% eyeCalibDisp.m
%
%        $Id$
%      usage: eyeCalibDisp()
%         by: justin gardner
%       date: 12/10/04
%  copyright: (c) 2006 Justin Gardner (GPL see mgl/COPYING)
%    purpose: eye calibration - mgl version
%             stimuli should be defined in visual angle coords
%

% TODO: make this function generic with respect to the eyetracker used
function myscreen = eyeCalibDisp(myscreen)

    if ~myscreen.eyetracker.init
        myscreen = initASLEyeTracker(myscreen);
    end
    if myscreen.eyetracker.init
        myscreen = eyeCalibrationASL(myscreen);
    else
        error('Eyetracker initialization failed');
    end
    
end