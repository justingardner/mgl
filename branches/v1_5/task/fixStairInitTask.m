% fixStairInitTask.m
%
%        $Id$
%      usage: [fixTask myscreen] = fixStairInitTask(myscreen)
%         by: justin gardner
%       date: 09/07/06
%  copyright: (c) 2006 Justin Gardner (GPL see mgl/COPYING)
%    purpose: Implements a fixation task. In this task, the fixation cross
%             starts out cyan and then darkens twice. The fixation cross then
%             turns yellow to indicate the response interval, and the subject
%             is required to press 1 or 2 to indicate in which interval the cross
%             appeared darker. The cross will then turn green or red to indicate
%             correct or incorrect responses. The dimness of the target is 
%             controlled by a 2 down 1 up staircase to keep task difficulty
%             the same. 
%
%             See testExperiment.m for how this is used in a task. If you want
%             to change parameters, before you call fixStairInitTask, set 
%             appropriate fields of the global variable fixStimulus. e.g.:
%
%             global fixStimulus
%             fixStimulus.interTime = 1;
%
%             See the code, for a list of all parameters that can be changed.
%
function [task myscreen] = fixStairInitTask(myscreen)

% check arguments
if ~any(nargin == [1])
  help fixDispStairInitTask
  return
end

% create the stimulus for the experiment, use defaults if they are
% not already set
global fixStimulus;
myscreen = initStimulus('fixStimulus',myscreen);
if ~isfield(fixStimulus,'threshold') fixStimulus.threshold = 0.5; end
if ~isfield(fixStimulus,'pedestal') fixStimulus.pedestal = 0.4; end
if ~isfield(fixStimulus,'stairUp') fixStimulus.stairUp = 1; end
if ~isfield(fixStimulus,'stairDown') fixStimulus.stairDown = 2; end
if ~isfield(fixStimulus,'stairStepSize') fixStimulus.stairStepSize = 0.05; end
if ~isfield(fixStimulus,'stairUseLevitt') fixStimulus.stairUseLevitt = 0; end
if ~isfield(fixStimulus,'stimColor') fixStimulus.stimColor = [0 1 1]; end
if ~isfield(fixStimulus,'responseColor') fixStimulus.responseColor = [1 1 0]; end
if ~isfield(fixStimulus,'interColor') fixStimulus.interColor = [0 1 1]; end
if ~isfield(fixStimulus,'correctColor') fixStimulus.correctColor = [0 1 0]; end
if ~isfield(fixStimulus,'incorrectColor') fixStimulus.incorrectColor = [1 0 0]; end
if ~isfield(fixStimulus,'traceNum') fixStimulus.traceNum = 5; end
if ~isfield(fixStimulus,'responseTime') fixStimulus.responseTime = 1; end
if ~isfield(fixStimulus,'stimTime') fixStimulus.stimTime = 0.2; end
if ~isfield(fixStimulus,'interTime') fixStimulus.interTime = 0.5; end
if ~isfield(fixStimulus,'diskSize') fixStimulus.diskSize = 1; end
if ~isfield(fixStimulus,'pos') fixStimulus.pos = [0 0]; end

% create a fixation task
task{1}.seglen = [fixStimulus.interTime fixStimulus.stimTime fixStimulus.interTime fixStimulus.stimTime fixStimulus.interTime fixStimulus.responseTime];
task{1}.getResponse = [0 0 0 0 0 1];
[task{1} myscreen] = addTraces(task{1}, myscreen, 'segment', 'phase', 'response')

% init the staircase
fixStimulus.staircase = upDownStaircase(fixStimulus.stairUp,fixStimulus.stairDown,fixStimulus.threshold,fixStimulus.stairStepSize,fixStimulus.stairUseLevitt);

% init the task
[task{1} myscreen] = initTask(task{1},myscreen,@fixStartSegmentCallback,@fixDrawStimulusCallback,@fixTrialResponseCallback,@fixTrialStartCallback);

% keep the correct and incorrect counts
task{1}.correct = 0;
task{1}.incorrect = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function that gets called at the start of each segment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task myscreen] = fixTrialStartCallback(task, myscreen)

global fixStimulus;
% choose stimulus interval
task.thistrial.sigInterval = 1+(rand > 0.5);
disp(sprintf('sigint = %i threshold = %0.2f',task.thistrial.sigInterval,fixStimulus.threshold));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function that gets called at the start of each segment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task myscreen] = fixStartSegmentCallback(task, myscreen)

global fixStimulus;

% choose what color the fixation cross will be
whichInterval = find(task.thistrial.thisseg == [2 4]);
% if this is the signal interval
if ~isempty(whichInterval)
  if task.thistrial.sigInterval == whichInterval
    fixStimulus.thisStrength = (1-(fixStimulus.pedestal+fixStimulus.threshold));
  else
    fixStimulus.thisStrength = (1-fixStimulus.pedestal);
  end
  fixStimulus.thisColor = fixStimulus.stimColor*fixStimulus.thisStrength;
  % write out what the strength is
  myscreen = writeTrace(fixStimulus.thisStrength,fixStimulus.traceNum,myscreen);
% if this is the response interval
elseif task.thistrial.thisseg == 6
  fixStimulus.thisColor = fixStimulus.responseColor;
% if this is the inter stimulus interval
else
  fixStimulus.thisColor = fixStimulus.interColor;
  myscreen = writeTrace(0,fixStimulus.traceNum,myscreen);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function that gets called every frame udpate to draw the fixation 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task myscreen] = fixDrawStimulusCallback(task, myscreen)

global fixStimulus;
mglGluDisk(fixStimulus.pos(1),fixStimulus.pos(2),fixStimulus.diskSize*[1 1],myscreen.background,60);

mglFixationCross(0.5,1,fixStimulus.thisColor,fixStimulus.pos);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function that gets called when subject responds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task myscreen] = fixTrialResponseCallback(task, myscreen)

global fixStimulus;

% get correct or incorrect
response = find(task.thistrial.buttonState) == task.thistrial.sigInterval;
response = response(1);

if response
  % set to correct fixation color
  fixStimulus.thisColor = fixStimulus.correctColor;
  % set trace to 2 to indicate correct response
  myscreen = writeTrace(2,fixStimulus.traceNum,myscreen);
  % and update correct count
  task.correct = task.correct+1;
else
  % set to incorrect fixation color
  fixStimulus.thisColor = fixStimulus.incorrectColor;
  % set trace to -2 to indicate incorrect response
  myscreen = writeTrace(-2,fixStimulus.traceNum,myscreen);
  % and update incorrect count
  task.incorrect = task.incorrect+1;
end

% update staircase
fixStimulus.staircase = upDownStaircase(fixStimulus.staircase,response);
fixStimulus.threshold = fixStimulus.staircase.threshold;