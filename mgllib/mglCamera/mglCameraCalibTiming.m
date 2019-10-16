% mglCameraCalibTiming
%
%        $Id$
%      usage: taskTemplate
%         by: justin gardner
%       date: 10/16/2019
%  copyright: (c) 2006 Justin Gardner (GPL see mgl/COPYING)
%    purpose: program to calibrate the timing of camera frames. Basically the story is that
%             the Spinnaker library gives a timestamp for each image it collects from an FLIR camera
%             This timestamp is a device timestamp and I think accurate. Problem is that this
%             needs to sync to the systems clock against which we have all other events syncd. Right
%             now the mglCameraThread code gets this close to right by asking the device to return a time
%             stamp at the beginning and end of acquisition and then calibrating that against the
%             systems clock. This still seems to be partially inaccurate probably because of the delay it takes
%             from asking the device to return a time stamp and actually getting it. So to calibrate the
%             extra delay (about 70ms on my machine), this program displays system time stamps on the screen
%             If you point the camera at it, the camera will record those system time stamps in the image
%             then afterwords it will bring up a figure where you can read what the images say. Then
%             this program will compute what the correct timelag should be and store that as a 
%             mgl persistent setting which will be used to correct the timestamps whenever you use mglCameraThread
%
function myscreen = mglCameraCalibTiming

% check arguments
if ~any(nargin == [0])
  help mglCameraCalibTiming
  return
end

% initalize the screen
myscreen = initScreen;

% how long to capture images for in seconds
captureTime = 15;

task{1}.waitForBacktick = 0;
task{1}.segmin = [0.5 captureTime 3 1];
task{1}.segmax = [0.5 captureTime 3 1];
task{1}.numTrials = 1;

% initialize the task
for phaseNum = 1:length(task)
  [task{phaseNum} myscreen] = initTask(task{phaseNum},myscreen,@startSegmentCallback,@screenUpdateCallback);
end

% init the stimulus
global stimulus;
myscreen = initStimulus('stimulus',myscreen);
stimulus = myInitStimulus(stimulus,myscreen);
stimulus.captureTime = captureTime;

% init the camera
dispHeader('(cameraTest) Starting Camera Thread');
mglCameraThread('init');
stimulus.cameraImages = {};
dispHeader;

% set text size
mglTextSet('Courier',128,[1 1 1]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% run the eye calibration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
myscreen = eyeCalibDisp(myscreen);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main display loop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
phaseNum = 1;
while (phaseNum <= length(task)) && ~myscreen.userHitEsc
  % update the task
  [task myscreen phaseNum] = updateTask(task,myscreen,phaseNum);
  % flip screen
  myscreen = tickScreen(myscreen,task);
end

% if we got here, we are at the end of the experiment
myscreen = endTask(myscreen,task);

% end the camera thread
mglCameraThread('quit');

% ask user to get calibration
mglCameraGetCalibration(stimulus);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function that gets called at the start of each segment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task myscreen] = startSegmentCallback(task, myscreen)

global stimulus;

if task.thistrial.thisseg == 1
  % start saving camera
  mglCameraThread('capture','timeToCapture',stimulus.captureTime);
elseif task.thistrial.thisseg == 4
  % save camera images
  stimulus.cameraImages{end+1} = mglCameraThread('get');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function that gets called to draw the stimulus each frame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task myscreen] = screenUpdateCallback(task, myscreen)

global stimulus

mglClearScreen;
if task.thistrial.thisseg == 2;
  mglTextDraw(sprintf('%5.4f',mglGetSecs(stimulus.startTime)),[0 0]);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function to init the stimulus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function stimulus = myInitStimulus(stimulus,myscreen)

stimulus.startTime = mglGetSecs;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    mglCameraGetCalibration    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function mglCameraGetCalibration(stimulus)

% get first set of camera images
c = stimulus.cameraImages{1};

% bring up figure with some images
mlrSmartfig('cameraTestCalibrate','reuse');clf;

% decide which image to show first and how many to skip before showing the next
startImage = 50;
skipImage = 50;

% figure out how many images this is
nDisp = floor((size(c.im,3)-startImage)/skipImage);

% cycle through the images
for iDisp = 1:nDisp;
  r = [];imageStep = 0;
  while isempty(r)
    % get the image num
    thisImage = startImage+(iDisp-1)*skipImage+imageStep;
    if thisImage <= size(c.im,3)
      % display it
      imagesc(c.im(:,:,thisImage)');
      colormap(gray);
      % get the time stamp and set the title
      imageTimestamp(iDisp) = c.t(thisImage)-stimulus.startTime;
      title(sprintf('Image timestamp: %.4fs',imageTimestamp(iDisp)));
      r = input('(mglCameraCalibTiming) What number do you see (hit ENTER if image is not clear or ''skip'' to skip this calibration point): ','s');
      imageStep = imageStep+1;
    else
      r = 'skip';
    end
  end
  if ~strcmp(r,'skip')
    % get the timestamp that the user put in
    timestamp(iDisp) = str2num(r);
    % and display it
    disp(sprintf('(mglCameraCalibTiming) Frame: %0.4f happened at: %.4f (delay: %0.4f)',imageTimestamp(iDisp),timestamp(iDisp),imageTimestamp(iDisp)-timestamp(iDisp)));
  else
    timestamp(iDisp) = nan;
  end
end

% deal wtih any skipped values
goodVals = find(~isnan(timestamp));
imageTimestamp = imageTimestamp(goodVals);
timestamp = timestamp(goodVals);
if isempty(timestamp)
  disp(sprintf('(mglCameraCalibTiming) No calibration points. Aborting'));
  return
end

% get slope and offset
x = imageTimestamp(:);x(:,2) = 1;
fit = (((x' * x)^-1) * x')*timestamp(:);

% display what we found
disp(sprintf('(mglCameraCalibTiming) Slope (should be close to 1): %0.4f and Intercept (in ms of delay): %0.4f',fit(1),fit(2)*1000));

% get old setting
cameraDelay = mglGetParam('mglCameraDelay');
if ~isempty(cameraDelay)
  newCameraDelay = cameraDelay + fit(2);
else
  newCameraDelay = fit(2);
end

% ask user if they want to update the setting
dispHeader('(mglCameraCalbTiming) By setting mglCameraDelay, the program mglCameraThread will correct for this amount of delay the next time you use mglCameraThread and can be overridden by using mglSetParam to set mglCameraDelay to zero. The setting is persistent to starting a new matlab session');
if isempty(cameraDelay)
  askUserStr = sprintf('(mglCameraCalibTiming) Ok to set mglCameraDelay to %0.4f ms of delay',newCameraDelay*1000);
else
  askUserStr = sprintf('(mglCameraCalibTiming) Ok to reset mglCameraDelay form %0.4fms to %0.4fms of delay',cameraDelay*1000,newCameraDelay*1000);
end

if askuser(askUserStr)
  mglSetParam('mglCameraDelay',newCameraDelay,1);
end


