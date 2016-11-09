% getTaskVar.m
%
%      usage: val = getTaskVar(task,varname,trialNum)
%         by: justin gardner
%       date: 11/09/16
%    purpose: Gets the value of a variable from the task.
%
%       e.g.: Get the last trial value for parameter, myVariable
%             val = getTaskVar(task,'myVariable',-1);
%
%       e.g.: Get the for parameter, myVariable for trial 5
%             val = getTaskVar(task,'myVariable',5);
%
%       e.g.: Get the for parameter, myVariable for current trial 
%             val = getTaskVar(task,'myVariable',0);
%
%             If the trial or variable does not exist, returns []
%
function retval = getTaskVar(task,varname,trialNum)

retval = [];

% check arguments
if ~any(nargin == [3])
  help getTaskVar
  return
end

% what trial is being asked for
if trialNum == -1
  % if last trial, then this is easy, just pull from lasttrial structure
  if isfield(task.lasttrial,varname)
    retval = task.lasttrial.(varname);
  end
  return
elseif trialNum == 0
  % if current trial, then this is easy, just pull from thistrial structure
  if isfield(task.thistrial,varname)
    retval = task.thistrial.(varname);
  end
  return
elseif trialNum < -1
  % convert to a positive trialnum (from beginning of experiment)
  trialNum = task.trialnum + trialNum;
  if trialNum < 1,return,end
elseif trialNum > task.trialnum
  % no trial yet
  return
end

% see if it is a parameter
if task.parameter.n_ > 0
  % look for variable name
  matchValue = find(strcmp(varname,task.parameter.names_));
  if ~isempty(matchValue)
    % figure out block and trial
    blockNum = floor((trialNum-1)/task.block(1).trialn)+1;
    trialNum = trialNum -  ((blockNum-1) * task.block(1).trialn);
    % get value
    retval = task.block(blockNum).parameter.(varname)(trialNum);
    return
  end
end

if task.randVars.n_ > 0
  % look for variable name
  matchValue = find(strcmp(varname,task.randVars.names_));
  if ~isempty(matchValue)
    % get value
    retval = task.randVars.(varname)(trialNum);
    return
  end
end
