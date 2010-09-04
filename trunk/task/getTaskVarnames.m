% getTaskVarnames.m
%
%        $id:
%      usage: [varnames varnamesStr] = getTaskVarnames(task)
%             [varnames varnamesStr] = getTaskVarnames(v)
%         by: justin gardner
%       date: 03/14/07
%    purpose: returns all the names of the variables in the task
%             as a cell array (second optional output returns
%             a single string with the name of the variables)
%
%             Can also be called on a view:
%
%             v = newView;
%             v = viewSet(v,'curGroup','Concatenation');
%             v = viewSet(v,'curScan',1); 
%             [varnames varnameStr] = getTaskVarnames(v);
%
function [varnames varnamesStr] = getTaskVarnames(task)

% check arguments
if ~any(nargin == [1])
  help getTaskVarnames
  return
end

% if passed in view, then lookup varnames for the view
if (exist('isview')==2) && isview(task)
  % task is really a view
  v = task;
  % get the stimfiles
  s = viewGet(v,'stimfile');
  % get the varnames for each stimfile
  varnames = {};
  for i = 1:length(s)
    [thisVarnames] = getTaskVarnames(s{i}.task);
    varnames = union(thisVarnames,varnames);
  end
  % create the varnamesStr
  varnamesStr = '';
  if ~isempty(varnames)
    varnamesStr = varnames{1};
    for j = 2:length(varnames)
      varnamesStr = sprintf('%s, %s',varnamesStr,varnames{j});
    end
  end
  return
end
  
% make into a cell array of cell arrays
task = cellArray(task,2);

varnames = {};
for taskNum = 1:length(task)
  for phaseNum = 1:length(task{taskNum})
    % look in parameter for parameter names
    fields = fieldnames(task{taskNum}{phaseNum}.parameter);
    for fieldNum = 1:length(fields)
      % real vars don't end in _
      if fields{fieldNum}(end) ~= '_'
	varnames{end+1} = fields{fieldNum};
      end
    end
    %  or in randVars
    if isfield(task{taskNum}{phaseNum},'randVars')
      fields = fieldnames(task{taskNum}{phaseNum}.randVars);
      for fieldNum = 1:length(fields)
	% real vars don't end in _
	if fields{fieldNum}(end) ~= '_'
	  varnames{end+1} = fields{fieldNum};
	end
      end
    end
  end
end

% get unique names, and remove default name
varnames = unique(varnames);
varnames = setdiff(varnames,'default');

% also return string array of variable names
if length(varnames)
  varnamesStr = varnames{1};
  for i = 2:length(varnames)
    varnamesStr = sprintf('%s, %s',varnamesStr,varnames{i});
  end
else
  varnamesStr = '';
end

% cellArray.m
%
%      usage: var = cellArray(var,<numLevels>)
%         by: justin gardner
%       date: 04/05/07
%    purpose: when passed a single structure it returns it as a
%    cell array of length 1, if var is already a cell array just
%    passes it back. numLevels controls how many levels of
%    cell array you want, usually this would be one, but
%    if you wanted to make sure you have a cell array of cell
%    arrays then set it to two.
%  
% 
% e.g.:
% c = cellArray('this')
%
function var = cellArray(var,numLevels)

% check arguments
if ~any(nargin == [1 2])
  help cellArray
  return
end

% make the variable name
varName = 'var';

for i = 1:numLevels
  % for each level make sure we have a cell array
  % if not, make it into a cell array
  if ~iscell(eval(varName))
    tmp = var;
    clear var;
    var{1} = tmp;
  end
  % test the next level
  varName = sprintf('%s{1}',varName);
end



