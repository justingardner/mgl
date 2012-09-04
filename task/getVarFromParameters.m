% getVarFromParameters.m
%
%        $Id: 
%      usage: getVarFromParameters(varname,e,<allPossibleVals=0>)
%         by: justin gardner
%       date: 03/16/07
%    purpose: get a variable name from task parameters, could be
%             will return the full qualified name of the variable
%             e is returned from getTaskParameters
%             if the third argument is set to 1, this function returns
%             what all possible values are for the variable.
% e.g.
% getVarFromParameters('varname',getTaskParameters(task));
%%%%%%%%%%%%%%%%%%%%%%%%
function [varval taskNum phaseNum] = getVarFromParameters(varname,e,allPossibleVals)

% check arguments
if ~any(nargin == [2 3])
  help getVarFromParameters
  return
end

% normally just get the values that were actually run. If allPossibleVals is set
% then return what all possible values for that parameter were.
if nargin < 3
  allPossibleVals = 0;
end

if ~iscell(e)
  olde = e;
  clear e;
  e{1} = olde;
end

varval = '';
taskNum = [];
phaseNum = [];

% now handle varnames that look like refvar(indexvar)
if regexp(varname,'.*[(].*[)]$') 
  % then split into two variables
  [refvar varname] = strtok(varname,'(');
  indexvar = strtok(varname,'()');
  % get the index values
  [indexval taskNum phaseNum] = getVarFromParameters(indexvar,e);
  if isempty(indexval)
    disp(sprintf('(getVarFromParameters) Could not find index variable %s',indexvar));
    keyboard
  end
  % make sure there is a valid parameterCode named refvar
  if ~isfield(e{taskNum}(phaseNum),'parameterCode') || ~isfield(e{taskNum}(phaseNum).parameterCode,refvar)
    disp(sprintf('(getVarFromParameters) Could not find parameterCode %s',refvar));
    varval = [];
    return
  end
  % get refvar
  refvar = e{taskNum}(phaseNum).parameterCode.(refvar);
  % check lengths
  if (min(indexval) < 1) || (max(indexval) > length(refvar))
    disp(sprintf('(getVarFromParameters) Index variable %s has invalid index for parameterCode %s',indexvar,refvar));
    disp(sprintf('                       Index variables has values %s',num2str(unique(indexval))));
    disp(sprintf('                       ParameterCode has length %i',length(refvar)));
    varval = [];
    return
  end
  varval = refvar(indexval);
  % if allPossibleVals is set, then just return the parameterCode vals
  if allPossibleVals
    varval = unique(sort(refvar));
  end
  return
end

% go search for the parameter
for i = 1:length(e)
  for j = 1:length(e{i})
    % see if it is a parameter
    if isfield(e{i}(j).parameter,varname)
      % get the variable
      if allPossibleVals
	% get all possible vals
	varval = unique(e{i}(j).originalTaskParameter.(varname));
      else
	% get the vals that were actually run
	varval = e{i}(j).parameter.(varname);
      end
      taskNum = i;
      phaseNum = j;
      % or a rand var
    elseif isfield(e{i}(j),'randVars') && isfield(e{i}(j).randVars,varname)
      % get the variable
      if allPossibleVals
	% look for it in the "originalRandVars" field, make sure that the original is not empty
	% or set to nan - which indicates that it does not contain all possible values
	if isfield(e{i}(j),'originalRandVars') && isfield(e{i}(j).originalRandVars,varname) && ~isempty(e{i}(j).originalRandVars.(varname)) && ~any(isnan(e{i}(j).originalRandVars.(varname)))
	  varval = unique(e{i}(j).originalRandVars.(varname));
	  % check here if this all possible values actually contains the values that were recorded
	  actualValues = unique(e{i}(j).randVars.(varname));
	  numMissingValues = sum(~ismember(actualValues,varval));
	  if numMissingValues>0
	    % display warning
	    disp(sprintf('(getVarFromParameters) !!! Found %i values for variable %s recorded that were unexpected, given that they were not ones set in the orignal rand var setting - i.e. in the task variable - adding them to the all possible values list !!!',numMissingValues,varname));
	    % add the missing values to varval
	    varval = union(varval,actualValues);
	  end
	else
	  varval = unique(e{i}(j).randVars.(varname));
	end
      else
	varval = e{i}(j).randVars.(varname);
      end
      taskNum = i;
      phaseNum = j;
    % if allPossibleVals is set then see if the variable is a parameterCode and return that 
    elseif allPossibleVals && isfield(e{i}(j),'parameterCode') && isfield(e{i}(j).parameterCode,varname)
      varval = unique(sort(e{i}(j).parameterCode.(varname)));
      taskNum = i;
      phaseNum = j;
    end
  end
end

