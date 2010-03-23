% taskTemplate.m
%
%        $Id: taskTemplate.m 217 2007-04-04 16:54:42Z justin $
%      usage: taskTemplate
%         by: eric dewitt
%       date: 03/19/2010
%  copyright: (c) 2006 Justin Gardner (GPL see mgl/COPYING)
%    purpose: example program that demonstrates a gaze contingent experiment
%             (displays a line of text which gets revealed as you look at it)
%             using the EyeLink tracker. You will need to have the eyelink code
%             compiled to use this: mglMake('eyelink');
%
function myscreen = taskTemplateGazeContingent

% check arguments
if ~any(nargin == [0])
  help taskTemplate
  return
end

% initalize the screen
%myscreen.screenParams{1} = {mglGetHostName,[],2,1280,1024,57,[31 23],60,1,0,'',1.8,'',[0 0]};

% background
myscreen.background = 0.2;

% initialize the screen
myscreen = initScreen(myscreen);

% this specifies whether to save data or not
myscreen.eyetracker.savedata = true;

% this says what data to collect:
% (file-samples file-events link-samples ~link-events)
myscreen.eyetracker.data = [1 1 1 0]; % don't need link events

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% run the eye calibration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this initializes the eye tracker subsystem (a set of callback functions)
myscreen = initEyeTracker(myscreen, 'Eyelink');
% this calls the appropriate calibration function for the initialized eyetracker
myscreen = calibrateEyeTracker(myscreen);

task{1}.waitForBacktick = 0;
% fix: the task defined here has two segments, one that
% is 3 seconds long followed by another that is 
% 6-9 seconds (randomized in steps of 1.5 seconds)
% change this to what you want for your trial
task{1}.segmin = [5 3];
task{1}.segmax = [5 6];
task{1}.segquant = [0 1.5];
% fix: enter the parameter of your choice
task{1}.parameter.myParameter = [0 30 90];
task{1}.random = 1;

% if we want to collect eyedata we must also specify it in one of the task/phases
% otherwise it will default to false
task{1}.collectEyeData = true;

% initialize the task
for phaseNum = 1:length(task)
  [task{phaseNum} myscreen] = initTask(task{phaseNum},myscreen,@stimStartSegmentCallback,@stimDrawStimulusCallback);
end

% init the stimulus
global stimulus;
myscreen = initStimulus('stimulus',myscreen);

% fix: you will change the function myInitStimulus
% to initialize the stimulus for your experiment.
stimulus = myInitStimulus(stimulus,myscreen);

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

global stimulus;

% fix: do anything that needs to be done at the beginning
% of a segment (like for example setting the stimulus correctly
% according to the parameters etc).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function that gets called to draw the stimulus each frame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task myscreen] = stimDrawStimulusCallback(task, myscreen)

global stimulus

% fix: display your stimulus here, for this code we just display 
% a fixation cross that changes color depending on the segment
% we are on.

mglClearScreen;

mglBltTexture(stimulus.texture,[0,0], 'center', 'center')

mglGluAnnulus(myscreen.eyetracker.eyepos(1),myscreen.eyetracker.eyepos(2),5,500, [0.8 0.8 0.8]*myscreen.background);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function to init the dot stimulus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function stimulus = myInitStimulus(stimulus,myscreen)

mglTextSet('Helvetica',48,[0 0.5 1 1],0,0,0,0,0,0,0);
if myscreen.eyetracker.init
  stimulus.texture = mglText('Please read this line of text. Hit ESC to end.');
else
  stimulus.texture = mglText('Tracker failed to init. Hit ESC to end.');
end  
% fix: add stuff to initalize your stimulus
stimulus.init = 1;


