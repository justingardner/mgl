% taskTemplateSaccade.m
%
%        $Id: taskTemplate.m 217 2007-04-04 16:54:42Z justin $
%      usage: taskTemplateSaccade
%         by: justin gardner
%       date: 04/27/2010
%  copyright: (c) 2010 Justin Gardner (GPL see mgl/COPYING)
%    purpose: example program that demonstrates a simple saccade task
%             that runs the eye calibration and saves eye position traces
%             should be useful for testing that you are collecting eye position data correctly
%
function myscreen = taskTemplateSaccade

% check arguments
if ~any(nargin == [0])
  help taskTemplateSaccade
  return
end

% initialize the screen
myscreen.background = 0;
myscreen = initScreen(myscreen);

% setup task
task{1}.waitForBacktick = 0;
task{1}.segmin = [1 1.5 0.5];
task{1}.segmax = [1 1.5 1.5];
task{1}.parameter.targetAngle = [0:45:359];
task{1}.parameter.targetRadius = [5 8];
task{1}.random = 1;

% initialize the task
for phaseNum = 1:length(task)
  [task{phaseNum} myscreen] = initTask(task{phaseNum},myscreen,@stimStartSegmentCallback,@stimDrawStimulusCallback);
end

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
function [task myscreen] = stimStartSegmentCallback(task, myscreen)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function that gets called to draw the stimulus each frame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task myscreen] = stimDrawStimulusCallback(task, myscreen)

mglClearScreen;

% either draw the target at the target location
if task.thistrial.thisseg == 2
  x = task.thistrial.targetRadius * cos(pi*task.thistrial.targetAngle/180);
  y = task.thistrial.targetRadius * sin(pi*task.thistrial.targetAngle/180);
else
  % or at the center of the screen
  x = 0;
  y = 0;
end

% draw the target
mglGluDisk(x,y,0.1,[1 1 1]);


