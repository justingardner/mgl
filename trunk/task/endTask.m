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

% compute traces and save data
myscreen = endScreen(myscreen);
saveStimData(myscreen,task);
  
% see if the last error was just the error
% thrown by ending the task
%err = lasterror;
% if not rethrow the error
%if (isempty(strfind(err.message,'taskend')))
%  if isfield(err,'stack')
%    for i = 1:length(err.stack)
%      disp(sprintf('%s at %i',err.stack(i).name, err.stack(i).line));
%    end
%  end
%  rethrow(err);
%else
  mydisp(sprintf('End task\n'));
  % otherwise we are done
  myscreen.task = task;
  % package up stimuli
  myscreen.stimuli = '';
  for stimulusNum = 1:length(myscreen.stimulusNames)
    eval(sprintf('global %s;',myscreen.stimulusNames{stimulusNum}));
    eval(sprintf('myscreen.stimuli{end+1} = %s;',myscreen.stimulusNames{stimulusNum}));
  end
%end


