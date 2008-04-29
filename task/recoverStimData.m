% check the stack
[st stackIndex] = dbstack;

% make sure we are at bottom of stack. Note that we use
% eval to make this whole string of commands to avoid
% a lot of weirdness with code jumping up and down contexts
evalstr = '';
for i = 1:stackIndex-1
  evalstr = sprintf('%sdbdown;',evalstr);
end
% now go up through stack looking for
% a myscreen or task variable which we can save
% basically the further up the stack we are the
% better off we are since lower parts of stack
% may have only a part of the task variable. However
% the top part of the stack may have myscreen or task
% in a state where it cannot be used (since it is in
% the middle of being set by a calling routine
% start with recoveredData set to empty
assignin('base','recoveredMyscreen',[]);
assignin('base','recoveredTask',[]);
for i = 1:length(st)
  % if myscreen variable exists then assign it in base context
  evalstr{i} = sprintf('%sif exist(''myscreen'',''var''),',evalstr{i});
  evalstr{i} = sprintf('%sassignin(''base'',''recoveredMyscreen'',myscreen);end,',evalstr{i});

  % if task variable exists then assign it in base context
  evalstr = sprintf('%sif exist(''task'',''var''),',evalstr);
  evalstr = sprintf('%sassignin(''base'',''recoveredTask'',task);end,',evalstr);
  
  % go up one context
  if i ~= length(st)
    evalstr = sprintf('%sdbup,',evalstr);
  end
end

eval(evalstr);
keyboard
% check to see if we have the correct fields
if isfield(recoveredData,'task') && isfield(recoveredData,'myscreen')
  recoveredData.myscreen.saveData = -1;
  saveStimData(recoveredData.myscreen,recoveredData.task);
elseif isfield(recoveredData,'task')
  disp(sprintf('(recoverStimData) Could only get task information. Setting as recoveredTask in local environment'));
  assignin('caller','recoveredTask',recoveredData.task);
elseif isfield(recoveredData,'myscreen')
  disp(sprintf('(recoverStimData) Could only get myscreen information. Setting as recoveredMyscreen in local environment'));
  assignin('caller','recoveredMyscreen',recoveredData.myscreen);
else
  disp(sprintf('(recoverStimData) Could not get myscreen or task information'));
end
