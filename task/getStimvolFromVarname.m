% getStimvolFromVarname.m
%
%      usage: getStimvolFromVarname()
%         by: justin gardner
%       date: 03/15/07
%    purpose: 
%
function stimvolOut = getStimvolFromVarname(varnameIn,myscreen,task)

% check arguments
if ~any(nargin == [3])
  help getStimvolFromVarname
  return
end

% first make varname into a cell array of cell arrays.
if isstr(varnameIn)
  varname{1}{1} = varnameIn;
else
  % see if this is a cell array of strings
  isArrayOfStr = 1;
  for i = 1:length(varnameIn)
    if ~isstr(varnameIn{i})
      isArrayOfStr = 0;
    end
  end
  %  now if it is an array of strings, then
  % we only have one condition
  if isArrayOfStr
    varname{1} = varnameIn;
  else
    for i = 1:length(varnameIn)
      if isstr(varnameIn{i})
	varname{i}{1} = varnameIn{i};
      else
	varname{i} = varnameIn{i};
      end
    end
  end
end
% get the task parameters
e = getTaskParameters(myscreen,task);
% now cycle over all array elements
for i = 1:length(varname)
  stimvol{i} = {};
  stimnames{i} = {};
  % cycle over all strings in varname
  for j = 1:length(varname{i})
    % get the value of the variable in question
    % on each trial
    [thisvarname varval] = getVarFromParameters(varname{i}{j},e);
    % see if it is a strict variable name
    if isempty(strfind(varname{i}{j},'='))
      % if it is then for each particular setting
      % of the variable, we make a stim type
      vartypes = unique(sort(varval));
      for k = 1:length(vartypes)
	stimvol{i}{end+1} = varval==vartypes(k);
	stimnames{i}{end+1} = sprintf('%s=%s',varname{i}{j},num2str(vartypes(k)));
      end
    end
  end
  % now we cycle through again, looking for any modifiers
  % that is, if we have something like varname=[1 2 3] then
  % it means that we only add the variable in, if it has
  % that var set appropriately. 
  for j = 1:length(varname{i})
    % get the value of the variable in question
    % on each trial
    [thisvarname varval] = getVarFromParameters(varname{i}{j},e);
    % see if it is a conditional variable, that is,
    % one that is like var=[1 2 3].
    if ~isempty(strfind(varname{i}{j},'='))
      [t,r] = strtok(varname{i}{j},'=');
      varcond = strtok(r,'=');
      % if it is then get the conditions
      varval = eval(sprintf('ismember(varval,%s)',varcond));
      % if we don't have any applied conditions applied, then
      % this is the condition
      if isempty(stimvol{i})
	stimvol{i}{1} = varval;
      else
	for k = 1:length(stimvol{i})
	  stimvol{i}{k} = stimvol{i}{k} & varval;
	  stimnames{i}{k} = sprintf('%s %s=%s',stimnames{i}{k},thisvarname,varcond);
	end
      end
    end
  end
end
% find stimvols and put into structure
stimvolOut = {};
for i = 1:length(stimvol)
  for j = 1:length(stimvol{i})
    stimvolOut{end+1} = e.trialVolume(stimvol{i}{j});
  end
end

% check for non-unique conditions
if length(cell2mat(stimvolOut)) ~= length(unique(cell2mat(stimvolOut)))
  disp(sprintf('(getstimvol) Same trial in multiple conditions.'));
end

%%%%%%%%%%%%%%%%%%%%%%%%
% get a variable name
%%%%%%%%%%%%%%%%%%%%%%%%
function [varname varval] = getVarFromParameters(varname,e)

if ~iscell(e)
  olde = e;
  clear e;
  e{1} = olde;
end

varval = '';
enum = [];

% remove any equal sign
varname = strtok(varname,'=');
for i = 1:length(e)
  % see if it is a parameter
  if isfield(e{i}.parameter,varname)
    varval = e{i}.parameter.(varname);
    enum = i;
    % or a rand var
  elseif isfield(e{i},'randVars') && isfield(e{i}.randVars,varname)
    varval = e{i}.randVars.(varname);
    enum = i;
  end
end

if isempty(varval)
  disp(sprintf('(getstimvol) Could not find variable name %s',varname));
end 
