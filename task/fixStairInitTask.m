% fixStairInitTask.m
%
%        $Id$
%      usage: [fixTask myscreen] = fixStairInitTask(myscreen)
%         by: justin gardner
%       date: 09/07/06
%  copyright: (c) 2006 Justin Gardner (GPL see mgl/COPYING)
%    purpose: 
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
task{1}.segmentTrace = myscreen.stimtrace;
task{1}.phaseTrace = myscreen.stimtrace+1;
task{1}.responseTrace = myscreen.stimtrace+2;
myscreen.stimtrace = myscreen.stimtrace+3;

% don't save any info in the traces about the segments
% of this task
task{1}.segmentsTrace = 0;
task{1}.phaseTrace = 0;

% init the staircase
fixStimulus.staircase = upDownStaircase(fixStimulus.stairUp,fixStimulus.stairDown,fixStimulus.threshold,fixStimulus.stairStepSize,fixStimulus.stairUseLevitt);

% init the task
task{1} = initTask(task{1},myscreen,@fixStartSegmentCallback,@fixDrawStimulusCallback,@fixTrialResponseCallback,@fixTrialStartCallback);

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