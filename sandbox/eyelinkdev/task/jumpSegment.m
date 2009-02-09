% jumpSegment.m
%
%      usage: task = jumpSegment(task,segnum)
%         by: justin gardner
%       date: 04/23/07
%    purpose: jumps to a segment
%      usage: jump to next semgent
%             task = jumpSegment(task) 
%             % jump to end of trial
%             task = jumpSegment(task,inf);
%             % jump to specified segment 3
%             task = jumpSegment(task,3);
%
function task = jumpSegment(task,segnum)

% check arguments
if ~any(nargin == [1 2])
  help jumpToSegment
  return
end

if ~exist('segnum','var')
  task.thistrial.seglen(task.thistrial.thisseg) = mglGetSecs-task.thistrial.segstart;
elseif isinf(segnum)
  task.thistrial.seglen(task.thistrial.thisseg) = mglGetSecs-task.thistrial.segstart;
  task.thistrial.seglen(task.thistrial.thisseg+1:end) = 0;
  task.thistrial.thisseg = length(task.thistrial.seglen);
elseif (segnum > task.thistrial.thisseg)
  task.thistrial.seglen(task.thistrial.thisseg) = mglGetSecs-task.thistrial.segstart;
  task.thistrial.seglen(task.thistrial.thisseg+1:(segnum-1)) = 0;
  task.thistrial.thisseg = segnum-1;
end


