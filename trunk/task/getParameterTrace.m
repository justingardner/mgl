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

% go through each phase
for pnum = 1:length(myscreen.task)
  original = '';exptVarname = '';
  % look for variable in parameters
  if isfield(myscreen.task{pnum}.parameter,varname)
    original = sprintf('myscreen.task{%i}.parameter.%s',pnum,varname);
    exptVarname = sprintf('experiment(%i).parameter.%s',pnum,varname);
  end
  % or look for variable in randVars
  if myscreen.task{pnum}.randVars.n_ && any(strcmp(varname,myscreen.task{pnum}.randVars.names_))
    original = sprintf('myscreen.task{%i}%s',pnum,myscreen.task{pnum}.randVars.originalName_{find(strcmp(varname,myscreen.task{pnum}.randVars.names_))}(5:end));
    exptVarname = sprintf('experiment(%i).randVars.%s',pnum,varname);
  end
  % if we found the variable then go ahead and create the trace
  if ~isempty(original)
    for i = 1:experiment(pnum).nTrials
      ticknum = experiment(pnum).trialTicknum(i);
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


