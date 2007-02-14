% getParameterTrace.m
%
%      usage: getParameterTrace(myscreen,varname,[usenum])
%         by: justin gardner
%       date: 02/05/07
%    purpose: creates a parameter trace from a saved
%             myscreen variable
%       e.g.: myscreen.traces(myscreen.stimtrace,:) = getParameterTrace(myscreen,'myParameter1');
%
function trace = getParameterTrace(myscreen,varname,usenum)

% check arguments
if ~any(nargin == [2 3])
  help getParameterTrace
  return
end

% default value
if ~exist('usenum','var'),usenum = 1;,end

% get the experimental parameters
experiment = getTaskParameters(myscreen);

% init trace
trace = zeros(1,size(myscreen.traces,2));

% if there is only one task
if ~iscell(myscreen.task{1})
  allTasks{1} = myscreen.task;
else
  % otherwise cycle through tasks
  allTasks = myscreen.task;
end

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
	ticknum = experiment{tnum}(pnum).trialTicknum(i);
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