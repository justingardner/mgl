% taskTemplateSeglenPrecompute.m
%
%        $Id: taskTemplateSeglenPrecompute.m 835 2010-06-29 04:04:08Z justin $
%      usage: taskTemplateSeglenPrecompute
%         by: justin gardner
%       date: 09/25/2013 
%  copyright: (c) 2006 Justin Gardner (GPL see mgl/COPYING)
%    purpose: example program to show how to use seglenPrecompute feature
%
function myscreen = taskTemplateSeglenPrecompute(type)

% check arguments
if ~any(nargin == [0 1])
  help taskTemplate
  return
end
if nargin == 0
  type = 1;
end

% initalize the screen
myscreen = initScreen;

if type == 1
  task{1}.waitForBacktick = 0;
  task{1}.segmin = [3 1];
  task{1}.segmax = [3 6];
  task{1}.seglenPrecompute = 1;
  task{1}.random = 1;
  task{1}.numTrials = 10;
elseif type == 2
  task{1}.waitForBacktick = 1;
  task{1}.segmin = [3 1.5];
  task{1}.segmax = [3 6];
  task{1}.synchToVol = [0 1];
  task{1}.seglenPrecompute = 1;
  task{1}.seglenPrecomputeSettings.framePeriod = 1.5;
  task{1}.random = 1;
  task{1}.numTrials = 5;
elseif type == 3
  task{1}.segmin = [3 6];
  task{1}.segmax = [3 6];
  task{1}.segdur{3} = [1 3 7];
  task{1}.segprob{3} = [0.2 0.5 0.3];
  task{1}.seglenPrecompute = 1;
  task{1}.random = 1;
  task{1}.numTrials = 20;
elseif type == 4
  task{1}.seglenPrecompute.seglen{1} = [1 10];
  task{1}.seglenPrecompute.seglen{2} = [2 1];
  task{1}.seglenPrecompute.seglen{3} = [3 4];
  task{1}.seglenPrecompute.seglen{4} = [2 1 5];
  task{1}.seglenPrecompute.myVar = {'huh','wow','uhm','yowsa'};
  task{1}.random = 1;
  task{1}.numTrials = 8;
end  

% initialize the task
for phaseNum = 1:length(task)
  [task{phaseNum} myscreen] = initTask(task{phaseNum},myscreen,@startSegmentCallback,@screenUpdateCallback,@responseCallback);
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
if isempty(stimulus.starttime)
  stimulus.starttime = mglGetSecs;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function that gets called to draw the stimulus each frame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task myscreen] = screenUpdateCallback(task, myscreen)

global stimulus


mglClearScreen;
mglTextDraw(sprintf('Trial %i/%i',task.trialnum,task.numTrials),[0 8]);
mglTextDraw(sprintf('Segment %i',task.thistrial.thisseg),[0 4]);
mglTextDraw(sprintf('Segments: [%s]',num2str(task.thistrial.seglen,'%0.2f ')),[0 0]);
mglTextDraw(sprintf('Trial Length: %0.1f/%0.1f',mglGetSecs(task.thistrial.trialstart),sum(task.thistrial.seglen)),[0 -4]);
if isfield(task.seglenPrecompute,'totalLength')
  mglTextDraw(sprintf('Total Length: %0.1f/%0.1f',mglGetSecs(stimulus.starttime),task.seglenPrecompute.totalLength),[0 -8]);
else
  mglTextDraw(sprintf('Total Length: %0.1f',mglGetSecs(stimulus.starttime)),[0 -8]);
end
if isfield(task.seglenPrecompute,'numVolumes')
  mglTextDraw(sprintf('Volume number: %i/%i',myscreen.volnum,task.seglenPrecompute.numVolumes),[0 -12]);
end
if isfield(task.thistrial,'myVar')
  mglTextDraw(sprintf('myVar: %s',task.thistrial.myVar),[0 -12]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%
%    responseCallback    %
%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task myscreen] = responseCallback(task,myscreen)

global stimulus

% fix: add the code you want to use to process subject response

% here, we just check whether this is the first time we got a response
% this trial and display what the subject's response was and the reaction time
if task.thistrial.gotResponse < 1
  disp(sprintf('Subject response: %i Reaction time: %0.2fs',task.thistrial.whichButton,task.thistrial.reactionTime));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function to init the stimulus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function stimulus = myInitStimulus(stimulus,myscreen)


stimulus.starttime = [];