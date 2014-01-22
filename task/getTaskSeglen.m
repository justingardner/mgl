% getTaskSeglen.m
%
%        $Id:$ 
%      usage: [seglen task] = getTaskSeglen(task)
%         by: justin gardner
%       date: 09/17/13
%    purpose: Helper function called by initTask (for precomputed segs) and updateTask
%             which looks at the settings in task for seglens and computes a random
%             set of seglens. Note that this sets the randomization state for trialState
%             so that if you set the trialState randomization you can get the same sequence
%             of trial lengths again. Make sure to accept the 2nd argument task so that
%             the randomization gets updated.           
%
function [seglen task] = getTaskSeglen(task)

% check arguments
if ~any(nargin == [1])
  help getTaskSeglen
  return
end

% set the random state
randstate = rand(task.randstate.type);
rand(task.randstate.type,task.randstate.trialState);

% for time in ticks and vols, we want an integer value
if (task.timeInTicks || task.timeInVols)
  seglen = task.segmin + floor(rand(1,numel(task.segmax)).*(task.segmax-task.segmin+1));
else
  seglen = task.segmin + rand(1,numel(task.segmax)).*(task.segmax-task.segmin);
 seglen(isinf(task.segmin) | isinf(task.segmax)) = inf;
end

% if any of the seglen are nan then we must choose a value from segdur
nansegs = find(isnan(seglen));
if ~isempty(nansegs)
  for iSeg = nansegs
    % get one of the segdur durations with the right associated probability
    seglen(iSeg) = task.segdur{iSeg}(sum(rand > task.segprob{iSeg}));
  end
end

% remember the status of the random number generator
task.randstate.trialState = rand(task.randstate.type);
% and reset it to what it was before this call
rand(task.randstate.type,randstate);



