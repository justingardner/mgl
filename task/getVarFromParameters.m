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

