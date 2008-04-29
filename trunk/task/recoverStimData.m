% recoverStimData.m
%
%      usage: recoverStimData()
%         by: justin gardner
%       date: 04/29/08
%    purpose: Run this function if you accidently stopped your
%    stimulus program while it was running (or the program
%    crashed) and you are at the debugger prompt K>>). This
%    will spit out some lines of matlab code. Copy these lines
%    and then paste them back to run them. (It needs to be done
%    this way since the program has to search up and down the stack
%    for the correct variables by using dbup/dbdown which can't be
%    used inside a function). This will find your myscreen and task
%    variables and then call saveStimData to save
%    them. Alternatively you can always go look for your myscreen
%    and task variables yourself and call saveStimData. Just be
%    sure that you get the full task variable and not just one
%    part of the task cell array.
%  
% 
%
%function retval = recoverStimData()

% check the stack
[st stackIndex] = evalin('caller','dbstack');
% make sure we are at bottom of stack. 
% Note that we use eval to make this whole string of commands to avoid
% a lot of weirdness with code jumping up and down contexts
evalstr = '';
for i = 1:length(st)-2
  evalstr = sprintf('%sdbdown\n',evalstr);
end

% now look for a myscreen and task
% basically the further up the stack we are the
% better off we are since lower parts of stack
% may have only a part of the task variable. However
% the top part of the stack may have myscreen or task
% in a state where it cannot be used (since it is in
% the middle of being set by a calling routine
% start with recoveredData set to empty
assignin('base','recoveredMyscreen',[]);
assignin('base','recoveredTask',[]);
for i = 1:length(st)-2
  % if myscreen variable exists then assign it in base context
  evalstr = sprintf('%sif exist(''myscreen'',''var''),',evalstr);
  evalstr = sprintf('%sassignin(''base'',''recoveredMyscreen'',myscreen);end\n',evalstr);

  % if task variable exists then assign it in base context
  evalstr = sprintf('%sif exist(''task'',''var''),',evalstr);
  evalstr = sprintf('%sassignin(''base'',''recoveredTask'',task);end\n',evalstr);
  
  % go up one context
  if i ~= length(st)
    evalstr = sprintf('%sdbup\n',evalstr);
  end
end

% now check to see if we have recovered anything and save
evalstr = sprintf('%sif ~isempty(recoveredTask) && ~isempty(recoveredMyscreen)\n',evalstr);
evalstr = sprintf('%s  recoveredMyscreen.saveData = -1;\n',evalstr);
evalstr = sprintf('%s  saveStimData(recoveredMyscreen,recoveredTask);\n',evalstr);
evalstr = sprintf('%selseif ~isempty(recoveredTask)\n',evalstr);
evalstr = sprintf('%s  errstr = ''(recoverStimData) Only found task variable.'';\n',evalstr);
evalstr = sprintf('%s  recoveredMyscreen.datadir = ''.'';\n',evalstr);
evalstr = sprintf('%s  recoveredMyscreen.saveData = -1;\n',evalstr);
evalstr = sprintf('%s  recoveredMyscreen.stimulusNames = {};\n',evalstr);
evalstr = sprintf('%s  disp(errstr);\n',evalstr);
evalstr = sprintf('%s  saveStimData(recoveredMyscreen,recoveredTask);\n',evalstr);
evalstr = sprintf('%selseif ~isempty(recoveredMyscreen)\n',evalstr);
evalstr = sprintf('%s  errstr = ''(recoverStimData) Only found myscreen variable.'';\n',evalstr);
evalstr = sprintf('%s  recoveredMyscreen.saveData = -1;\n',evalstr);
evalstr = sprintf('%s  disp(errstr);\n',evalstr);
evalstr = sprintf('%s  saveStimData(recoveredMyscreen,[]);\n',evalstr);
evalstr = sprintf('%selse\n',evalstr);
evalstr = sprintf('%s  errstr = ''(recoverStimData) Could not find myscreen or task variable.'';\n',evalstr);
evalstr = sprintf('%s  disp(errstr);\n',evalstr);
evalstr = sprintf('%send',evalstr);

disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
disp('% Copy the lines of code below and then run them by %');
disp('% pasting them back into your matlab buffer         %');
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
disp(evalstr);
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
disp('% Copy the lines of code above and then run them by %');
disp('% pasting them back into your matlab buffer         %');
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
