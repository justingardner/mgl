function [myscreen] = calibrateEyeTracker(myscreen)
% calibrateEyeTracker - calibrates the eye-tracker
%
% The tracker must have been initialized first (see initEyeTracker)
%
% calibrateEyeTracker.m
%
%        $Id: calibrateEyeTracker.m 203 2007-03-19 15:41:00Z justin $
%      usage: myscreen = calibrateEyeTracker(myscreen, [tracker])
%         by: eric dewitt
%       date: 2009-03-10
%  copyright: (c) 2006 Justin Gardner (GPL see mgl/COPYING)
%             (c) Copyright 2009 Eric DeWitt. All Rights Reserved. 
% 

initializer = [];
if ~any(nargin==[1])
  help calibrateEyeTracker;
end

if isfield(myscreen, 'eyetracker') && isfield(myscreen.eyetracker, 'init') ...
      && myscreen.eyetracker.init
  % first turn off eat keys if eat keys is set
  mglListener('quit');
  %% calibrate the eyetracker by type
  calibrator = sprintf('eyeCalibration%s', myscreen.eyeTrackerType);
  eval(sprintf('myscreen = %s(myscreen);', calibrator));
  if myscreen.eatKeys,mglEatKeys(myscreen);end
else
  fprintf(2, '(calibrateEyeTracker) No eye-tracker has been initialized.\n');
end
    
% eat any keys that are left around from the calibration
mglGetKeyEvent(0,1);

