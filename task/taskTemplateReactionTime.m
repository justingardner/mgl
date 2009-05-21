% taskTemplateReactionTime.m
%
%        $Id$
%      usage: taskTemplateReactionTime
%         by: justin gardner
%       date: 01/27/07
%  copyright: (c) 2007 Justin Gardner (GPL see mgl/COPYING)
%    purpose: example program to show how to use the task structure
%
function myscreen = taskTemplateReactionTime

% check arguments
if ~any(nargin == [0])
  help taskTemplateReactionTime
  return
end

% initalize the screen
myscreen.background = 'gray';
myscreen = initScreen(myscreen);

task{1}.waitForBacktick = 1;
% fix: the task defined here has two segments, 
% one to display the ready text and one for the response interval
task{1}.segmin = [0.5 3];
task{1}.segmax = [1.5 3];
task{1}.getResponse = [0 2];
% fix: enter the parameter of your choice
task{1}.parameter.myParameter1 = [0 30 90];
task{1}.random = 1;

% initialize the task
for phaseNum = 1:length(task)
  [task{phaseNum} myscreen] = initTask(task{phaseNum},myscreen,@startSegmentCallback,@drawStimulusCallback,@responseCallback);
end

% init the stimulus
global stimulus;
myscreen = initStimulus('stimulus',myscreen);

% fix: you will change the funciton myInitStimulus
% to initialize the stimulus for your experiment.
stimulus = myInitStimulus(stimulus,myscreen);

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

mglClearScreen;
if (task.thistrial.thisseg == 1)
  mglTextDraw('Hit 1 when this text disappears',[0 0]);
end  
myscreen.flushMode = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function that gets called to draw the stimulus each frame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task myscreen] = drawStimulusCallback(task, myscreen)

% note that here we do not have anything drawing in the
% drawStimulus callback. We are just doing it in the initSegment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function that gets subject  response
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task myscreen] = responseCallback(task, myscreen)

if task.thistrial.gotResponse == 0
  mglClearScreen;
  % display what the reaction time was
  if task.thistrial.whichButton == 1
    mglTextDraw(sprintf('Your reaction time was: %0.0f ms',round(task.thistrial.reactionTime*1000)),[0 0]);
  else
    mglTextDraw(sprintf('You hit %i instead of 1',task.thistrial.whichButton),[0 0]);
  end  
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function to init the dot stimulus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function stimulus = myInitStimulus(stimulus,myscreen)

% fix: add stuff to initalize your stimulus
stimulus.init = 1;


