% initStimulus.m
%
%      usage: [stimulus myscreen] = 
%               initStimulus(stimulus, myscreen, task, stimulusFunctions)
%         by: justin gardner
%       date: 05/01/06
%    purpose: 
%
function [stimulus task myscreen] = initStimulus(stimulus, task, myscreen, varargin)

% check arguments
if ~any(nargin == [4])
  help initStimulus
  return
end

% run the stimulus init functions
for i = 1:length(varargin)
  [stimulus task myscreen] = feval(varargin{i},stimulus,task,myscreen);
end

% remember that we have been initialized
stimulus.init = 1;

