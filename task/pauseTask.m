% pauseTask.m
%
%        $Id$
%      usage: pauseTask()
%         by: justin gardner
%       date: 10/26/06
%  copyright: (c) 2006 Justin Gardner (GPL see mgl/COPYING)
%    purpose: fix trial timers when the stimulus has been paused
%
function task = pauseTask(task,pauseInterval)

% check arguments
if ~any(nargin == [2])
  help pauseTask
  return
end

if iscell(task)
  for i = 1:length(task)
    task{i} = pauseTask(task{i},pauseInterval);
  end
else
  if isfield(task,'thistrial')
    if isfield(task.thistrial,'trialstart')
      task.thistrial.trialstart = task.thistrial.trialstart+pauseInterval;
    end
    if isfield(task.thistrial,'segstart')
      task.thistrial.segstart = task.thistrial.segstart+pauseInterval;
    end
    if isfield(task.thistrial,'segStartSeconds')
      task.thistrial.segStartSeconds = task.thistrial.segStartSeconds+pauseInterval;
    end
  end
end
