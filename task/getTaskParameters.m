% getTaskParameters.m
%
%      usage: myscreen = getTaskParameters(myscreen,task)
%         by: justin gardner
%       date: 01/27/07
%    purpose: get the task parameters, reaction times etc,
%             out of the screen and task variables
%
function experiment = getTaskParameters(myscreen,task)

% check arguments
if ~any(nargin == [1 2])
  help getTaskParameters
  return
end

% get task from myscreen
if ~exist('task','var') && isfield(myscreen,'task')
  task = myscreen.task;
end

if ~exist('task','var') || isempty(task)
  disp(sprintf('(getTaskParameters) No task variable'));
  help getTaskParameters;
  return
end

% if there is only one task
if ~iscell(task{1})
  allTasks{1} = task;
  multiTask = 0;
else
  % otherwise cycle through tasks
  allTasks = task;
  multiTask = 1;
end

for taskNum = 1:length(allTasks)
  task = allTasks{taskNum};
  % init some variables
  exptStartTime = inf;
  volnum = 0;
  phaseNum = 1;
  blockNum = 1;
  blockTrialNum = 0;
  numTraces = max(0,max(myscreen.events.tracenum) - myscreen.stimtrace + 1);
  experiment = initPhase([],phaseNum,numTraces);
  tnum = 0;
  
  if (task{phaseNum}.segmentTrace)
    % go through the events, looking for the segment  
    for enum = 1:myscreen.events.n
      % deal with segment trace
      if myscreen.events.tracenum(enum) == task{phaseNum}.segmentTrace
	% get the segment and the segment time
	thisseg = myscreen.events.data(enum);
	segtime = myscreen.events.time(enum);
	ticknum = myscreen.events.ticknum(enum);
	% check for new trial
	if thisseg == 1
	  tnum = tnum+1;
	  experiment(phaseNum).nTrials = tnum;
	  % get the time that the experiment starts
	  % this will only get set for the 1st seg of 1st trial
	  exptStartTime = min(segtime,exptStartTime);
	  % now keep the trial time
	  experiment(phaseNum).trialTime(tnum) = segtime-exptStartTime;
	  experiment(phaseNum).trialTicknum(tnum) = myscreen.events.ticknum(enum);
	  % see whether we are closer to this volume time
	  % or the next volume time
	  if (segtime-volTime) > (nextVolTime-segtime)
	    % if we are closer to the next volume, then adjust
	    % the volume by 1
	    experiment(phaseNum).trialVolume(tnum) = volnum+1;
	  else
	    experiment(phaseNum).trialVolume(tnum) = volnum;
	  end
	  % get block trial numbers
	  blockTrialNum = blockTrialNum+1;
	  % see if we have to go over to the next block
	  if task{phaseNum}.block(blockNum).trialn < blockTrialNum
	    blockNum = blockNum + 1;
	    blockTrialNum = 1;
	  end
	  % save the block num and trial num
	  experiment(phaseNum).blockNum(tnum) ...
	      = blockNum;
	  experiment(phaseNum).blockTrialNum(tnum) ...
	      = blockTrialNum;
	  % and initalize other parameters
	  experiment(phaseNum).trials(tnum).response = [];
	  experiment(phaseNum).trials(tnum).responseVolume = [];
	  experiment(phaseNum).trials(tnum).reactionTime = [];
	  experiment(phaseNum).trials(tnum).traces.tracenum = [];
	  experiment(phaseNum).trials(tnum).traces.val = [];
	  experiment(phaseNum).trials(tnum).traces.time = [];
	  if numTraces > 0
	    experiment(phaseNum).traces(:,tnum) = nan;
	  end
	  experiment(phaseNum).response(tnum) = nan;
	  experiment(phaseNum).responseVolume(tnum) = nan;
	  experiment(phaseNum).reactionTime(tnum) = nan;
	  % get all the random parameter
	  for rnum = 1:task{phaseNum}.randVars.n_
	    eval(sprintf('experiment(phaseNum).randVars.%s(tnum) = task{phaseNum}.randVars.%s(mod(tnum-1,task{phaseNum}.randVars.varlen_(%i))+1);',task{phaseNum}.randVars.names_{rnum},task{phaseNum}.randVars.names_{rnum},rnum));
	  end
	  % and get all parameters
	  parameterNames = fieldnames(task{phaseNum}.block(blockNum).parameter);
	  % and set the values
	  for pnum = 1:length(parameterNames)
	    thisParam = task{phaseNum}.block(blockNum).parameter.(parameterNames{pnum});
	    % if it is an array then it is just a regular parameter
	    if size(thisParam,1) == 1
	      eval(sprintf('experiment(phaseNum).parameter.%s(tnum) = thisParam(blockTrialNum);',parameterNames{pnum}));
	    % otherwise there are multiple values per each trial
	    else
	      for paramRowNum = 1:size(thisParam,1)
		eval(sprintf('experiment(phaseNum).parameter.%s%i(tnum) = thisParam(paramRowNum,blockTrialNum);',parameterNames{pnum},paramRowNum));
	      end
	    end
	  end
	end
	
	% set the segment time for this trial
	segtime = segtime-exptStartTime;
	experiment(phaseNum).trials(tnum).segtime(thisseg) = segtime;
	experiment(phaseNum).trials(tnum).volnum(thisseg) = volnum;
	experiment(phaseNum).trials(tnum).ticknum(thisseg) = ticknum;
	% deal with volnum event
      elseif myscreen.events.tracenum(enum) == 1
	% if data is set to one then it means that we got a backtick
	% if it is set to zero it means we are coming out of a backtick
	if myscreen.events.data(enum)
	  % so update the volume counter when we get the backtick
	  volnum = volnum+1;
	  % and remember the time of the volume
	  volTime = myscreen.events.time(enum);
	  % get the next volume time, by looking for the next volume event
	  volEvents = find((myscreen.events.tracenum(enum+1:end) == 1) & (myscreen.events.data(enum+1:end) == 1));
	  % if we have the next volume event get the time
	  if ~isempty(volEvents)
	    nextVolEvent = volEvents(1)+enum;
	    nextVolTime = myscreen.events.time(nextVolEvent);
	  else
	    nextVolTime = inf;
	  end
	end
	% deal with phasenum event
      elseif myscreen.events.tracenum(enum) == task{phaseNum}.phaseTrace
	phaseNum = myscreen.events.data(enum);
	blockNum = 1;
	blockTrialNum = 0;
	experiment = initPhase(experiment,phaseNum,numTraces);
	experiment(phaseNum).nTrials = 1;
	tnum = 0;
	% deal with response
      elseif myscreen.events.tracenum(enum) == task{phaseNum}.responseTrace
	whichButton = myscreen.events.data(enum);
	% make sure this is happening after first trial
	if tnum
	  reactionTime = myscreen.events.time(enum)-exptStartTime-segtime;
	  % save the first response in the response array
	  if isnan(experiment(phaseNum).response(tnum))
	    experiment(phaseNum).response(tnum) = whichButton;
	    experiment(phaseNum).reactionTime(tnum) = reactionTime;
	    % now see if the response happened closer to this volume 
	    % or closer to the next volume
	    responseTime = myscreen.events.time(enum);
	    % if the response happened closer to the next volume then
	    % we should adjust the volume number so that it is associated
	    % with the next volume
	    if (responseTime-volTime) > (nextVolTime-responseTime)
	      experiment(phaseNum).responseVolume(tnum) = myscreen.events.volnum(enum)+1;
	    else
	      experiment(phaseNum).responseVolume(tnum) = myscreen.events.volnum(enum);
	    end
	  end
	  % save all responses in trial
	  experiment(phaseNum).trials(tnum).response(end+1) = whichButton;
	  experiment(phaseNum).trials(tnum).reactionTime(end+1) = reactionTime;
	end
	% deal with user traces
      elseif myscreen.events.tracenum(enum) >= myscreen.stimtrace
	tracenum = myscreen.events.tracenum(enum)-myscreen.stimtrace+1;
	userval = myscreen.events.data(enum);
	usertime = myscreen.events.time(enum)-exptStartTime;
	% there is some chance that a user trace can be written
        % before the first trial is started for this task. This
	% happens if there are multiple tasks and this user
	% trace belongs to another task. In that case, storing
	% this variable with this task is not really necessary,
	% but we do not know that here so we just either save
	% it if we have a valid trial number or ignore it if not.
	if (tnum)
	  % store it if it is the first setting
	  if isnan(experiment(phaseNum).traces(tracenum,tnum))
	    experiment(phaseNum).traces(tracenum,tnum) = userval;
	  end
	  % put it in trial
	  experiment(phaseNum).trials(tnum).traces.tracenum(end+1) = tracenum;
	  experiment(phaseNum).trials(tnum).traces.val(end+1) = userval;
	  experiment(phaseNum).trials(tnum).traces.time(end+1) = usertime;
	end
      end
    end      
  end
  % for a multi task experiment, then we keep a cell array of values
  if multiTask
    retval{taskNum} = experiment;
  else
    retval = experiment;
  end
end

experiment = retval;

% set the traces in the return value if they exist
if isfield(myscreen,'traces')
  if iscell(experiment)
    for i = 1:length(experiment)
      for j = 1:length(experiment{i})
        experiment{i}(j).tracesAll = myscreen.traces;
      end
    end
  else
    for j = 1:length(experiment)
      experiment(j).tracesAll = myscreen.traces;
    end
  end
end

function experiment = initPhase(experiment,phaseNum,numTraces)

experiment(phaseNum).nTrials = 0;
experiment(phaseNum).trialVolume = [];
experiment(phaseNum).trialTime = [];
experiment(phaseNum).trialTicknum = [];
experiment(phaseNum).trials = [];
experiment(phaseNum).blockNum = [];
experiment(phaseNum).blockTrialNum = [];
experiment(phaseNum).response = [];
experiment(phaseNum).reactionTime = [];
if numTraces>0
  experiment(phaseNum).traces(1:numTraces,:) = nan;
end

