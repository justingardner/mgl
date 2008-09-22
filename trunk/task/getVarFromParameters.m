% getVarFromParameters.m
%
%        $Id: 
%      usage: getVarFromParameters(varname,e)
%         by: justin gardner
%       date: 03/16/07
%    purpose: get a variable name from task parameters, could be
%             will return the full qualified name of the variable
%             e is returned from getTaskParameters
% e.g.
% getVarFromparametrs('varname',getTaskParameters(task));
%%%%%%%%%%%%%%%%%%%%%%%%
function [varval taskNum phaseNum] = getVarFromParameters(varname,e)

% check arguments
if ~any(nargin == [2])
  help getVarFromParameters
  return
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
  return
end

% go search for the parameter
for i = 1:length(e)
  for j = 1:length(e{i})
    % see if it is a parameter
    if isfield(e{i}(j).parameter,varname)
      varval = e{i}(j).parameter.(varname);
      taskNum = i;
      phaseNum = j;
      % or a rand var
    elseif isfield(e{i}(j),'randVars') && isfield(e{i}(j).randVars,varname)
      varval = e{i}(j).randVars.(varname);
      taskNum = i;
      phaseNum = j;
    end
  end
end

