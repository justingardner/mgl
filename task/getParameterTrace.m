% getParameterTrace.m
%
%      usage: getParameterTrace(myscreen,task,varname,[usenum],[segnum])
%         by: justin gardner
%       date: 02/05/07
%    purpose: creates a parameter trace from a saved
%             myscreen variable
%       e.g.: myscreen.traces(task.myParameter1Trace,:) = getParameterTrace(myscreen,task,'myParameter1');
%
function trace = getParameterTrace(myscreen,task,varname,usenum,segnum)

% check arguments
if ~any(nargin == [3 4 5])
  help getParameterTrace
  return
end

% if the varname is a number, it means to return a trace number
if isnumeric(varname)
  myscreen = makeTraces(myscreen);
  if all(varname <= size(myscreen.traces,1))
    trace = myscreen.traces(varname,:);
  else
    trace = [];
    disp(sprintf('(getParameterTrace) Only found %i traces',size(myscreen.traces,1)));
  end
  return
end

% default value
if ~exist('usenum','var'),usenum = 1;,end
if ~exist('segnum','var'),segnum = 1;,end

% init trace
trace = zeros(1,myscreen.tick);

% if there is only one task
if ~iscell(task{1})
  allTasks{1} = task;
else
  % otherwise cycle through tasks
  allTasks = task;
end

% get the experimental parameters
experiment = getTaskParameters(myscreen,allTasks);


for tnum = 1:length(allTasks)
  task = allTasks{tnum};
  % go through each phase
  for pnum = 1:length(task)
    original = '';exptVarname = '';
    % look for variable in parameters
    if isfield(task{pnum}.parameter,varname)
      original = sprintf('task{%i}.parameter.%s',pnum,varname);
      exptVarname = sprintf('experiment{%i}(%i).parameter.%s',tnum,pnum,varname);
    end
    % or look for variable in randVars
    if task{pnum}.randVars.n_ && any(strcmp(varname,task{pnum}.randVars.names_))
      original = sprintf('task{%i}%s',pnum,task{pnum}.randVars.originalName_{find(strcmp(varname,task{pnum}.randVars.names_))}(5:end));
      exptVarname = sprintf('experiment{%i}(%i).randVars.%s',tnum,pnum,varname);
    end
    % if we found the variable then go ahead and create the trace
    if ~isempty(original)
      for i = 1:experiment{tnum}(pnum).nTrials
	% make sure we have enough segments
	if (task{pnum}.numsegs >= segnum) && (length(experiment{tnum}(pnum).trials(i).segtime)>=segnum)
	  ticknum = experiment{tnum}(pnum).trials(i).ticknum(segnum);
	  varValue = eval(sprintf('%s(%i)',exptVarname,i));
	  varIndex = eval(sprintf('find(%s == varValue)',original));
	  if (usenum)
	    trace(ticknum) = varIndex;
	  else
	    trace(ticknum) = varValue;
	  end
	end
      end
    end
  end
end