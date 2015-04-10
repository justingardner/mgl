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
%             getStimvolFromVarname('dir',myscreen,task,2,2);
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
%             Or it can be _every_ which returns every combination of different parameters as a separate
%             trial type. So, for example if you have 3 speeds and 2 directions, it will create 6 different
%             types
%
%             getStimvolFromVarname('_every_',myscreen,task);
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
%             This will return two sets of stimvols. One in which var1=1 and var2 = 2 or 3
%             and another set in which var1=2 and var2=1
%
%             If you want to return a set of stimvols for each value of a
%             different variable, say var1 and var2 which can have values
%             var1 = 1 or 2 and var2 = 3 or 4, Then use a comma separated list
% 
%             getStimvolFromVarname('var1,var2',myscreen,task);
%
%             This will then return 4 stimvols, one in which var1 =1, one in which
%             var1 = 2, one in which var2 = 3 and one in which var2 = 4. Note
%             that these are not guaranteed to be non-overlapping stimvols
%
%             If you want to get the cross between different variables, then
%             put _x_ between the variable names
%
%             getStimvolFromVarname('var1_x_var2',myscreen,task)
%
%             Following the example above, this will return 4 sets of stimvols
%             One in which var1 = 1 and var2 = 3, one in which var1 = 1 and var2 = 4
%             one in which var1 = 2 and var2 = 3 and one in which var1 = 2 and var2 = 4
%
function [stimvolOut stimNamesOut trialNumOut] = getStimvolFromVarname(varnameIn,myscreen,task,taskNum,phaseNum,segmentNum)

stimvolOut = {};
stimNamesOut = {};
trialNumOut = {};
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
  if isfield(varnameIn,'segmentBegin') && isfield(varnameIn,'segmentEnd')
    segmentNum = [varnameIn.segmentBegin varnameIn.segmentEnd];
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

% used for rounding variable values to a tractable number
% of significant figures. i.e. if your value is 0.5000000001
% that is hard to represent in a string, it will get rounded
% to 0.5. If you actually need all the significant figures
% you might need to up this value here. The value of 7 is set
% so that if you use sprintf('%f',val) you will represent
% the default number of significant figures
numSigDigits = 7;

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

if iscell(varnameIn)
  % make into a 2 level cell array, one element for each set of conditions
  varnameIn = cellArray(varnameIn,2);
  % the purpose of this code is to handle the {} cell array conditions
  % for every cell aray element
  for iVarname = 1:length(varnameIn)
    % we are going to create a single entry in the stimvolOut and other arrays
    thisVarnameIn = varnameIn{iVarname};
    stimvolOut{iVarname} = [];
    % each element may have several conditions like: side=1 or contrast=[0.5 1]
    for iCond = 1:length(thisVarnameIn)
      thisCond = thisVarnameIn{iCond};
      % recursively call this fucntion to get the current condition
      [stimvol stimNames trialNum] = getStimvolFromVarname(thisCond,myscreen,task,taskNum,phaseNum,segmentNum);
      if isempty(stimvolOut{iVarname}) 
	% first time, just get stimvols /names and trial nums
	stimvolOut{iVarname} = stimvol;
	stimNamesOut{iVarname} = stimNames;
	trialNumOut{iVarname} = trialNum;
      else
	% next times, combine what we already have with the new condition
	oldStimvolOut = stimvolOut;oldStimNamesOut = stimNamesOut;oldTrialNumOut = trialNumOut;
	stimvolOut{iVarname} = [];stimNamesOut{iVarname} = {};trialNumOut{iVarname} = {};
	for iOldStimvolOut = 1:length(oldStimvolOut{iVarname})
	  % intersect each condition with existing conditions and union them together
	  for iStimvol = 1:length(stimvol)
	    if iStimvol == 1
	      stimvolOut{iVarname}{1} = intersect(oldStimvolOut{iVarname}{iOldStimvolOut},stimvol{iStimvol});
	      stimNamesOut{iVarname}{1} = sprintf('(%s & %s)',oldStimNamesOut{iVarname}{iOldStimvolOut},stimNames{iStimvol});
	      trialNumOut{iVarname}{1} = intersect(oldTrialNumOut{iVarname}{iOldStimvolOut},trialNum{iStimvol});
	    else
	      stimvolOut{iVarname}{1} = union(stimvolOut{iVarname}{1},intersect(oldStimvolOut{iVarname}{iOldStimvolOut},stimvol{iStimvol}));
	      stimNamesOut{iVarname}{1} = sprintf('%s or (%s & %s)',stimNamesOut{iVarname}{1},oldStimNamesOut{iVarname}{iOldStimvolOut},stimNames{iStimvol});
	      trialNumOut{iVarname}{1} = union(trialNumOut{iVarname}{1},intersect(oldTrialNumOut{iVarname}{iOldStimvolOut},trialNum{iStimvol}));
	    end
	  end
	end
      end
    end
  end
  % make into a cell array with depth 1 (the procedure above returns a cell array of cell arrays
  oldStimvolOut = stimvolOut;oldStimNamesOut = stimNamesOut;oldTrialNumOut = trialNumOut;
  stimvolOut = oldStimvolOut{1};
  stimNamesOut = oldStimNamesOut{1};
  trialNumOut = oldTrialNumOut{1};
  for iVarname = 2:length(oldStimvolOut)
    stimvolOut = {stimvolOut{:} oldStimvolOut{iVarname}{:}};
    stimNamesOut = {stimNamesOut{:} oldStimNamesOut{iVarname}{:}};
    trialNumOut = {trialNumOut{:} oldTrialNumOut{iVarname}{:}};
  end
  return
end

% check to see if the varnameIn is a comma separated list. In which
% case we return the stimvols for each variable in the list concatenated
% together
if ~isempty(strfind(varnameIn,','))
  % go through each of the varnames
  while ~isempty(varnameIn)
    % get this varname
    [thisVarname varnameIn] = mystrtok(varnameIn,',');
    % recursively call this fucntion to get the current variable name
    [stimvol stimNames trialNum] = getStimvolFromVarname(thisVarname,myscreen,task,taskNum,phaseNum,segmentNum);
    % set in output argument
    stimvolOut = {stimvolOut{:} stimvol{:}};
    stimNamesOut = {stimNamesOut{:} stimNames{:}};
    trialNumOut = {trialNumOut{:} trialNum{:}};
  end
  return
end

% check to see if the varnameIn is a _x_ separated list. In which
% case we return the stimvols for each variable crossed with each other variable
if ~isempty(strfind(varnameIn,'_x_'))
  crossStimvol = [];crossStimNames = [];crossTrialNum = [];
  % go through each of the varnames
  while ~isempty(varnameIn)
    % get this varname
    [thisVarname varnameIn] = mystrtok(varnameIn,'_x_');
    % recursively call this fucntion to get the current variable name
    [stimvol stimNames trialNum] = getStimvolFromVarname(thisVarname,myscreen,task,taskNum,phaseNum,segmentNum);
    % first time, just set the cross variables
    if isempty(crossStimvol)
      crossStimvol = stimvol;
      crossStimNames = stimNames;
      crossTrialNum = trialNum;
    else
      % next time we cross each new variable with the last one
      newCrossStimvol = {};newCrossStimNames = {};newCrossTrialNum = {};
      for iCross = 1:length(crossStimvol)
	for iStimvol = 1:length(stimvol)
	  [newCrossStimvol{end+1} crossIndex] = intersect(crossStimvol{iCross},stimvol{iStimvol});
	  newCrossStimNames{end+1} = sprintf('%s and %s',crossStimNames{iCross},stimNames{iStimvol});
	  newCrossTrialNum{end+1} = crossTrialNum{iCross}(crossIndex);
	end
      end
      crossStimvol = newCrossStimvol;
      crossStimNames = newCrossStimNames;
      crossTrialNum = newCrossTrialNum;
    end
  end
  % set in output argument
  stimvolOut = {stimvolOut{:} crossStimvol{:}};
  stimNamesOut = {stimNamesOut{:} crossStimNames{:}};
  trialNumOut = {trialNumOut{:} crossTrialNum{:}};
  return
end
% now check if we have been called with two segmentNums in which
% case we should return volumes from the beginning semgent num to
% the end segment num, so we recursively call this function to get
% the start segment and end segment and then create a stimvol cell
% array that contains all the intervening volumes
if length(segmentNum) == 2
  [stimvol1 stimNamesOut trialNum1] = getStimvolFromVarname(varnameIn,myscreen,task,taskNum,phaseNum,segmentNum(1));
  [stimvol2 stimNamesOut] = getStimvolFromVarname(varnameIn,myscreen,task,taskNum,phaseNum,segmentNum(2));
  % add all volumes from start to end
  for i = 1:length(stimvol1)
    stimvolOut{i} = [];
    trialNumOut{i} = [];
    for j = 1:length(stimvol1{i})
      if length(stimvol2{i}) >= j
	stimvolOut{i} = [stimvolOut{i} stimvol1{i}(j):stimvol2{i}(j)];
	trialNumOut{i} = [trialNumOut{i} repmat(trialNum1{i}(j),1,length(stimvol1{i}(j):stimvol2{i}(j)))];
      end
    end
  end
  return
end

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

% handle when the varname is every (which means to make every combination of variables
if (length(varname{1}) == 1) && strcmp(varname{1}{1},'_every_')
  varname = makeEveryCombination(e{taskNum}(phaseNum).parameter,numSigDigits);
end

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
        if length(e{taskNum}(phaseNum).trials(trialNum).volnum) >= segmentNum
	      stimvolOut{1}(trialNum) = e{taskNum}(phaseNum).trials(trialNum).volnum(segmentNum);
	      trialNumOut{1}(trialNum) = trialNum;
        end
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
	    varval = getVarFromParameters(mystrtok(varname{i}{j},'='),e{tnum}(pnum));
	    % check to make sure it is not empty
	    if isempty(varval)
	      disp(sprintf('(getStimvolFromVarname) Could not find variable %s in task %i phase %i',mystrtok(varname{i}{j},'='),tnum,pnum));
	      return;
	    end
	    % see if it is a strict variable name
	    if isempty(strfind(varname{i}{j},'='))
	      % if it is then for each particular setting
	      % of the variable, we make a stim type. Use getVarFromParameters
	      % to return all the possible settings for the variable
	      vartypes = getVarFromParameters(varname{i}{j},e{tnum}(pnum),1);
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
	    varval = getVarFromParameters(mystrtok(varname{i}{j},'='),e{tnum}(pnum));
	    % round the values to numSigDigits. This is so that if you have
	    % multiple significant digits you still get the string to match, which
	    % won't have as many significant digits. (e.g. if your value was pi, and
	    % your reperesnt as a string, you will lose some digits). First remember how many unique
	    % values we have so that we can spit out a warning if this manipulation
	    % causes some conditions to get grouped together (i.e. this would happen
	    % if you have a variable that only difference after the numSigDigitis decimal place)
	    if isnumeric(varval)
	      nUniqueVarval = length(unique(varval));
	      varval = round(varval*10^numSigDigits)/10^numSigDigits;
	      if length(unique(varval)) ~= nUniqueVarval
		disp(sprintf('(getStimvolFromVarname) WARNING: Variable %s has values that only differe after %i significant figures that will be grouped together',mystrtok(varname{i}{j},'='),numSigDigits));
	      end
	    end
	    % see if it is a conditional variable, that is,
	    % one that is like var=[1 2 3].
	    if ~isempty(strfind(varname{i}{j},'='))
	      [t,r] = mystrtok(varname{i}{j},'=');
	      varcond = mystrtok(r,'=');
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
		trialNumOut{k} = find(stimvol{i}{j});
	      else
		stimvolOut{k} = trialVolume(stimvol{i}{j});
		stimNamesOut{k} = stimnames{i}{j};
		trialNumOut{k} = find(stimvol{i}{j});
	      end
	      k = k+1;
	    end
	  end
	end
      end
    end
  end
end

% remove any 0 stimvols (this happens if a trial occurs
% before the experiment started)
for i = 1:length(stimvolOut)
  if any(stimvolOut{i} == 0)
    disp(sprintf('(getStimvolFromVarname) !!! Removing %i trials that occurred before scanning !!!',sum(stimvolOut{i}==0)));
    trialNumOut{i} = trialNumOut{i}(stimvolOut{i} ~= 0);
    stimvolOut{i} = stimvolOut{i}(stimvolOut{i} ~= 0);
  end
end

% remove any nan stimvols (this happens if a trial occurs
% after the end of the experiment)
for i = 1:length(stimvolOut)
  trialNumOut{i} = trialNumOut{i}(~isnan(stimvolOut{i}));
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    makeEveryCombination    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varname = makeEveryCombination(p,numSigDigits)

% get parameter names and number
p = initRandomization(p);
parameterNames = p.names_;
numParameters = p.n_;

% get all parameter values
for i = 1:numParameters
  parameterValues{i} = unique(p.(parameterNames{i}));
  parameterLength(i) = length(parameterValues{i});
end

% now go through and make each combination
for i = 1:prod(parameterLength)
  % figure out what value to set each parameter to. Do this by creating
  % a command which will set the variables x1, x2, xi to the index
  % for each parameter value to set to for the ith combination
  evalStr = '[';
  for j = 1:numParameters
    evalStr = sprintf('%s x%i',evalStr, j);
  end
  evalStr = sprintf('%s] = ind2sub(parameterLength,i);',evalStr);
  eval(evalStr);
  % now that x1, x2, xi equal what index for each parameter, make the correct
  % string for each parameter
  for j = 1:numParameters
    eval(sprintf('val = parameterValues{j}(x%i);',j));
    varname{i}{j} = sprintf(sprintf('%%s=%%.%if',numSigDigits),parameterNames{j},val);
  end
end

%%%%%%%%%%%%%%%%%%
%    mystrtok    %
%%%%%%%%%%%%%%%%%%
function [tok str] = mystrtok(str,delim)

% like strtok but treats the delim as a string
% you have to search for: e.g. '_x_' and
% strips the tokens of leading/trailing white space

delimloc = findstr(delim,str);
% no token return whole string
% stripping whitespace from beginning and end
if isempty(delimloc)
  tok = strtrim(str);
  str = '';
else
  tok = strtrim(str(1:delimloc(1)-1));
  str = str(delimloc(1)+length(delim):end);
end

