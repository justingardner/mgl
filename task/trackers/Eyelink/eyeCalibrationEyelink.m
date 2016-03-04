function [myscreen] = eyeCalibrationEyelink(myscreen)
% eyeCalibrationEyelink - initializes a the myscreen and tracker for use
%
%        $Id: eyeCalibrationEyelink.m 203 2007-03-19 15:41:00Z justin $
%      usage: myscreen = eyeCalibrationEyelink(myscreen)
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

if ~myscreen.eyetracker.dummymode
  fprintf(2,'(eyeCalibrationEyelink) Calibrating Eyelink.\n');
  % get current coordinates
  inScreenCoord = mglGetParam('screenCoordinates');
  
  % This screws up the autothresholding (as the text changes the luminence from
  % what it will be during the experiment). Also, this text should not be on the
  % users screen, it should be on the console.
  % % draw some text to tell user what is going on
  % mglTextDraw('Calibrate Eyelink - Hit ESC when finished',[0 0]);
  disp('===========================');
  disp('Enter: Display camera image');
  disp('c: Start calibration routine');
  disp('v: Start verification routine');
  disp('a: autothreshold');
  disp('ESC: Finished');
  disp('For a full list of commands. Hit F1 on eye tracker');
  disp('===========================');
  mglFlush;

  % get any shift of screen origin so that
  % the calibration code can place targets approriately - note
  % that we don't deal with coordinate flipping here (should we?) 
  % Instead getTaskEyeTraces will adjust the eye position data
  % from the file for any horizontal or vertical flipping of the
  % screen done mglEditScreenParams
  xOffset = 0;yOffset = 0;
  deviceOrigin = mglGetParam('deviceOrigin');
  if length(deviceOrigin) >= 2
    xOffset = mglGetParam('deviceHDirection')*round(deviceOrigin(1)*mglGetParam('xDeviceToPixels'));
    yOffset = -mglGetParam('deviceVDirection')*round(deviceOrigin(2)*mglGetParam('yDeviceToPixels'));
  end
  mglSetParam('eyelinkCoordinateXShift',xOffset);
  mglSetParam('eyelinkCoordinateYShift',yOffset);
    
  % switch to screen coordinates
  mglScreenCoordinates();
  
  % run calibration routine
  mglEyelinkSetup();
  
  % return screen coordinates
  if ~inScreenCoord
    mglVisualAngleCoordinates(myscreen.displayDistance, myscreen.displaySize);
  end
  
  % clear screen
  mglClearScreen;
  mglFlush;
  mglClearScreen;
  mglFlush;
else
  fprintf(2,'(eyeCalibrationEyelink) Skipping calibration in dummy mode.\n');
end
