% getTaskParameters.m
%
%      usage: exp = getTaskParameters(myscreen,task)
%         by: justin gardner
%       date: 01/27/07
%    purpose: get the task parameters, reaction times etc,
%             out of the screen and task variables
%
%             Note that all volume numbers represent the beginning of a trial or a segment
%             and are rounded to the **closest** volume number. Thus if your trial or segment
%             started at time 0.76 seconds and your frame period (TR) was 1.5 seconds, then 
%             you would see a volume number of 2 rather than 1.
%
function [experiment stimfile] = jglGetTaskParameters(myscreen,task)

% check arguments
experiment = [];stimfile=[];
if ~any(nargin == [1 2])
  help getTaskParameters
  return
end

% see if we are passed the name of a file
if (nargin == 1) && isstr(myscreen)
  % check for file
  [pathStr filename ext] = fileparts(myscreen);
  if ~isempty(pathStr)
    filename = sprintf('%s.mat',fullfile(pathStr,filename));
  else
    filename = sprintf('%s.mat',fullfile(pwd,filename));
  end
    
  if ~isfile(filename)
    disp(sprintf('(getTaskParameters) Could not find file %s',filename));
    return
  end
  % load file
  load(filename);
  stimfileName = filename;
else
  stimfileName = '';
end

% so you can pass in stimfile strucuture from MLR
if isfield(myscreen,'myscreen') && isfield(myscreen,'task')
  task = myscreen.task;
  myscreen = myscreen.myscreen;
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
if ~iscell(task)
  allTasks{1}{1} = task;
  multiTask = 0;
elseif ~iscell(task{1}) % assumes multiple phases, not tasks
  allTasks{1} = task;
  multiTask = 0;
else
  % otherwise cycle through tasks
  allTasks = task;
  multiTask = 1;
end

volumeTR = [];

for taskNum = 1:length(allTasks)
  task = allTasks{taskNum};
  % init some variables
  exptStartTime = inf;
  volnum = 0;
  nextVolNum = 1;
  volTime = 0;
  nextVolTime = inf;
  phaseNum = 1;
  blockNum = 1;
  blockTrialNum = 0;
  numTraces = max(0,max(myscreen.events.tracenum) - myscreen.stimtrace + 1);
  experiment = initPhase([],phaseNum,numTraces,task{phaseNum});
  tnum = 0;

  if (task{phaseNum}.segmentTrace)
    % go through the events, looking for the segment  
    for enum = 1:myscreen.events.n
      % get the volume number of the event
      volnum = myscreen.events.volnum(enum);
      eventTime = myscreen.events.time(enum);
      % if we are closer to the next volume than the current
      % volume (i.e. the one last recorded by a backtick, then
      % we want to use the following volume as our volume number
      if (eventTime-volTime) > (nextVolTime-eventTime)
	volnum = nextVolNum;
      end
      % deal with segment trace
      if myscreen.events.tracenum(enum) == task{phaseNum}.segmentTrace
	if (round(myscreen.events.data(enum)) ~= myscreen.events.data(enum)) || (myscreen.events.data(enum)<1)
	  disp(sprintf('(getTaskParameters) Bad segmentTrace (%i) value %i at %i',myscreen.events.tracenum(enum),myscreen.events.data(enum),enum));
	  continue;
	end
	% get the segment and the segment time
	thisseg = myscreen.events.data(enum);
	segtime = myscreen.events.time(enum);
	ticknum = myscreen.events.ticknum(enum);
	% check for new trial
	if thisseg == 1
	  tnum = tnum+1;
	  if tnum > task{phaseNum}.numTrials
	    fprintf('Recorded trace events past end of last trial.\n');
	    return
	  end 
	  experiment(phaseNum).nTrials = tnum;
	  % get the time that the experiment starts
	  % this will only get set for the 1st seg of 1st trial
	  exptStartTime = min(segtime,exptStartTime);
	  % now keep the trial time
	  experiment(phaseNum).trialTime(tnum) = segtime-exptStartTime;
	  experiment(phaseNum).trialTicknum(tnum) = myscreen.events.ticknum(enum);
	  experiment(phaseNum).trialVolume(tnum) = volnum;
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
	  experiment(phaseNum).trials(tnum).responseSegnum = [];
	  experiment(phaseNum).trials(tnum).reactionTime = [];
	  experiment(phaseNum).trials(tnum).responseTimeRaw = [];
	  experiment(phaseNum).trials(tnum).traces.tracenum = [];
	  experiment(phaseNum).trials(tnum).traces.val = [];
	  experiment(phaseNum).trials(tnum).traces.time = [];
	  if numTraces > 0
	    experiment(phaseNum).traces(:,tnum) = nan;
	  end
	  experiment(phaseNum).response(tnum) = nan;
	  experiment(phaseNum).responseVolume(tnum) = nan;
	  experiment(phaseNum).reactionTime(tnum) = nan;
	  experiment(phaseNum).responseTimeRaw(tnum) = nan;
	  % get all the random parameter
	  for rnum = 1:task{phaseNum}.randVars.n_
	    eval(sprintf('experiment(phaseNum).randVars.%s(tnum) = task{phaseNum}.randVars.%s(mod(tnum-1,task{phaseNum}.randVars.varlen_(%i))+1);',task{phaseNum}.randVars.names_{rnum},task{phaseNum}.randVars.names_{rnum},rnum));
	  end
	  if isfield(task{phaseNum},'parameterCode')
	    experiment(phaseNum).parameterCode = task{phaseNum}.parameterCode;
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
	  % remember the time of the volume
	  volTime = myscreen.events.time(enum);
	  % get the next volume time, by looking for the next volume event
	  volEvents = find((myscreen.events.tracenum(enum+1:end) == 1) & (myscreen.events.data(enum+1:end) == 1));
	  % if we have the next volume event get the time
	  if ~isempty(volEvents)
	    nextVolEvent = volEvents(1)+enum;
	    nextVolTime = myscreen.events.time(nextVolEvent);
	    nextVolNum = myscreen.events.volnum(nextVolEvent)+1;
	  else
	    % if we have collected some information about volumeTR
	    % then we set the final+1 volume to happen one volume
	    % later. This way events that happen after the last volume
	    % can be set to have a volume number of nan
	    if ~isempty(volumeTR(~isnan(volumeTR)))
	      nextVolTime = volTime+median(volumeTR(~isnan(volumeTR)));
	    else
	      nextVolTime = inf;
	    end
	    nextVolNum = nan;
	  end
	  % keep the amount of time each volume takes
	  volumeTR(end+1) = nextVolTime-volTime;
	end
	% deal with phasenum event
      elseif myscreen.events.tracenum(enum) == task{phaseNum}.phaseTrace
	phaseNum = myscreen.events.data(enum);
	if phaseNum <= length(task)
	  blockNum = 1;
	  blockTrialNum = 0;
	  experiment = initPhase(experiment,phaseNum,numTraces,task{phaseNum});
	  experiment(phaseNum).nTrials = 1;
	  tnum = 0;
	else
	  break;
	end
	% deal with response
      elseif myscreen.events.tracenum(enum) == task{phaseNum}.responseTrace
	whichButton = myscreen.events.data(enum);
	% make sure this is happening after first trial
	if tnum
	  % reaction time relative to beginning of segment
	  reactionTime = myscreen.events.time(enum)-exptStartTime-segtime;
	  % responseTimeRaw is response time relative to beginning of the experiment
	  responseTimeRaw = myscreen.events.time(enum)-exptStartTime;
	  % now adjust reactionTime if the previous segments
	  % had the response on (that is, the response time
	  % is the time not necesarily from the beginning of 
	  % this current segment, but from the first segment
	  % before this one in which the subject could have
	  % responded.
	  if isfield(task{phaseNum},'getResponse') && (length(task{phaseNum}.getResponse) >= thisseg)
	    % get how long each segment took relative to the previous one
	    seglen = diff(experiment(phaseNum).trials(tnum).segtime);
	    % now cycle backwards from the segment previous to this one
	    i = thisseg-1;
	    % if getResponse was on (and we are not at the beginning of the trial yet
	    while ((i >= 1) && task{phaseNum}.getResponse(i))
	      % then the reaction time should be increased by the length
	      % of time the segment took.
	      reactionTime = reactionTime+seglen(i);
	      i=i-1;
	    end
	  end
	  % save the first response in the response array
	  if isnan(experiment(phaseNum).response(tnum))
	    experiment(phaseNum).response(tnum) = whichButton;
	    experiment(phaseNum).reactionTime(tnum) = reactionTime;
	    experiment(phaseNum).responseTimeRaw(tnum) = responseTimeRaw;
	    % now see if the response happened closer to this volume 
	    % or closer to the next volume
	    responseTime = myscreen.events.time(enum);
	    experiment(phaseNum).responseVolume(tnum) = volnum;
	  end
	  % save all responses in trial
	  experiment(phaseNum).trials(tnum).response(end+1) = whichButton;
	  experiment(phaseNum).trials(tnum).reactionTime(end+1) = reactionTime;
	  experiment(phaseNum).trials(tnum).responseTimeRaw(end+1) = responseTimeRaw;
	  experiment(phaseNum).trials(tnum).responseSegnum(end+1) = thisseg;
	  experiment(phaseNum).trials(tnum).responseVolume(end+1) = volnum;
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

% save stimfile
stimfile.stimfilePath = '';
if ~isempty(stimfileName)
  [stimfile.stimfilePath stimfile.stimfile] = fileparts(stimfileName);
else
  if isfield(myscreen,'stimfile');
    stimfile.stimfile = myscreen.stimfile;
  else
    stimfile.stimfile = '';
  end
end
stimfile.myscreen = myscreen;
stimfile.task = allTasks;

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

%%%%%%%%%%%%%%%%%%%
%    initPhase    %
%%%%%%%%%%%%%%%%%%%
function experiment = initPhase(experiment,phaseNum,numTraces,task)

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

% get what the parameters were originaly set to - i.e. in the task variable. This gives a record
% of all the values that the parameter was originally intended to go through for example (sometimes
% an experiment may run short and you don't go through all possible values).
experiment(phaseNum).originalTaskParameter = task.parameter;
taskParameters = fieldnames(task.parameter);
for i = 1:length(taskParameters)
  % remove fields that end in _ which are created by initRandomization
  if taskParameters{i}(end) == '_'
    experiment(phaseNum).originalTaskParameter = rmfield(experiment(phaseNum).originalTaskParameter,taskParameters{i});
  else
    % check for a multi-row field, this a variable that has different settings for each row
    % i.e. like when you do a split screen design with one randomization for the left and one for the right
    numRows = size(task.parameter.(taskParameters{i}),1);
    if numRows > 1
      % remove the field
      experiment(phaseNum).originalTaskParameter = rmfield(experiment(phaseNum).originalTaskParameter,taskParameters{i});
      % and reset to a field name which has a number for each row. e.g. orientation will become
      % orientation1, orientation2 etc.
      for iRows = 1:numRows
	experiment(phaseNum).originalTaskParameter.(sprintf('%s%i',taskParameters{i},iRows)) = task.parameter.(taskParameters{i})(iRows,:);
      end
    end
  end
end

% now do the same for randVars. Works the same way, but get what the parameters were originaly set to - i.e. in the task variable. This gives a record
randVarTypes = {'uniform','block','calculated'};
for iRandVarType = 1:length(randVarTypes)
  if isfield(task.randVars,randVarTypes{iRandVarType})
    randVars = fieldnames(task.randVars.(randVarTypes{iRandVarType}));
    for i = 1:length(randVars)
      % only use fields that don't end in _ 
      if randVars{i}(end) ~= '_'
	% check to see if there is a variable with the same name except with an underscore after
	% it, that will contain the variables all possible settings.
	allSettings = find(strcmp(sprintf('%s_',randVars{i}),randVars));
	if ~isempty(allSettings)
	  experiment(phaseNum).originalRandVars.(randVars{i}) = task.randVars.(randVarTypes{iRandVarType}).(randVars{allSettings});
	else
	  % otherwise just set to whatever it was set to
	  experiment(phaseNum).originalRandVars.(randVars{i}) = task.randVars.(randVarTypes{iRandVarType}).(randVars{i});
	end
      end
    end
  end
end


