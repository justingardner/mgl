% removeTaskFunctionHandles.m
%
%        $Id$
%      usage: removeTaskFunctionHandles()
%         by: justin gardner
%       date: 09/19/06
%    purpose: removes the function handles from task, since
%             if you load up in another system matlab gives
%             warnings
%  copyright: (c) 2006 Justin Gardner (GPL see mgl/COPYING)
%
function task = removeTaskFunctionHandles(task)

% check arguments
if ~any(nargin == [1])
  help removeTaskFunctionHandles
  return
end

% if this is just a variable check
% for callback and remove it
if ~iscell(task)
  % if there is a callback field 
  if isfield(task,'callback')
    % then convert all its fields to strings
    callbackNames = fieldnames(task.callback);
    for i = 1:length(callbackNames)
      eval(sprintf('task.callback.%s = func2str(task.callback.%s);',callbackNames{i},callbackNames{i}));
    end
  end
  return
end

% otherwise go throgh each cell and call recursively
for tnum = 1:length(task)
  task{tnum} = removeTaskFunctionHandles(task{tnum});
end
