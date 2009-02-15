% getStimvolFromVarname.m
%
%      usage: [stimvol stimNames] = getStimvolFromVarname(varnameIn,myscreen,task,[taskNum],[phaseNum],[segmentNum],[verbose])
%         by: justin gardner
%       date: 03/15/07
%    purpose: returns the volume numbers for the stimulus variable in stimvol and also
%             a string which describes the parameter setting in stimNames.
%
%             varnameIn can be the name of a parameter or randVar. e.g.:
%
%             getStimvolFromVarname('dir',myscreen,task,'taskNum=2','phaseNum=2');
%
%             It can also be of the form varname(indexVar). For when you have used
%             a parameterCode and an index variable. e.g.:
% 
%             getStimvolFromVarname('localDir(dirIndex)',myscreen,task);
%
%             Or it can be _all_ which returns all trial numbers regardless of stimulus type:
%
%             getStimvolFromVarname('_all_',myscreen,task);
%
%             If varnameIn is a cell array, then you can specify a set of matching
%             conditions. For example, the following would return the stimvols for
%             when var1 = 1 *and* var2 = either 2 or 3:
%
%             {'var1=[1]','var2=[2 3]'}
%
%             If you want to return multiple sets of stimvols with matching conditions,
%             you can make a cell array of cell arrays of the type form above. For example:
%
%             {{'var1=[1]','var2=[2 3]'},{'var1=[2]','var2=[1]'}}
%
%
function [stimvolOut stimNamesOut] = getStimvolFromVarname(varnameIn,myscreen,task,taskNum,phaseNum,segmentNum)

stimvolOut = {};
stimNamesOut = {};
% check arguments
if ~any(nargin == [3 4 5 6 7])
  help getStimvolFromVarname
  return
end

% structure passed in, can have fields for taskNum,phaseNum and varname
if isstruct(varnameIn) 
  if isfield(varnameIn,'segmentNum')
    segmentNum = varnameIn.segmentNum;
  end
  if isfield(varnameIn,'taskNum')
    taskNum = varnameIn.taskNum;
  end
  if isfield(varnameIn,'phaseNum')
    phaseNum = varnameIn.phaseNum;
  end
  if isfield(varnameIn,'verbose')
    verbose = varnameIn.verbose;
  end
  if isfield(varnameIn,'varname')
    varnameIn = varnameIn.varname;
  else
    disp('Passed in structure must have field varname');
    return
  end
end

% get default task numbers and phase numbers
if ~exist('taskNum','var'),taskNum = 1:length(task);end
if ~exist('segmentNum','var'),segmentNum = 1;end
if ~exist('phaseNum','var')
  phaseNum = 1;
  for tnum = 1:length(task)
    if length(task{tnum})>phaseNum
      phaseNum = length(task{tnum});
    end
  end
  phaseNum = 1:phaseNum;
end
if ~exist('verbose','var'),verbose = true;end

if verbose
  disp(sprintf('(getStimvolFromVarname) taskNum=[%s], phaseNum=[%s], segmentNum=[%s]',num2str(taskNum),num2str(phaseNum),num2str(segmentNum)));
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
% make sure it is a cell array
if ~iscell(e),olde = e;clear e;e{1} = olde;,end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% check, if we have a single varname and that name is _all_, then
% we want to concatenate together all the trial types
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (length(varname) == 1) && (length(varname{1}) == 1) && strcmp(varname{1}{1},'_all_')
  % make sure that taskNum & phaseNum are in range, and then
  % extract volnum for every trial
  if ((taskNum > 0) && (taskNum <= length(e)))
    if (phaseNum > 0) && (phaseNum <= length(e{taskNum}))
      if length(e{taskNum}(phaseNum).trials) > 0
	if (segmentNum > 0) && (segmentNum <= length(e{taskNum}(phaseNum).trials(1).volnum))
	  % if we passed all the checks, then get the volume number for each trial
	  for trialNum = 1:length(e{taskNum}(phaseNum).trials)
	    stimvolOut{1}(trialNum) = e{taskNum}(phaseNum).trials(trialNum).volnum(segmentNum);
	  end
	else
	  disp(sprintf('(getStimvolFromVarname) SegmentNum %i out of range [1 %i]',segmentNum,length(e{taskNum}(phaseNum).trials(1).volnum)));
	  keyboard
	end
      else
	disp(sprintf('(getStimvolFromVarname) No trials found'));
	keyboard
      end
    else
      disp(sprintf('(getStimvolFromVarname) PhaseNum %i out of range [1 %i]',phaseNum,length(e{taskNum})));
      keyboard
    end
  else
    disp(sprintf('(getStimvolFromVarname) TaskNum %i out of range [1 %i]',taskNum,length(e)));
    keyboard
  end
  
  % set the stim name
  stimNamesOut{1} = '_all_';
else
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% processing for all other stimvol names
% cycle through the task/phases, when we have a match go look for
% the stimvosl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  for tnum = 1:length(e)
    for pnum = 1:length(e{tnum})
      % see if we have a match
      if any(tnum == taskNum) && any(pnum == phaseNum)
	% now cycle over all array elements
	for i = 1:length(varname)
	  stimvol{i} = {};
	  stimnames{i} = {};
	  % cycle over all strings in varname
	  for j = 1:length(varname{i})
	    % get the value of the variable in question
	    % on each trial
	    varval = getVarFromParameters(strtok(varname{i}{j},'='),e{tnum}(pnum));
	    % check to make sure it is not empty
	    if isempty(varval)
	      disp(sprintf('(getStimvolFromVarname) Could not find variable %s in task %i phase %i',strtok(varname{i}{j},'='),tnum,pnum));
	      return;
	    end
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
	    varval = getVarFromParameters(strtok(varname{i}{j},'='),e{tnum}(pnum));
	    % see if it is a conditional variable, that is,
	    % one that is like var=[1 2 3].
	    if ~isempty(strfind(varname{i}{j},'='))
	      [t,r] = strtok(varname{i}{j},'=');
	      varcond = strtok(r,'=');
	      % if it is then get the conditions
	      varval = eval(sprintf('ismember(varval,%s)',varcond));
  	      % if we dont have any applied conditions applied then
              % this is the condition
	      if isempty(stimvol{i})
		stimvol{i}{1} = varval;
		stimnames{i}{1} = varname{i}{j};
	      else
		for k = 1:length(stimvol{i})
		  stimvol{i}{k} = stimvol{i}{k} & varval;
		  stimnames{i}{k} = sprintf('%s %s',stimnames{i}{k},varname{i}{j});
		end
	      end
	    end
	  end
	end
	% select which volume to use, this will normally be the volume at which the
	% trial started, but if the user passes in a segmentNum than we have to return
	% the volume at which that segment occurred
	if segmentNum == 1
	  trialVolume = e{tnum}(pnum).trialVolume;
	else
	  for trialNum = 1: e{tnum}(pnum).nTrials
	    % make sure we have enough segments
	    if segmentNum <= length(e{tnum}(pnum).trials(trialNum).volnum)
	      trialVolume(trialNum) = e{tnum}(pnum).trials(trialNum).volnum(segmentNum);
	    elseif trialNum == e{tnum}(pnum).nTrials
	      % this is last trial, probably just ended in middle
	      % without having that segment. Get rid of volume
	      trialVolume(trialNum) = nan;
	      for sdim1 = 1:length(stimvol)
		for sdim2 = 1:length(stimvol{sdim1})
		  stimvol{sdim1}{sdim2}(trialNum) = 0;
		end
	      end
	    else
	      disp(sprintf('(getStimvolFromVarname) Asked for segment %i but trials only have %i segments',segmentNum,length(e{tnum}(pnum).trials(trialNum).volnum)));
	    end	
	  end
	end	

	% now we convert the trial numbers into volumes
	if exist('stimvol','var')
	  k = 1;
	  for i = 1:length(stimvol)
	    for j = 1:length(stimvol{i})
	      if length(stimvolOut) >= k
		stimvolOut{k} = [stimvolOut{k} trialVolume(stimvol{i}{j})];
		stimNamesOut{k} = [stimNamesOut{k} stimnames{i}{j}];
	      else
		stimvolOut{k} = trialVolume(stimvol{i}{j});
		stimNamesOut{k} = stimnames{i}{j};
	      end
	      k = k+1;
	    end
	  end
	end
      end
    end
  end
end

% remove any nan stimvols (this happens if a trial occurs
% after the end of the experiment)
for i = 1:length(stimvolOut)
  stimvolOut{i} = stimvolOut{i}(~isnan(stimvolOut{i}));
end

% check for non-unique conditions
if length(cell2mat(stimvolOut)) ~= length(unique(cell2mat(stimvolOut)))
  disp(sprintf('(getstimvol) Same trial in multiple conditions.'));
end

% make sure we got something
if isempty(stimvolOut) 
  disp(sprintf('(getStimvolFromVarname) No stimvols found in task %i phase %i',taskNum,phaseNum));
end

% display the number of stimvols and the variable name
if verbose
  for i = 1:length(stimvolOut)
    disp(sprintf('(getStimvolFromVarname) %s: %i trials',stimNamesOut{i},length(stimvolOut{i})));
  end
end
