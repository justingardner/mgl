% eyeCalib9.m
%
%        $Id$
%      usage: eyeCalib9.m()
%         by: justin gardner
%       date: 02/24/05
%  copyright: (c) 2006 Justin Gardner (GPL see mgl/COPYING)
%
function retval = eyeCalib9(bkcolor)

if ~exist('bkcolor','var'),bkcolor = 'gray',end

% init the screen
myscreen.background = bkcolor;
myscreen = initScreen(myscreen);
  
myscreen = initASLEyeTracker(myscreen, 9);

% do eye calibration
eyeCalibDisp(myscreen);
myscreen = tickScreen(myscreen);

writeDigPort(0);
