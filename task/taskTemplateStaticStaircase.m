% taskTemplateStaticStaircase.m
%
%        $Id$
%      usage: taskTemplateStaticStaircase
%         by: justin gardner
%       date: 01/27/07
%  copyright: (c) 2007 Justin Gardner (GPL see mgl/COPYING)
%    purpose: example program to show how to use the task structure
%
function myscreen = taskTemplateStaticStaircase

% check arguments
if ~any(nargin == [0])
  help taskTemplateStaticStaircase
  return
end

% initalize the screen
myscreen.background = 'gray';
myscreen = initScreen(myscreen);

task{1}.waitForBacktick = 1;
% task has segments, 1st which displays ready text
% 2nd and 4th which display the stimulus and 5th
% which is the response interval
task{1}.seglen = [1 0.5 0.25 0.5 1.5];
task{1}.getResponse = [0 0 0 0 2];
% we test at three different orientations
task{1}.parameter.orientation = [-45 90 45];
% and have the task structure pick which interval
% to display the target from a uniform distribution
task{1}.randVars.uniform.targetInterval = [1 2];
task{1}.random = 1;

% initialize the task
for phaseNum = 1:length(task)
  [task{phaseNum} myscreen] = initTask(task{phaseNum},myscreen,@startSegmentCallback,@screenUpdateCallback,@responseCallback);
end

% init the stimulus
global stimulus;
myscreen = initStimulus('stimulus',myscreen);

% do our initialization which creates a grating
% and sets up the staircase
stimulus = myInitStimulus(stimulus,myscreen,task);

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function that gets called at the start of each segment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task myscreen] = startSegmentCallback(task, myscreen)

global stimulus;

% clear the screen
mglClearScreen;

% for the first segment just display the ready text
if task.thistrial.thisseg == 1
  mglTextDraw(sprintf('Which interval is more clockwise (1 or 2)?'),[0 0]);
% check to see if we are in one of the segments in which
% the stimulus should be shown.
elseif any(task.thistrial.thisseg == stimulus.stimulusSegments)
  % get which staircase we are working on
  staircaseNum = find(task.thistrial.orientation==task.parameter.orientation);
  % check if this segment is the target interval. If it is then
  % display the stimulus with the threshold added to the orientation
  if task.thistrial.thisseg == stimulus.stimulusSegments(task.thistrial.targetInterval)
    mglBltTexture(stimulus.tex,[0 0],0,0,task.thistrial.orientation);
  else
    mglBltTexture(stimulus.tex,[0 0],0,0,task.thistrial.orientation+stimulus.stair{staircaseNum}.threshold);
  end
end  
% set flush mode to 1, this will insure that mglFlush will be
% called once to display the screen (but won't continue to get
% called every 1/framerate).
myscreen.flushMode = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function that gets called to draw the stimulus each frame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task myscreen] = screenUpdateCallback(task, myscreen)

% note that here we do not have anything drawing in the
% screenUpdateStimulus callback. We are just doing it in the initSegment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function that gets subject  response
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task myscreen] = responseCallback(task, myscreen)

global stimulus;
global MGL;
mglClearScreen;
% make sure we have not already received a response
if ~task.thistrial.gotResponse
  % get which staircase we are working on
  staircaseNum = find(task.thistrial.orientation==task.parameter.orientation);
  % display stuff
  disp(sprintf('Orientation %i threshold %0.2f correct %i reaction time: %0.3f reversals: %i', task.thistrial.orientation,stimulus.stair{staircaseNum}.threshold,task.thistrial.whichButton == task.thistrial.targetInterval,round(task.thistrial.reactionTime*1000),stimulus.stair{staircaseNum}.reversaln));
  % see if we got a correct or incorrect answer
  if task.thistrial.whichButton == task.thistrial.targetInterval
    mglTextDraw('Correct',[0 0]);
    % update staircase
    stimulus.stair{staircaseNum} = upDownStaircase(stimulus.stair{staircaseNum},1);
    % play the correct sound
    mglPlaySound(find(strcmp(MGL.soundNames,'Tink')));
  else
    mglTextDraw('Incorrect',[0 0]);
    % update staircase
    stimulus.stair{staircaseNum} = upDownStaircase(stimulus.stair{staircaseNum},0);
    % play the incorrect sound
    mglPlaySound(find(strcmp(MGL.soundNames,'Pop')));
  end  
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function to init the dot stimulus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function stimulus = myInitStimulus(stimulus,myscreen,task)

% fix: add stuff to initalize your stimulus
stimulus.init = 1;

% keep an array that lists which of the segments we
% are presenting the stimulus in. 
stimulus.stimulusSegments = [2 4];

% make a gabor patch
grating(:,:,1) = 255*(makeGrating(8,8,1.5,0,0)+1)/2;
grating(:,:,2) = 255*(makeGrating(8,8,1.5,0,0)+1)/2;
grating(:,:,3) = 255*(makeGrating(8,8,1.5,0,0)+1)/2;
grating(:,:,4) = 255*makeGaussian(8,8,1,1);

% make it into a texture
stimulus.tex = mglCreateTexture(grating);

% set the starting threshold and stepsize
stimulus.threshold = 10;
stimulus.stepsize = 3;

% now create staircases for each orientation
for i = 1:length(task{1}.parameter.orientation)
  % init a 2 down 1 up staircase
  stimulus.stair{i} = upDownStaircase(1,2,stimulus.threshold,stimulus.stepsize,1);
  % the minimum threshold is 0
  stimulus.stair{i}.minThreshold = 0;
end
