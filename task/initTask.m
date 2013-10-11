% initTask - initializes task for stimuli programs
%
%      usage: [ task myscreen ] = initTask( task, myscreen, startSegmentCallback, ...
%			 screenUpdateCallback, <trialResponseCallback>, ...
%			 <startTrialCallback>, <endTrialCallback>, <startBlockCallback>,...
%                        <randCallback>);
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
%    [task myscreen] = screenUpdateCallback(task,myscreen)
%    Gets called on every display tick. Responsible for drawing the
%    stimulus to the screen for stimuli that are update every frame
%    (Mandatory)
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
%    block = randCallback(paramaters,block,previousBlock,task);
%    gets called at beginning of block to randomize parameters
%
%    outputs: task
%    purpose: initializes task for stimuli programs - you need to
%    write functions (and provide function handles to them) to
%    handle new tasks that you want to implement.
%
% 
function [task myscreen] = initTask(task, myscreen, startSegmentCallback, ...
				    screenUpdateCallback, trialResponseCallback,...
				    startTrialCallback, endTrialCallback, startBlockCallback,...
				    randCallback);

if ~any(nargin == [4:10])
  help initTask;
  return
end

if nargout ~= 2
  disp(sprintf('(initTask) You must accept the return variables task & myscreen from initTask'));
  help initTask;
end

if ~isfield(task,'verbose')
  task.verbose = 1;
end

% check for capitalization errors
knownFieldnames = ...
    {'verbose', ...
     'parameter', ...
     'seglen', ...
     'segmin', ...
     'segmax', ...
     'segquant', ...
     'segdur',...
     'segprob',...
     'segnames', ...
     'seglenPrecompute',...
     'seglenPrecomputeSettings',...
     'synchToVol', ...
     'writeTrace', ...
     'getResponse', ...
     'numBlocks', ...
     'numTrials', ...
     'waitForBacktick', ...
     'random', ...
     'timeInTicks', ...
     'timeInVols', ...
     'segmentTrace', ...
     'responseTrace', ...
     'phaseTrace', ...
     'parameterCode', ...
     'private', ...
     'randVars', ...
     'fudgeLastVolume', ...
     'collectEyeData',...
    };

taskFieldnames = fieldnames(task);
for i = 1:length(taskFieldnames)
  matches = find(strcmp(upper(taskFieldnames{i}),upper(knownFieldnames)));
  if  matches & ~any(strcmp(taskFieldnames{i},knownFieldnames))
    disp(sprintf('(initTask) task.%s is miscapitalized. Changed to task.%s.',taskFieldnames{i},knownFieldnames{matches}));
    fieldval = eval(sprintf('task.%s',taskFieldnames{i}));
    task = rmfield(task,taskFieldnames{i});
    eval(sprintf('task.%s = fieldval;',knownFieldnames{matches}));
  elseif isempty(matches)
    disp(sprintf('Unknown task field: task.%s',taskFieldnames{i}));
  end
end

% check for parameters
if ~isfield(task,'parameter')
  task.parameter.default = 1;
end

% set up trial and block numbers
task.blocknum = 0;
task.thistrial.thisseg = inf;

% keep the task randstate. Note that initScreen initializes the
% state of the random generator to a random value (set by clock)
% each time, guaranteeing a different random sequence. 
% Note that the updateTask code switches the rand state
% back and forth between the blockState / trialState at
% the appropriate times to make sure that *if* the randstate
% set by initScreen is set the same as a previous run, we
% get exactly the same sequence of random numbers for
% the blocks and trials (regardless of what the user is
% doing inside their callbacks -- which will have a different
% rand number state).
% set the randstate type
task.randstate.type = myscreen.randstate.type;
% init the random sequence for this task
task.randstate.state = floor((2^32-1)*rand);
% initialize the block randomization sequence. This is used so that
% you can always guarantee the same parameter sequence
task.randstate.blockState = floor((2^32-1)*rand);
% initialize the trial randomization sequence. This is used so that
% you can always guarantee the same segment lengths
task.randstate.trialState = floor((2^32-1)*rand);

% set the random state
randstate = rand(myscreen.randstate.type);
rand(task.randstate.type,task.randstate.state);

% see if seglen has been precomputed
if isfield(task,'seglenPrecompute')  && isstruct(task.seglenPrecompute)
  % then validate the structure
  task = seglenPrecomputeValidate(task);
else
  % find out how many segments we have and
  % check to see if they are specified correctly
  if isfield(task,'seglen')
    if isfield(task,'segmin') || isfield(task,'segmax')
      disp(sprintf('(initTask) Found both seglen field and segmin/segmax. Using seglen'));
    end
    task.segmin = task.seglen;
    task.segmax = task.seglen;
  end

  if ~isfield(task,'segmin') || ~isfield(task,'segmax')
    disp(sprintf('(initTask) Must specify task.segmin and task.segmax'));
    keyboard
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
  elseif length(task.segquant) < length(task.segmin)
    task.segquant(end+1:length(task.segmin)) = 0;
  end
  if ~isfield(task,'synchToVol')
    task.synchToVol = zeros(1,length(task.segmin));
  elseif length(task.synchToVol) < length(task.segmin)
    % if sycnhToVol is not long enough, pad it out with 0s
    task.synchToVol(end+1:length(task.segmin)) = 0;
  end
  
  % check for segdur - segdur allows one to set 
  % an array of possible durations
  if ~isfield(task,'segdur') || (length(task.segdur) < length(task.segmin))
    task.segdur{length(task.segmin)} = [];
  % check length
  elseif length(task.segdur) > length(task.segmin)
    task.segmin(end+1:length(task.segdur)) = nan;
    task.segmax(end+1:length(task.segdur)) = nan;
    if length(task.segquant) < length(task.segmin)
      task.segquant(end+1) = 0;
    end
    if length(task.synchToVol) < length(task.segmin)
      task.synchToVol(end+1) = 0;
    end
  end
  % check for segprob
  if ~isfield(task,'segprob') || (length(task.segprob) < length(task.segmin))
    task.segprob{length(task.segmin)} = [];
  end
  
  % check matching segdur / segprob and segmin
  for iSeg = 1:length(task.segmin)
    % check if there isa segdur
    if ~isempty(task.segdur{iSeg})
      % check for matching freq
      if isempty(task.segprob{iSeg})
	% no matching frequency. set to equal frequencies
	task.segprob{iSeg} = repmat(1/length(task.segdur{iSeg}),1,length(task.segdur{iSeg}));
      elseif length(task.segprob{iSeg})~=length(task.segdur{iSeg})
	disp(sprintf('(initTask) segprob{%i} must have the same number of elements as segdur{%i}',iSeg,iSeg));
	keyboard
      elseif round(10000*sum(task.segprob{iSeg}))/10000 ~= 1
	disp(sprintf('(initTask) segprob{%i} must add up to 1',iSeg));
	keyboard
      end
      % set segmin/segmax to nan
      task.segmin(iSeg) = nan;
      task.segmax(iSeg) = nan;
      % make probabilities
      task.segprob{iSeg} = cumsum(task.segprob{iSeg});
      task.segprob{iSeg} = [0 task.segprob{iSeg}(1:end-1)];
    elseif ~isempty(task.segprob{iSeg})
      disp(sprintf('(initTask) Non-empty segprob{%i} for empty segdur{%i}',iSeg,iSeg));
      keyboard
    elseif isnan(task.segmin(iSeg))
      disp(sprintf('(initTask) Segmin is nan without a segdur{%i}',iSeg));
      keyboard
    end
  end

  % now implement segquant using segdur and segprob
  for iSeg = 1:length(task.segquant)
    if task.segquant(iSeg) ~= 0
      if isempty(task.segdur{iSeg})
	task.segdur{iSeg} = task.segmin(iSeg):task.segquant(iSeg):task.segmax(iSeg);
	task.segprob{iSeg} = cumsum(ones(1,length(task.segdur{iSeg}))/length(task.segdur{iSeg}));
	task.segprob{iSeg} = [0 task.segprob{iSeg}(1:end-1)];
	task.segquant(iSeg) = 0;
	task.segmin(iSeg) = nan;
	task.segmax(iSeg) = nan;
      end
    end
  end

  task.numsegs = length(task.segmin);
  if length(task.segmin) ~= length(task.segmax)
    error(sprintf('(initTask) task.segmin and task.segmax not of same length\n'));
    return
    end
  if any((task.segmax - task.segmin) < 0)
    error(sprintf('(initTask) task.segmin not smaller than task.segmax\n'));
    return
  end

  % if we have specified segment names, setup the index
  if isfield(task, 'segnames') 
    if numel(task.segnames) ~= task.numsegs
      error(sprintf('(initTask) task.segnames does not match the number of segments\n'));
    else
      for nSeg = 1:task.numsegs
	task.segndx.(task.segnames{nSeg}) = ...
	    strmatch(task.segnames{nSeg}, task.segnames);
      end
    end
  end
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
  disp(sprintf('(initTask) Time is both ticks and vols, setting to vols'));
  task.timeInTicks = 0;
end

% just warn if user has a writeTrace field. It is no longer necessary
if isfield(task,'writeTrace') || isfield(task,'writetrace')
  disp(sprintf('(initTask) There is no longer any need to use writeTrace. All variable settings are correctly stored in the task variables and can be extracted after the experiment using getTaskParameters. The passed in writeTrace field will be ignored'));
end

% here we deal with randVars (see wiki for how to use randVars). The randVars
% are independent random variables from parameters. Note that this code allows
% two different ways of setting them up (either as block or uniform). But it
% is written in a way to be extensible. (look at the functions blockRandomization
% and uniformRandomization). All the variable values are precomputed, so you 
% have to specify how long to precompute them for.
% there is an extension to randVars to deal with user calculated (random)
% variables that have trial-to-trial dependencies (e.g. a random hazard 
% function that depends on user choice). this field uses the calculated
% field to setup these variables, which are then made availible as they
% are initialized to the user, and then they are saved at the end of each
% trial
randTypes = {'block','uniform', 'calculated'};
% compute stuff for random variables
task.randVars.n_ = 0;
task.randVars.calculated_n_ = 0;

% default to computing a length of 250
if ~isfield(task.randVars,'len_')
  if isfield(task,'numTrials') && isfinite(task.numTrials)
    task.randVars.len_ = max(task.numTrials,250);;
  else
    task.randVars.len_ = 250;
  end
end
% check the variable names for known randomization types
randVarNames = fieldnames(task.randVars);
originalNames = {};shortNames = {};
for i = 1:length(randVarNames)
  % if we got one, then first initialize the randomization procedure
  if any(strcmp(randVarNames{i},randTypes))
    vars = [];
    disp(sprintf('(initTask) Computing randVars with %sRandomization.m',randVarNames{i}));
    % we first loop over the length of the array, this is so
    % that, in the case of block, for example, we can have
    % randVars.block{1...n} so that we can have groups of blocked params
    % if the variable is not already a cell array then make a
    % cell array
    thisRandVar = {};
    if ~iscell(eval(sprintf('task.randVars.%s',randVarNames{i})))
      thisRandVar{1} = eval(sprintf('task.randVars.%s',randVarNames{i}));
      thisIsCell = 0;
    else
      thisRandVar = eval(sprintf('task.randVars.%s',randVarNames{i}));
      thisIsCell = 1;
    end
    for varNum = 1:length(thisRandVar)
      eval(sprintf('vars = %sRandomization(thisRandVar{varNum});',randVarNames{i}));
      % compute blocks of trials until we have enough
      varBlock = [];totalTrials = 0;
      % init variables
      for vnum = 1:vars.n_
	eval(sprintf('task.randVars.%s = [];',vars.names_{vnum}));
        % now get original names, i.e. shortNames is just the name of the variable: e.g. varname
	% originalNames is the full name e.g.: task.randVars.calculated.varname 
	if thisIsCell
	  shortNames{end+1} = vars.names_{vnum};
	  originalNames{end+1} = sprintf('task.randVars.%s{%i}.%s',randVarNames{i},varNum,vars.names_{vnum});
	else
	  shortNames{end+1} = vars.names_{vnum};
	  originalNames{end+1} = sprintf('task.randVars.%s.%s',randVarNames{i},vars.names_{vnum});
	end
      end
      % now keep calculating blocks of the randvars until we have enough. That is, we use the
      % routine xxxxRandomization to compute each block of the stimulus. So, for example
      % if we are using blockRandomization - then blockRandomization gets called to 
      % initialize a number of blocks. This is done to precompute blocks at the beginning which
      % results in time savings when running since we have precomputed arrays that don't grow with each 
      % trial (until we run out of precomputed blocks - in which case the system goes back to the
      % beginning of the list of precomputed blocks and starts over - so, if you need to insure
      % that you have enough precomputed trials, you will need to set the len_ parameter for your
      % variable longer.
      while totalTrials < task.randVars.len_
	eval(sprintf('varBlock = %sRandomization(vars,varBlock);',randVarNames{i}));
	totalTrials = totalTrials+varBlock.trialn;
	for vnum = 1:vars.n_
	  eval(sprintf('task.randVars.%s = [task.randVars.%s varBlock.parameter.%s];',vars.names_{vnum},vars.names_{vnum},vars.names_{vnum}));
	end
      end
    end
    % we need this to rapidly iterate and copy the calculated vals
    if strcmp(randVarNames{i},'calculated')
      task.randVars.calculated_n_ = vars.n_;
      task.randVars.calculated_names_ = vars.names_;
    end
  end
end

% check to make sure that we don't use a reserved variable name
reservedVarNames = {'thisphase','thisseg','gotResponse','segstart','startvolnum','seglen','waitForBacktick','buttonState','waitingToInit','trialstart','synchVol','segStartSeconds','whichButton','reactionTime'};
conflictNames = intersect(lower(reservedVarNames),lower(shortNames));
if ~isempty(conflictNames)
  for i = 1:length(conflictNames)
    disp(sprintf('(initTask) ****%s randVar name conflicts with a reserved name****',conflictNames{i}));
  end
  keyboard
end

% now go through all of our variables and make a list of names
% and store how long they are
randVarNames = fieldnames(task.randVars);
for i = 1:length(randVarNames)
  % check if it is a random variable
  if ~any(strcmp(randVarNames{i},randTypes)) && isempty(regexp(randVarNames{i},'_$'))
    task.randVars.n_ = task.randVars.n_+1;
    task.randVars.names_{task.randVars.n_} = randVarNames{i};
    task.randVars.varlen_(task.randVars.n_) = eval(sprintf('length(task.randVars.%s)',randVarNames{i}));
    if any(strcmp(randVarNames{i},shortNames))
      task.randVars.originalName_{task.randVars.n_} = originalNames{find(strcmp(randVarNames{i},shortNames))};
    else
      task.randVars.originalName_{task.randVars.n_} = sprintf('task.randVars.%s',randVarNames{i});
    end      
  end
end

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
task.parameter.doRandom_ = task.random;

% set how many total trials we have run (trialnumTotal is there for
% compatibility, but doesn't get set anymore)
task.trialnum = 1;
task.trialnumTotal = 0;

% update, how many tasks we have seen
myscreen.numTasks = myscreen.numTasks+1;
task.taskID = myscreen.numTasks;

% now set the segment trace
%% NOTE: Should this be generalized to simply use addTraces for
%%       all tasks including the first task? What code is dependent
%%       on the explicit numbering for a single task? Note then the
%%       duplicate check for the existance of the field would be
%%       unnecessary.
if ~isfield(task,'segmentTrace')
  if myscreen.numTasks == 1
    task.segmentTrace = 2;
  else
    [task myscreen] = addTraces(task, myscreen, 'segment');
  end
end
if ~isfield(task,'responseTrace')
  if myscreen.numTasks == 1
    task.responseTrace = 3;
  else
    [task myscreen] = addTraces(task, myscreen, 'response');
  end
end
if ~isfield(task,'phaseTrace')
  if myscreen.numTasks == 1
    task.phaseTrace = 4;
  else
    [task myscreen] = addTraces(task, myscreen, 'phase');
  end
end

% write out starting phase
myscreen = writeTrace(1,task.phaseTrace,myscreen);

% set function handles
if exist('startSegmentCallback','var') && ~isempty(startSegmentCallback)
  task.callback.startSegment = startSegmentCallback;
end
if exist('trialResponseCallback','var') && ~isempty(trialResponseCallback)
  task.callback.trialResponse = trialResponseCallback;
end
if exist('screenUpdateCallback','var') && ~isempty(screenUpdateCallback)
  task.callback.screenUpdate = screenUpdateCallback;
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
if exist('randCallback','var') && ~isempty(randCallback)
  task.callback.rand = randCallback;
else
  task.callback.rand = @blockRandomization;
end
% default to assuming we are not collecting data for this task/phase
if ~isfield(task, 'collectEyeData')
  task.collectEyeData = false;
elseif ~isequal(task.collectEyeData,false)
  % if we are "collecting eye data" on a task, then we 
  % should shut down myscreens collectEyeData which
  % collects eye data for all tasks rather than each
  % task specifically. 
  myscreen.eyetracker.collectEyeData = false;
end

% initialize the parameters
task.parameter = feval(task.callback.rand,task.parameter);

% if seglenPrecompute is set to true then we set it up
if isfield(task,'seglenPrecompute') 
  if ~isstruct(task.seglenPrecompute)
    task = seglenPrecompute(task);
  end
else
  % otherwise turn it off
  task.seglenPrecompute = false;
end

% get calling name
if ~isfield(task,'taskFilename')
  [st,i] = dbstack;
  task.taskFilename = st(min(i+1,length(st))).file;
end
% if we can find the file (we should be able to)
% load the task listing into the task variables
% so that we have a record of what *exactly*
% was run
ftask = fopen(which(task.taskFilename),'r');
if (ftask ~= -1)
  task.taskFileListing = fread(ftask,inf,'*char')';
  fclose(ftask);
end

% init thistrial
task.thistrial = [];

% init the time discrepancy to 0
task.timeDiscrepancy = 0;

% there are situations in which for the trial in the sequence
% we are waiting for a volume to end the trial, but will never
% get one since the scan is over. Yet, we still want to end the
% trial to end the experiment, so we are going to have fudge
% on the last volume. Default is not to, the user can turn this off
if ~isfield(task,'fudgeLastVolume')
  task.fudgeLastVolume = 0;
end

% remember the status of the random number generator
% and reset it to what it was before this call
task.randstate.state = rand(task.randstate.type);
rand(myscreen.randstate.type,randstate);

% set the debug mode to stop on error
dbstop('if','error');


%%%%%%%%%%%%%%%%%%%%%%%%%%
%    seglenPrecompute    %
%%%%%%%%%%%%%%%%%%%%%%%%%%
function task = seglenPrecompute(task)


% this sets up the seglenPrecompute


% segmin/segmax/seglen/segquant/synchToVol have already
% been validated. So base the precomputed seglen on these
% values
task.seglenPrecompute = [];
if ~isfield(task,'seglenPrecomputeSettings')
  task.seglenPrecomputeSettings = [];
end

% default to equal frequency computation. What this does is everywhere
% there is a segquant or a synchToVol it assigns equal probabilities
% defaults
settingsDefaults = {{'synchWaitBeforeTime',0.1},{'verbose',1},{'averageLen',[]},{'numTrials',[]},{'maxTries',500},{'idealDiffFromIdeal',[]}};

for iSettings = 1:length(settingsDefaults)
  % get this setting
  settingsName = settingsDefaults{iSettings}{1};
  settingsDefault = settingsDefaults{iSettings}{2};
  % and set default if it is no already set
  if ~isfield(task.seglenPrecomputeSettings,settingsName) || isempty(task.seglenPrecomputeSettings.(settingsName))
    task.seglenPrecomputeSettings.(settingsName) = settingsDefault;
  end
end

% grab some settings from the sturcture = just so they are easier to reference
for iSettings = 1:length(settingsDefaults)
  settingsName = settingsDefaults{iSettings}{1};
  eval(sprintf('%s = task.seglenPrecomputeSettings.%s;',settingsName,settingsName));
end

% see if any synchToVol is set.
synchToVol = any(task.synchToVol);
if synchToVol
  % make sure the last one is set otherwise it will be
  % hard to compute what will happen (since each trial will
  % start at some unknown time relative to the beginning
  % of a volume - why would you even want this?)
  if ~task.synchToVol(end)
    disp(sprintf('(initTask:seglenPrecompute) You have not set the last segment to have synchToVol (though other segments do have synchToVol set). Can not precompute the seglens. Usually you should have your last segment synchToVol so that the start of the trial is synched to acquisition. If you cannot arrange this, then you will need to precompute your own seglens.\n!!!! Not precomputing segments !!!!'));
    keyboard
    return
  end
  % chceck to see if frame period
  if ~isfield(task.seglenPrecomputeSettings,'framePeriod')
    disp(sprintf('(initTask:seglenPrecompute) You have set seglenPrecompute, and you have synchToVol. To compute the lengths of trials, initTask needs to know the framePeriod (the time each volume takes - i.e. how often you get an acquisition pulse from the magnet - sometimes every TR). Set the filed task.seglenPrecomputeSettings.framePeriod.\n!!! Not precomputing segments !!!'));
    keyboard
    return
  end
  framePeriod = task.seglenPrecomputeSettings.framePeriod;
  % set the fudgeLastVol setting so that the task will end
  if ~isfield(task,'fudgeLastVolume') || isempty(task.fudgeLastVolume)
    task.fudgeLastVolume = true;
  end
else
  framePeriod = nan;
end

% compute average length of trial unless we are passed in one
if isempty(averageLen)
  % now we are going to figure out all possibilities for how long
  % a trial should take. If there is no quantization or synchTovol
  % then this is just a range from min to max. But if we do, then
  % essentially there are a set of possibliites 
  nSegs = length(task.segmin);
  trialLens(1).freq = 1;
  trialLens(1).min = 0;
  trialLens(1).max = 0;
  trialLens(1).segmin = [];
  trialLens(1).segmax = [];
  trialLens(1).synchmin = [];
  trialLens(1).synchmax = [];
  for iSeg = 1:nSegs
    % if this has no seg quant
    if isnan(task.segmin(iSeg))
      % nan means to choose from the segdur with segprob, so create one trialLen for each of these possiblitites
      newTrialLens = [];
      segprob = diff([task.segprob{iSeg} 1]);
      for iTrialLen = 1:length(trialLens)
	for iSegdur = 1:length(task.segdur{iSeg})
	  % copy old structure
	  if isempty(newTrialLens)
	    newTrialLens = trialLens(iTrialLen);
	  else
	    newTrialLens(end+1) = trialLens(iTrialLen);
	  end
	  % and add this probability
	  newTrialLens(end).segmin(end+1) = task.segdur{iSeg}(iSegdur);
	  newTrialLens(end).segmax(end+1) = task.segdur{iSeg}(iSegdur);
	  newTrialLens(end).synchmin(end+1) = task.segdur{iSeg}(iSegdur);
	  newTrialLens(end).synchmax(end+1) = task.segdur{iSeg}(iSegdur);
	  % compute probability
	  newTrialLens(end).freq = newTrialLens(end).freq*segprob(iSegdur);
	  % set min and max
	  newTrialLens(end).min = newTrialLens(end).min + task.segdur{iSeg}(iSegdur);
	  newTrialLens(end).max = newTrialLens(end).max + task.segdur{iSeg}(iSegdur);
	end
      end
      trialLens = newTrialLens;
    elseif task.segquant(iSeg) == 0
      % just add the segmin and segmax on to each min / max trial len
      for iTrialLen = 1:length(trialLens)
	trialLens(iTrialLen).min = trialLens(iTrialLen).min + task.segmin(iSeg);
	trialLens(iTrialLen).max = trialLens(iTrialLen).max + task.segmax(iSeg);
	% add add on this segmin and segmax 
	trialLens(iTrialLen).segmin(end+1) = task.segmin(iSeg);
	trialLens(iTrialLen).segmax(end+1) = task.segmax(iSeg);
	trialLens(iTrialLen).synchmin(end+1) = task.segmin(iSeg);
	trialLens(iTrialLen).synchmax(end+1) = task.segmax(iSeg);
      end
    else
      % if the segments are quantized then break into each possibility
      % figure out all possible quantizations
      segLens = task.segmin(iSeg):task.segquant(iSeg):task.segmax(iSeg);
      if segLens(end) ~= task.segmax(iSeg)
	segLens(end+1) = task.segmax(iSeg);
      end
      % add a trialLens struct for each of these possibilities
      newTrialLens = [];
      for iTrialLen = 1:length(trialLens)
	% used for computing probability
	thisSegLenMin = task.segmin(iSeg);
	thisSegLen = (task.segmax(iSeg)-task.segmin(iSeg));
	for iSegLen = 1:length(segLens)
	  if isempty(newTrialLens)
	    newTrialLens = trialLens(iTrialLen);
	  else
	    newTrialLens(end+1) = trialLens(iTrialLen);
	  end
	  % compute the frequency with which this will happen
	  if thisSegLen > 0
	    thisSegLenMax = min(thisSegLenMin+task.segquant(iSeg),task.segmax(iSeg));
	    freq = (thisSegLenMax-thisSegLenMin)/thisSegLen;
	    thisSegLenMin = thisSegLenMax;
	  else
	    freq = 1;
	  end
	  newTrialLens(end).freq = newTrialLens(end).freq*freq;
	  % and add to the whole length of the trial
	  newTrialLens(end).min = newTrialLens(end).min+segLens(iSegLen);
	  newTrialLens(end).max = newTrialLens(end).max+segLens(iSegLen);
	  % and add the segmin / segmax
	  newTrialLens(end).segmin(end+1) = segLens(iSegLen);
	  newTrialLens(end).segmax(end+1) = segLens(iSegLen);
	  newTrialLens(end).synchmin(end+1) = segLens(iSegLen);
	  newTrialLens(end).synchmax(end+1) = segLens(iSegLen);
	end
      end
      trialLens = newTrialLens;
    end
    % now handle the synchToVol setting
    if task.synchToVol(iSeg)
      newTrialLens = [];
      % go through each possible trialLen and quantize
      for iTrialLen = 1:length(trialLens)
	% figure out what synchToVols you would get
	% (This assumes that the trial started on a volume
	% acquisition - which is why we force the trial
	% to end on a synchToVol - but note that synchToVol
	% can happen any segment within a trial as well
	minLen = trialLens(iTrialLen).min;
	maxLen = trialLens(iTrialLen).max;
	segLens = ceil(minLen/framePeriod)*framePeriod:framePeriod:ceil(maxLen/framePeriod)*framePeriod;
	segLensProbCompute = [minLen segLens];
	% make a new trial len for each of these seglens
	for iSegLen = 1:length(segLens)
	  if isempty(newTrialLens)
	    newTrialLens = trialLens(iTrialLen);
	  else
	    newTrialLens(end+1) = trialLens(iTrialLen);
	  end
	  % set the length of the trial
	  newTrialLens(end).min = segLens(iSegLen);
	  newTrialLens(end).max = segLens(iSegLen);
	  % compute frequency
	  % do actual computation of frequency - this looks at how often the amount of
	  % time before each synchToVol happens will actually occur is and divides
	  % by the full possible lengths of the segment. Get the segmin/segmax
	  if sum(newTrialLens(end).synchmin) == sum(newTrialLens(end).synchmax)
	    freq = 1;
	  else
	    freq = computeLenProb(newTrialLens(end).synchmin,newTrialLens(end).synchmax,segLensProbCompute(iSegLen),segLensProbCompute(iSegLen+1));
	  end
	  newTrialLens(end).freq = newTrialLens(end).freq*freq;
	  % and change the segmin segmax to account for the extra time needed to wait for synch
	  synchWaitTime = newTrialLens(end).max-sum(newTrialLens(end).segmin);
	  % set synchWaitTime back a fudge factor (synchWaitBeforeTime seconds) so that the segment
	  % has enough time to wait for the synch pulse
	  synchWaitTime = max(synchWaitTime-synchWaitBeforeTime,0);
	  newTrialLens(end).segmin(end) = newTrialLens(end).segmin(end)+synchWaitTime;
	  % set segmax to segmin since for synchToVol we are computing a different
	  % trial type for each possible synchToVol length
	  newTrialLens(end).segmax(end) = newTrialLens(end).segmin(end);
	  % now reset synchmin / synchmax
	  newTrialLens(end).synchmin = newTrialLens(end).min;
	  newTrialLens(end).synchmax = newTrialLens(end).max;
	end
      end
      trialLens = newTrialLens;
    end
  end

  % compute the average length a trial should take
  averageLen = 0;actualNumTrials = 0;
  for iTrialLen = 1:length(trialLens)
    averageLen = averageLen + trialLens(iTrialLen).freq*(trialLens(iTrialLen).max+trialLens(iTrialLen).min)/2;
  end

  % display what is going on
  if verbose>1
    for iTrialLen = 1:length(trialLens)
      % display the seglens
      seglenStr = sprintf('seglen=[');
      for iSeg = 1:length(trialLens(iTrialLen).segmin)
	% add synchWaitBeforeTime (the fudge factor)
	if task.synchToVol(iSeg)
	  seglen = trialLens(iTrialLen).segmin(iSeg)+synchWaitBeforeTime;
	  % and display with a * for synchToVol
	  seglenStr = sprintf('%s*%0.2f ',seglenStr,seglen);
	else
	  % display the seglen
	  if trialLens(iTrialLen).segmin(iSeg) == trialLens(iTrialLen).segmax(iSeg)
	    seglenStr = sprintf('%s%0.2f ',seglenStr,trialLens(iTrialLen).segmax(iSeg));
	  else
	    seglenStr = sprintf('%s%0.2f-%0.2f ',seglenStr,trialLens(iTrialLen).segmin(iSeg),trialLens(iTrialLen).segmax(iSeg));
	  end
	end
      end
      seglenStr = sprintf('%s]',seglenStr(1:end-1));

      % display for trial length
      if trialLens(iTrialLen).min == trialLens(iTrialLen).max
	trialLenStr = sprintf('trialLen: %f',trialLens(iTrialLen).min);
      else
	trialLenStr = sprintf('trialMin: %f trialMax: %f',trialLens(iTrialLen).min,trialLens(iTrialLen).max);
      end
      % display for frequency
      trialFreqStr = sprintf('frequency: %f',trialLens(iTrialLen).freq);
      % display
      disp(sprintf('(initTask:seglenPrecompute) %s %s %s',trialLenStr,seglenStr,trialFreqStr));
    end
  end
end

% figure out how many trials to precompute for
if isempty(numTrials)
  if isfield(task,'numTrials') && ~isempty(task.numTrials) && ~isinf(task.numTrials)
    numTrials = task.numTrials;
  elseif isfield(task,'numBlocks') && ~isempty(task.numBlocks) && isinf(task.numTrials)
    numTrials = task.numBlocks * task.parameter.totalN_;
  else
    disp(sprintf('(initTask:seglenPrecompute) Must set number of trials to precompute either by task.seglenPrecompute.numTrials, task.numTrials or task.numBlocks'));
    keyboard
  end
end

disp(sprintf('(initTask) Computing %i trials with average length %f',numTrials,averageLen));

% we were asked for a number of trials
for iTrial = 1:numTrials
  % compute length for each trial
  [seglen task] = getTaskSeglen(task);
  % compute trial length and adjust any segments that are synchToVol to allow at least 
  % synchWaitBeforeTime till the synch happens
  [trialLength(iTrial) seglen] = computeTrialLen(seglen,task.synchToVol,framePeriod,synchWaitBeforeTime);
  % and remember seglen
  task.seglenPrecompute.seglen{iTrial} = seglen;
end

% set the random state
randstate = rand(task.randstate.type);
rand(task.randstate.type,task.randstate.trialState);

% adjust trials until we have a match
diffFromIdeal = numTrials*averageLen-sum(trialLength);
% compute how close we should be (generally less than a framePeriod
if isempty(idealDiffFromIdeal)
  if ~isnan(framePeriod)
    idealDiffFromIdeal = framePeriod/2;
  else
    idealDiffFromIdeal = 1;
  end
end

nTries = 0;
while abs(diffFromIdeal) > idealDiffFromIdeal
  % choose a random trial
  randTrialNum = ceil(rand*numTrials);
  % compute new segment lengths
  [seglen task] = getTaskSeglen(task);
  [newTrialLength seglen] = computeTrialLen(seglen,task.synchToVol,framePeriod,synchWaitBeforeTime);
  newDiffFromIdeal = numTrials*averageLen-(sum(trialLength([1:(randTrialNum-1) (randTrialNum+1):end]))+newTrialLength);
  % only accept change if it reduces error
  if (abs(newDiffFromIdeal) < abs(diffFromIdeal)) || (rand < 0.1)
    trialLength(randTrialNum) = newTrialLength;
    task.seglenPrecompute.seglen{randTrialNum} = seglen;
    diffFromIdeal = newDiffFromIdeal;
  end
  % see if we should keep trying
  nTries = nTries + 1;
  if mod(nTries,maxTries) == 0
    if askuser(sprintf('(initTask:seglenPrecompute) Could not find a good trial sequence after %i iterations. Current difference = %0.2f. Keep trying',nTries,diffFromIdeal))==0
      keyboard
    end
  end
end

% remember the status of the random number generator
task.randstate.trialState = rand(task.randstate.type);
% and reset it to what it was before this call
rand(task.randstate.type,randstate);

% check again, and display compute lengths
trialLength = [];
for iTrial = 1:numTrials
  [trialLength(iTrial) seglen] = computeTrialLen(task.seglenPrecompute.seglen{iTrial},task.synchToVol,framePeriod,synchWaitBeforeTime);
  % display if called for
  if verbose>1
    disp(sprintf('(initTask:seglenPrecompute) Trial %i: seglen [%s] trialLen: %0.2f',iTrial,num2str(seglen,'%0.2f '),trialLength(iTrial)));
  end
end
% compute number of volumes needed
numVolumes = [];
if ~isnan(framePeriod)
  numVolumes = round((numTrials*averageLen)/framePeriod);
end

if verbose
  disp(sprintf('(initTask:seglenPrecompute) Total length: %0.2f Desired length: %0.2f Diff: %0.2f',sum(trialLength),numTrials*averageLen,sum(trialLength)-numTrials*averageLen));
  if ~isempty(numVolumes)
    disp(sprintf('(initTask:seglenPrecompute) %i volumes needed',numVolumes));
  end
end

% display frequency of all trials against expected - only do
% this for synchToVol since then we don't have to deal with
% what to do for expected lengths that are a range between segmin-segmax
if synchToVol || isequal([trialLens.min],[trialLens.max])
  % compute trial lengths and frequencies
  lens = unique(trialLength);
  freq = diff([0 find(diff(sort(trialLength))) length(trialLength)]);
  % if we have computed expected lengths then display those too
  if exist('trialLens')
    % get unique lengths
    [expectedLens dummy indexes]= unique([trialLens(:).max]);
    for iLen = 1:length(expectedLens)
      expectedFreq(iLen) = sum([trialLens(indexes==iLen).freq]);
    end
  else
    expectedLens = lens;
    expectedFreq = nan(1,length(lens));
  end
  % round to a few decimal places to avoid numerical round-off misses
  lens = round(lens*10e5)/10e5;
  expectedLens = round(expectedLens*10e5)/10e5;
  % now go print out
  for iLens = 1:length(expectedLens)
    matchLen = find(expectedLens(iLens) == lens);
    if isempty(matchLen)
      if expectedFreq(iLens)>0
	disp(sprintf('(initTask:seglenPrecompute) trialLen: %0.2f freq: 0.00 (0/%i, %0.2f expected)',expectedLens(iLens),numTrials,expectedFreq(iLens)));
      end
    else
      disp(sprintf('(initTask:seglenPrecompute) trialLen: %0.2f freq: %0.2f (%i/%i, %0.2f expected)',expectedLens(iLens),freq(matchLen)/numTrials,freq(matchLen),numTrials,expectedFreq(iLens)));
    end
  end
end

% validate the structure
task = seglenPrecomputeValidate(task);

if ~isempty(numVolumes) && ~isfield(task.seglenPrecompute,'numVolumes') 
  task.seglenPrecompute.numVolumes = numVolumes;
end
if ~isfield(task.seglenPrecompute,'totalLength') 
  task.seglenPrecompute.totalLength = sum(trialLength);
end

%%%%%%%%%%%%%%%%%%%%%%%%%
%    computeTriallen    %
%%%%%%%%%%%%%%%%%%%%%%%%%
function [trialLen seglen] = computeTrialLen(seglen,synchToVol,framePeriod,synchWaitBeforeTime)

seglenSynch = seglen;

for iSeg = find(synchToVol)
  % check synchToVol segs and set them to be *exact* - i.e. they now specify exactly
  % how long everything is expected to take.
  seglenSynch(iSeg) = ceil(sum(seglenSynch(1:iSeg))/framePeriod)*framePeriod - sum(seglenSynch(1:(iSeg-1)));
end
trialLen = sum(seglenSynch);

% now for each synchToVol remove time to allow a little fudge
for iSeg = find(synchToVol)
  if seglenSynch(iSeg) > synchWaitBeforeTime
    seglen(iSeg) = min(seglen(iSeg),seglenSynch(iSeg)-synchWaitBeforeTime);
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%
%    computeLenProb    %
%%%%%%%%%%%%%%%%%%%%%%%%
function prob = computeLenProb(segmin,segmax,lenmin,lenmax)

% find all segmin/segmaxthat are not the same
segdiff = find(segmin ~= segmax);

if length(segdiff) == 0
  % all segments are the same length, so just check
  % to see whether the sum of all semgnets is within
  % legmin/max limits
  if (sum(segmin) > lenmin) && (sum(segmin) < lenmax)
    prob = 1;
  else
    prob = 0;
  end
  return
elseif length(segdiff) == 1
  % one segment is randomized in length
  trialLenMin = sum(segmin);
  trialLenMax = sum(segmax);
  % compute overlap
  overlapMin = max(trialLenMin,lenmin);
  overlapMax = min(trialLenMax,lenmax);
  % compute probability
  prob = max((overlapMax-overlapMin)/(trialLenMax-trialLenMin),0);
  return
elseif length(segdiff) == 2
  % remove all fixed length segments from lengths so
  % we don't have to worry about them
  fixedLen = sum(segmin(find(segmin==segmax)));
  trialLenMin = lenmin - fixedLen;
  trialLenMax = lenmax - fixedLen;
  % get the lengths of the two segments
  segmin1 = segmin(segdiff(1));
  segmax1 = segmax(segdiff(1));
  seglen1 = segmax1-segmin1;
  segmin2 = segmin(segdiff(2));
  segmax2 = segmax(segdiff(2));
  seglen2 = segmax2-segmin2;
  % some locations we need
  topLeft = [segmin1 segmax2];
  bottomRight = [segmax1 segmin2];
  % to compute the probability we compute the length of time
  % as the polygon within the rectangle bounded by the two 
  % segmin and segmax boundaries. (uncomment the figure
  % to see what this means)
  % check if the trialLenMin is less than the shortest trial
  % this means that the minimum boundary is the minimum of the
  %seglens, so we put that in the vertex list
  nVertex = 0;
  if trialLenMin < (segmin1+segmin2)
    nVertex = nVertex+1;
    vertexList(nVertex,:) = [segmin1 segmin2];
  % check if the trialLenMin is greater than the longest trial
  elseif trialLenMin > (segmax1+segmax2)
    prob = 0;
    return;
  else
    % first get where the boundary crosses the bottom/right
    if trialLenMin < (segmax1+segmin2)
      % crosses the bottom
      nVertex = nVertex+1;
      vertexList(nVertex,:) = [(trialLenMin-segmin2) segmin2];
    else
      % crosses the right side
      nVertex = nVertex+1;
      vertexList(nVertex,:) = [segmax1 (trialLenMin-segmax1)];
      % bottomRight can no longer be a vertex
      bottomRight = [];
    end
    % now get where the topLeft crossing is
    if trialLenMin > (segmin1+segmax2)
      % crosses the top
      nVertex = nVertex+1;
      vertexList(nVertex,:) = [(trialLenMin-segmax2) segmax2];
      topLeft = [];
    else
      % crosses the top 
      nVertex = nVertex+1;
      vertexList(nVertex,:) = [segmin1 (trialLenMin-segmin1)];
    end
  end
  % ok, now find the corssing of the top boundary
  if trialLenMax < (segmin1+segmin2)
    % minimum length is smaller than possible
    prob = 0;
    return
  % check if the trialLenMax is greater than the longest trial
  elseif trialLenMax > (segmax1+segmax2)
    % add top right corner (pluse topLeft and bottomRight if it exists
    if ~isempty(topLeft)
      nVertex = nVertex+1;
      vertexList(nVertex,:) = topLeft;
    end
    nVertex = nVertex+1;
    vertexList(nVertex,:) = [segmax1 segmax2];
    if ~isempty(bottomRight)
      nVertex = nVertex+1;
      vertexList(nVertex,:) = bottomRight;
    end
  else
    % get where the boundary crosses the left
    if trialLenMax < (segmin1+segmax2)
      nVertex = nVertex+1;
      vertexList(nVertex,:) = [segmin1 (trialLenMax-segmin1)];
    else
      % crosses the top
      if ~isempty(topLeft)
	nVertex = nVertex+1;
	vertexList(nVertex,:) = topLeft;
      end
      nVertex = nVertex+1;
      vertexList(nVertex,:) = [(trialLenMax-segmax2) segmax2];
    end
    % now get where the right crossing is
    if trialLenMax < (segmax1+segmin2)
      % crosses the bottom
      nVertex = nVertex+1;
      vertexList(nVertex,:) = [(trialLenMax-segmin2) segmin2];
    else
      % crosses the right
      nVertex = nVertex+1;
      vertexList(nVertex,:) = [segmax1 (trialLenMax-segmax1)];
      if ~isempty(bottomRight)
	nVertex = nVertex+1;
	vertexList(nVertex,:) = bottomRight;
      end
    end
  end
  % compute probability as ratio of area we just computed
  % to the full area (full possible lengths of trial)
  prob = polyarea(vertexList(:,1),vertexList(:,2)) / ((segmax1-segmin1)*(segmax2-segmin2));
  if 0
    mlrSmartfig('initTask:computeLenProb','reuse');clf
    xmin = segmin1-100;xmax = segmax1+100;ymin = segmin2-100;ymax = segmax2+100;
    axis([xmin xmax ymin ymax]);hold on
    xlabel('seg 1 length');ylabel('seg 2 length');
    vline(segmin1,'k-');vline(segmax1,'k-');hline(segmin2,'k-');hline(segmax2,'k-');
    plot([xmin xmax],trialLenMin-[xmin xmax],'k-');
    plot([xmin xmax],trialLenMax-[xmin xmax],'k-');
    for iVertex = 1:nVertex
      plot(vertexList(iVertex,1),vertexList(iVertex,2),'ro');
    end
    title(sprintf('Probability = %f',prob));
    keyboard
  end
else
  disp(sprintf('(initTask:computeLenProb) Computing the probability of trial length not yet implemnted for cases in which more than 2 segments have randomized times'));
  keyboard
end
  

    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    seglenPrecomputeValidate    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function task = seglenPrecomputeValidate(task)

if isequal(task.seglenPrecompute,false),return,end

% make sure it is a structure
if ~isstruct(task.seglenPrecompute)
  disp(sprintf('(initTask) seglenPrecompute should either be true or a strucutre with fields that contains precomputed fields'));
  keyboard
end

if ~isfield(task.seglenPrecompute,'seglen')
  disp(sprintf('(initTask) seglenPrecompute must have the field seglen'));
  keyboard
end

% get the fields
task.seglenPrecompute.fieldNames = fieldnames(task.seglenPrecompute);
task.seglenPrecompute.nFields = length(task.seglenPrecompute.fieldNames);

% now for each field precompute number of rows
for iField = 1:task.seglenPrecompute.nFields
  % set each field to be a struct that contains the vals for each trial
  % and the number of values there are
  x.vals = task.seglenPrecompute.(task.seglenPrecompute.fieldNames{iField});
  % convert to cell array
  if ~iscell(x.vals)
    % if is just an array of values
    if isequal(length(x.vals),numel(x.vals))
      x.vals = num2cell(x.vals);
    else
      % this is an array, so one row per trial
      for iRow = 1:size(x.vals,1)
	vals{iRow} = x.vals(iRow,:);
      end
      x.vals = vals;
    end
  end
  x.nTrials = length(x.vals);
  task.seglenPrecompute.(task.seglenPrecompute.fieldNames{iField}) = x;
end

% remove seglen from list of fields
task.seglenPrecompute.fieldNames = setdiff(task.seglenPrecompute.fieldNames,'seglen');
task.seglenPrecompute.nFields = task.seglenPrecompute.nFields-1;

% compute numsegs (maximum number of segments)
task.numsegs = 0;
for iVal = 1:task.seglenPrecompute.seglen.nTrials
  task.numsegs = max(task.numsegs,length(task.seglenPrecompute.seglen.vals{iVal}));
end

% now add enough synchToVol, segquant, segdur and segprob
if ~isfield(task,'synchToVol') || (length(task.synchToVol) < task.numsegs)
  task.synchToVol(task.numsegs) = 0;
end
if ~isfield(task,'segquant') || (length(task.segquant) < task.numsegs)
  task.segquant(task.numsegs) = 0;
end
if ~isfield(task,'segdur') || (length(task.segdur) < task.numsegs)
  task.segdur{task.numsegs} = [];
end
if ~isfield(task,'segprob') || (length(task.segprob) < task.numsegs)
  task.segprob{task.numsegs} = [];
end



