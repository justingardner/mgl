% endTask.m
%
%        $Id$
%      usage: myscreen = endTask(myscreen,task)
%         by: justin gardner
%       date: 09/18/06
%    purpose: packages all variables into myscreen
%             and reports any thrown errors
%  copyright: (c) 2006 Justin Gardner (GPL see mgl/COPYING)
%
function myscreen = endTask(myscreen,task)

% check arguments
if ~any(nargin == [2])
  help endTask
  return
end

mydisp(sprintf('(endTask) Ending task...\n'));

% if there are calculated random variables, in the last trial, save them
task = saveCalculatedVariables(task);

% compute traces and save data
myscreen = endScreen(myscreen);
% This funciton will check for existing stim files and update the save
% number appropriately. This should ensure that the eyelink data will always
% matched, as the stim and eyelink will have the same file number.
myscreen = saveStimData(myscreen,task);

% end eye tracker
if myscreen.eyetracker.init && isfield(myscreen.eyetracker.callback, 'endTracking')
  feval(myscreen.eyetracker.callback.endTracking,task,myscreen);
end

% write task log if needed
if mglGetParam('writeTaskLog')
  % only write log if stimfile has been saved
  if ~isfield(myscreen,'stimfile') || ~isempty(myscreen.stimfile)
    mglTaskLog(myscreen);
  end
end

mydisp(sprintf('(endTask) Done\n'));
% we are done
myscreen.task = task;
% package up stimuli
myscreen.stimuli = '';
for stimulusNum = 1:length(myscreen.stimulusNames)
  eval(sprintf('global %s;',myscreen.stimulusNames{stimulusNum}));
  eval(sprintf('myscreen.stimuli{end+1} = %s;',myscreen.stimulusNames{stimulusNum}));
end

% switch back to current directory
if isfield(myscreen,'pwd') && isdir(myscreen.pwd)
  cd(myscreen.pwd);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    saveCalculatedVariables    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function task = saveCalculatedVariables(task)

if iscell(task)
  for i = 1:length(task)
    task{i} = saveCalculatedVariables(task{i});
  end
  return
else
  if task.randVars.calculated_n_
    for nVar = 1:task.randVars.calculated_n_
      if isfield(task.thistrial,task.randVars.calculated_names_{nVar})
	% get the variable name we are working on
	thisRandVarName = task.randVars.calculated_names_{nVar};
	% then store away the value calculated on the last trial
	if iscell(task.randVars.(thisRandVarName))
	  % cell array
	  task.randVars.(thisRandVarName){task.trialnum} = task.thistrial.(thisRandVarName);
	else
	  % regular array
	  task.randVars.(thisRandVarName)(task.trialnum) = task.thistrial.(thisRandVarName);
	end
	  
      end
    end
  end
end
  
  