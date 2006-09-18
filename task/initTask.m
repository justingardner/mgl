% initTask - initializes task for stimuli programs
%
%      usage: [ task ] = initTask( task, myscreen, startSegmentCallback, ...
%			 trialResponseCallback, trialStimulusCallback, ...
%			 endTrialCallback )
%        $Id$
%         by: justin gardner
%       date: 2006-04-27
%  copyright: (c) 2006 Justin Gardner (GPL see mgl/COPYING)
%     inputs: task, myscreen
%  callbacks:
%     -- function handles for callback functions --
%
%    [task myscreen] =
%      startSegmentCallback(task,myscreen)
%    Gets called at the beginning of each trial segment. The
%    variable settings for the trial are available in
%    task.thistrial (Mandatory)
%
%    [task myscreen] = drawStimulusCallback(task,myscreen)
%    Gets called on every display tick. Responsible for drawing the
%    stimulus to the screen  (Mandatory)
%
%    [task myscreen] = trialResponseCallback(task,myscreen)
%    Gets called if getResponse is set in the trial segment 
%    and the subject hits a response key. 
%
%    [task myscreen] = endTrialCallback(task,myscreen)
%    Gets called at end of trial
%
%    [task myscreen] = startBlockCallback(task,myscreen)
%    Gets called at beginning of block
%
%    outputs: task
%    purpose: initializes task for stimuli programs - you need to
%    write functions (and provide function handles to them) to
%    handle new tasks that you want to implement.
%
% 
function task = initTask(task, myscreen, startSegmentCallback, ...
			 drawStimulusCallback, trialResponseCallback,...
			 startTrialCallback, endTrialCallback, startBlockCallback)

if ~any(nargin == [4:8])
  help initTask;
  return
end

if ~isfield(task,'verbose')
  task.verbose = 1;
end

% check for parameters
if ~isfield(task,'parameter')
  error(sprintf('UHOH: No task parameters found'));
end

% find out how many parameters we have
task.parameterNames = fieldnames(task.parameter);
task.parameterN = length(task.parameterNames);
for i = 1:task.parameterN
  paramsize = eval(sprintf('size(task.parameter.%s)',task.parameterNames{i}));
  % check for column vectors
  if (paramsize(1) > 1) && (paramsize(2) == 1)
    if task.verbose
      disp(sprintf('Parameter %s is a column vector',task.parameterNames{i}));
    end
  end
  task.parameterSize(i,:) = eval(sprintf('size(task.parameter.%s)',task.parameterNames{i}));
end
task.parameterTotalN = prod(task.parameterSize(:,2));

% set up trial and block numbers
task.blocknum = 0;
task.thistrial.thisseg = inf;

% find out how many segments we have and
% check to see if they are specified correctly
if isfield(task,'seglen')
  if isfield(task,'segmin') || isfield(task,'segmax')
    disp(sprintf('UHOH: Found both seglen field and segmin/segmax. Using seglen'));
  end
  task.segmin = task.seglen;
  task.segmax = task.seglen;
end

if ~isfield(task,'segmin') || ~isfield(task,'segmax')
  error(sprintf('UHOH: Must specify task.segmin and task.segmax'));
  return
end

% look for seqment length quantization pramater, if it 
% is not set, default to 0. what this does is if you
% randomize times between segmin and segmax, it will
% give you a value that is quantized to this value.
% for example say we have;
% segmin = 1, segmax =5, segquant = 1.5
% then the random values that are possible are 1, 2.5, and 4
% if it is set to 0 then all random values  between 1 and 5 are possible
if ~isfield(task,'segquant') 
  task.segquant = zeros(1,length(task.segmin));
end

task.numsegs = length(task.segmin);
if length(task.segmin) ~= length(task.segmax)
  error(sprintf('UHOH: task.segmin and task.segmax not of same length\n'));
  return
end
if any((task.segmax - task.segmin) < 0)
  error(sprintf('UHOH: task.segmin not smaller than task.segmax\n'));
  return
end

% check task.writeTrace to see if it conforms to expectations
% make it extend to all segments
if ~isfield(task,'writeTrace'),task.writeTrace = {};,end
for i = (length(task.writeTrace)+1):task.numsegs
  task.writeTrace{i} = {};
end
% now make sure the writeTrace references existing variables
maxtracenum = -inf;
for i = 1:length(task.writeTrace)
  if isfield(task.writeTrace{i},'tracenum')
    % tracerow is optional
    if ~isfield(task.writeTrace{i},'tracerow')
      task.writeTrace{i}.tracerow = ones(1,length(task.writeTrace{i}.tracenum));
    end
    % usenum is optional
    if ~isfield(task.writeTrace{i},'usenum')
      task.writeTrace{i}.usenum = zeros(1,length(task.writeTrace{i}.tracenum));
    end
    % make traceval into a cell array if necessary
    if isstr(task.writeTrace{i}.tracevar)
      tracevarcell{1} = task.writeTrace{i}.tracevar;
      task.writeTrace{i}.tracevar = tracevarcell;
    end
    % now look for maximum and check variable and
    % row existence
    for j = 1:length(task.writeTrace{i}.tracenum)
      % look for maximum tracenum
      if task.writeTrace{i}.tracenum(j) > maxtracenum
	maxtracenum = task.writeTrace{i}.tracenum(j);
      end
      % see if variable called for exists
      thistracevar = task.writeTrace{i}.tracevar{j};
      if ~isfield(task.parameter,thistracevar)
	error(sprintf('UHOH: WriteTrace can not save variable %s (Does not exist)',thistracevar));
      end
      % see if tracerow is long enough
      thistracerow = task.writeTrace{i}.tracerow(j);
      thissize = eval(sprintf('size(task.parameter.%s,1);',thistracevar));
      if (thissize(1) < thistracerow)
	error(sprintf('UHOH: WriteTrace can not write row %i of variable %s',thistracerow,thistracevar));
      end
    end
  end
end
task.numstimtraces = maxtracenum;

% check get response
if ~isfield(task,'getResponse')
  task.getResponse = [];
end
for i = (length(task.getResponse)+1):task.numsegs
  task.getResponse(i) = 0;
end

% run infinite number of blocks if not specified
if ~isfield(task,'numBlocks')
  task.numBlocks = inf;
end

% run infinite number of trials if not specified
if ~isfield(task,'numTrials')
  task.numTrials = inf;
end

% check for waitForBacktick setting
if ~isfield(task,'waitForBacktick')
  task.waitForBacktick = 0;
end

% check for random
if ~isfield(task,'random')
  task.random =  0;
end

% check for time in ticks
if ~isfield(task,'timeInTicks')
  task.timeInTicks = 0;
end
% check for time in vols
if ~isfield(task,'timeInVols')
  task.timeInVols = 0;
end

% check for both
if task.timeInTicks && task.timeInVols
  disp(sprintf('UHOH: Time is both ticks and vols, setting to vols'));
  task.timeInTicks = 0;
end

% set how many total trials we have run
task.trialnumTotal = 0;

if ~isfield(task,'writeSegmentsTrace')
  task.writeSegmentsTrace = 4;
end

% set function handles
if exist('startSegmentCallback','var') && ~isempty(startSegmentCallback)
  task.callback.startSegment = startSegmentCallback;
end
if exist('trialResponseCallback','var') && ~isempty(trialResponseCallback)
  task.callback.trialResponse = trialResponseCallback;
end
if exist('drawStimulusCallback','var') && ~isempty(drawStimulusCallback)
  task.callback.drawStimulus = drawStimulusCallback;
end
if exist('endTrialCallback','var') && ~isempty(endTrialCallback)
  task.callback.endTrial = endTrialCallback;
end
if exist('startTrialCallback','var') && ~isempty(startTrialCallback)
  task.callback.startTrial = startTrialCallback;
end
if exist('startBlockCallback','var') && ~isempty(startBlockCallback)
  task.callback.startBlock = startBlockCallback;
end

% get calling name
[st,i] = dbstack;
task.taskfilename = st(max(i+1,length(st))).file;





