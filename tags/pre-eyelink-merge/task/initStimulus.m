% initStimulus.m
%
%        $Id$
%      usage: [stimulus myscreen] = 
%               initStimulus(stimulusName, myscreen)
%         by: justin gardner
%       date: 05/01/06
%    purpose: init the stimulus variable (and register it in myscreen)
%  copyright: (c) 2006 Justin Gardner (GPL see mgl/COPYING)
%       e.g.:
%global myStimulus;
%[myscreen] = initStimulus('myStimulus',myscreen);
%
function [myscreen] = initStimulus(stimulusName, myscreen)

% check arguments
if ~any(nargin == [2])
  help initStimulus
  return
end

eval(sprintf('global %s',stimulusName));

% remember that we have been initialized
eval(sprintf('%s.init = 1;',stimulusName));

% save the stimulus name
if ~isfield(myscreen,'stimulusNames')
  myscreen.stimulusNames{1} = stimulusName;
else
  notfound = 1;
  for i = 1:length(myscreen.stimulusNames)
    if (strcmp(myscreen.stimulusNames{i},stimulusName))
      disp(sprintf('There is already a stimulus called %s registered in myscreen',stimulusName));
      notfound = 0;
    end
  end
  if notfound
    myscreen.stimulusNames{end+1} = stimulusName;
  end
end


