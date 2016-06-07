% mglDefaultScreenParams.m
%
%        $Id:$ 
%      usage: mglDefaultScreenParams()
%         by: justin gardner
%       date: 04/26/10
%    purpose: Get a default screen parameters
%
% screenParams = mglDefaultScreenParams
%
function screenParams = mglDefaultScreenParams(screenParams)

% get host/display name
if nargin < 1
  screenParams.computerName = mglGetHostName;
  screenParams.displayName = '';
end

displays = mglDescribeDisplays;

% get screen settings
screenParams.screenNumber = length(displays);
screenParams.screenWidth = displays(end).screenSizePixel(1);
screenParams.screenHeight = displays(end).screenSizePixel(2);
screenParams.framesPerSecond = displays(end).refreshRate;

% get display settings
screenParams.displayDistance = 57;
screenParams.displaySize = [50.8 38.1];
screenParams.displayPos = [0 0];
screenParams.flipHV = [0 0];
screenParams.hideCursor = 0;
screenParams.autoCloseScreen = 1;

% get file saving settings
screenParams.saveData = 0;

% keyboard settings
screenParams.eatKeys = 0;
screenParams.backtickChar = '`';
screenParams.responseKeys = {'1' '2' '3' '4' '5' '6' '7' '8' '9' '0'};

% calibration info
screenParams.calibType = 'None';
screenParams.calibFilename = '';
screenParams.monitorGamma = [];

% digio
screenParams.digin.use = 0;
screenParams.digin.portNum = 2;
screenParams.digin.acqLine = 0;
screenParams.digin.acqType = 1;
screenParams.digin.responseLine = [1 2 3 4 5 6 7];
screenParams.digin.responseType = 1;

% eyeTracker
screenParams.eyeTrackerType = 'None';

% validate
screenParams = mglValidateScreenParams(screenParams);

