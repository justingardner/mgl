% updateTask - update the task in running in stimulus programs
%
%        $Id$
%      usage: [task, myscreen, tnum] = updateTask(task,myscreen,tnum)
%         by: justin gardner
%       date: 2006-04-27
%  copyright: (c) 2006 Justin Gardner (GPL see mgl/COPYING)
%     inputs: stimulus,task,myscreen,tnum
%    outputs: stimulus task myscreen tnum
%    purpose: runs experimental tasks
%
%   to do: figure out how the globals should work
%          initScreen,tickScreen, and endScreen should be ready
function [task, myscreen, tnum] = updateTask(task,myscreen,tnum)

% make sure we have a valid active task
if tnum > length(task),return,end

% check for a new block
if (task{tnum}.blocknum == 0) || (task{tnum}.blockTrialnum > task{tnum}.block(task{tnum}.blocknum).trialn) 
  % if we have finished how many blocks were called for
  % then we need to go on to the next task
  if (task{tnum}.blocknum == task{tnum}.numBlocks)
    tnum = tnum+1;
    % write out the phase
    myscreen = writeTrace(tnum,task{tnum-1}.phaseTrace,myscreen);
    [task myscreen tnum] = updateTask(task, myscreen, tnum);
    return
  end
  % otherwise init a new block and continue on
  [task{tnum} myscreen] = initBlock(task{tnum},myscreen);
end

% if we have finished how many trials were called for go to next task
if (task{tnum}.trialnum >= task{tnum}.numTrials)
  tnum = tnum+1;
  % write out the phase
  myscreen = writeTrace(tnum,task{tnum-1}.phaseTrace,myscreen);
  [task myscreen tnum] = updateTask(task,myscreen,tnum);
  return
end

% update trial
[task myscreen tnum] = updateTrial(task, myscreen, tnum);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% update trial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task, myscreen tnum] = updateTrial(task, myscreen, tnum)

% set the phase num of the trial
task{tnum}.thistrial.thisphase = tnum;

if task{tnum}.thistrial.waitingToInit
  % init the trial
  [task{tnum} myscreen] = initTrial(task{tnum},myscreen);
end

% get globals
global stimulus;

% see if we are waiting for backtick
if task{tnum}.thistrial.segstart == -inf
  if task{tnum}.thistrial.waitForBacktick
    % only continue if we have received a backtick
    if myscreen.volnum == task{tnum}.thistrial.startvolnum
      return
    else
      % clear waiting status
      task{tnum}.thistrial.waitForBacktick = 0;
    end
  end
  % write out appropriate trace
  myscreen = writeTrace(1,task{tnum}.segmentTrace,myscreen,1);
  myscreen = taskWriteTrace(task{tnum},myscreen);
  % restart segment clock and continue on
  % as if the segment just started
  if task{tnum}.timeInTicks
    task{tnum}.thistrial.trialstart = myscreen.tick;
  elseif task{tnum}.timeInVols
    task{tnum}.thistrial.trialstart = myscreen.volnum;
  else
    thistime = mglGetSecs;
    % calculate trial time discrepancy
    if task{tnum}.trialnum > 1
      % info for the last trial is in lasttrial, so find the
      % difference between the time the trial actually took
      % and how long it was expected to take-how much time
      % we had to make up 
      task{tnum}.timeDiscrepancy = (thistime-task{tnum}.lasttrial.trialstart)-(sum(task{tnum}.lasttrial.seglen)-task{tnum}.timeDiscrepancy);
    end
    task{tnum}.thistrial.trialstart = thistime;
  end
  task{tnum} = resetSegmentClock(task{tnum},myscreen);
  % call segment start callback
  [task{tnum} myscreen] = feval(task{tnum}.callback.startSegment,task{tnum},myscreen);
  % if this segment is set to getResponse(2), then it means that we 
  % are getting response and shutting down flipping of the screen
  % so that we can get better response time for reaction time tasks
  if (task{tnum}.getResponse(task{tnum}.thistrial.thisseg)==2)
    % call the display function now, and flush screen
    %[task{tnum} myscreen] = feval(task{tnum}.callback.screenUpdate,task{tnum},myscreen);
    %mglFlush;
    % now set not to update the screen while we wait for response
    myscreen.oldFlushMode = myscreen.flushMode;
    myscreen.flushMode = 1;
  end
end

% check to see if we have gone over segment time
segover = 0;

% check end of segment in ticks
if task{tnum}.timeInTicks == 1
  if (myscreen.tick - task{tnum}.thistrial.segstart) >= task{tnum}.thistrial.seglen(task{tnum}.thistrial.thisseg)
    segover = 1;
  end
% or the number of ticks
elseif task{tnum}.timeInVols 
  if (myscreen.volnum - task{tnum}.thistrial.segstart) >= task{tnum}.thistrial.seglen(task{tnum}.thistrial.thisseg)
    segover = 1;
  end
% check end of segment in seconds
else
  if (mglGetSecs-task{tnum}.thistrial.segstart) >= task{tnum}.thistrial.seglen(task{tnum}.thistrial.thisseg)
    % if we need to synch to volume
    if task{tnum}.synchToVol(task{tnum}.thistrial.thisseg)
      % then first time through set the volume number
      if task{tnum}.thistrial.synchVol == -1
	task{tnum}.thistrial.synchVol = myscreen.volnum;
      % then see if we have gone past that volume	
      elseif task{tnum}.thistrial.synchVol < myscreen.volnum
	segover = 1;
	% reset the segment time to match how much time elapsed
	% so that the next segment won't be shortened
	task{tnum}.thistrial.seglen(task{tnum}.thistrial.thisseg) = mglGetSecs-task{tnum}.thistrial.segstart;
      end
    %w/out synch to volume the segment is over
    else
      segover = 1;
    end
  end
end

% update the segment if necessary
if (segover)
  % reset flush mode if we just finished a reactionTime response interval
  if (task{tnum}.getResponse(task{tnum}.thistrial.thisseg)==2)
    myscreen.flushMode = myscreen.oldFlushMode;
  end
  % now update segment counter
  task{tnum}.thistrial.thisseg = task{tnum}.thistrial.thisseg + 1;
  % if we have completed all segments then we are done
  if (task{tnum}.thistrial.thisseg > length(task{tnum}.thistrial.seglen))
    % end the current trial
    if isfield(task{tnum}.callback,'endTrial')
      [task{tnum} myscreen]= feval(task{tnum}.callback.endTrial,task{tnum},myscreen);
    end
    % update the trial number
    task{tnum}.blockTrialnum = task{tnum}.blockTrialnum + 1;
    task{tnum}.trialnum = task{tnum}.trialnum+1;
    % set the trial to init when it hits updateTrial again 
    % (this will happen from the updateTask called below)
    task{tnum}.thistrial.waitingToInit = 1;
    % now we have to update the task
    [task myscreen tnum] = updateTask(task,myscreen,tnum);
    return
  end
  % restart segment clock
  task{tnum} = resetSegmentClock(task{tnum},myscreen);
  % write out appropriate trace
  myscreen = writeTrace(task{tnum}.thistrial.thisseg,task{tnum}.segmentTrace,myscreen,1);
  myscreen = taskWriteTrace(task{tnum},myscreen);
  % call segment start callback
  [task{tnum} myscreen] = feval(task{tnum}.callback.startSegment,task{tnum},myscreen);
  % if this segment is set to getResponse(2), then it means that we 
  % are getting response and shutting down flipping of the screen
  % so that we can get better response time for reaction time tasks
  if (task{tnum}.getResponse(task{tnum}.thistrial.thisseg)==2)
    % call the display funciton now, and flush screen
    [task{tnum} myscreen] = feval(task{tnum}.callback.screenUpdate,task{tnum},myscreen);
    mglFlush;
    % now set not update the screen while we wait for response
    myscreen.oldFlushMode = myscreen.flushMode;
    myscreen.flushMode = -1;
  end
end

% if we have to collect observer response, then look for that
if (task{tnum}.getResponse(task{tnum}.thistrial.thisseg))
  % get keyboard state
  buttons = mglGetKeys(myscreen.keyboard.nums);
  % if a button was pressed, then record response
  if (any(buttons) && (~isequal(buttons,task{tnum}.thistrial.buttonState)))
    % get the time of the button press
    responseTime = mglGetSecs;
    % set the button state to pass
    task{tnum}.thistrial.buttonState = buttons;
    task{tnum}.thistrial.whichButton = find(buttons);
    task{tnum}.thistrial.whichButton = task{tnum}.thistrial.whichButton(1);
    % write out an event
    myscreen = writeTrace(task{tnum}.thistrial.whichButton,task{tnum}.responseTrace,myscreen,1,responseTime);
    % get reaction time
    task{tnum}.thistrial.reactionTime = responseTime-task{tnum}.thistrial.segStartSeconds;
    if isfield(task{tnum}.callback,'trialResponse')
      [task{tnum} myscreen] = feval(task{tnum}.callback.trialResponse,task{tnum},myscreen);
    end
    % set flush mode back
    if (task{tnum}.getResponse(task{tnum}.thistrial.thisseg)==2)
      myscreen.flushMode = myscreen.oldFlushMode;
    end
    % and set that we have got a response
    task{tnum}.thistrial.gotResponse = task{tnum}.thistrial.gotResponse+1;
  end
  % remember the current button state
  task{tnum}.thistrial.buttonState = buttons;
end

% update the stimuli, but only if we are actually updating the screen
if myscreen.flushMode >= 0
  [task{tnum} myscreen] = feval(task{tnum}.callback.screenUpdate,task{tnum},myscreen);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% init block
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task myscreen] = initBlock(task,myscreen)

% start up a new block
% select a randomization of trial parameters
task.blocknum = task.blocknum+1;

% update the parameter order for this block
% using the randomization callback, if this
% pass previous block if it is available
if task.blocknum > 1
  task.block(task.blocknum) = feval(task.callback.rand,task.parameter,task.block(task.blocknum-1));
else
  task.block(task.blocknum) = feval(task.callback.rand,task.parameter,[]);
end

% set the initial trial
task.blockTrialnum = 1;

% call the init block callback
if isfield(task.callback,'startBlock')
  [task myscreen] = feval(task.callback.startBlock,task,myscreen);
end

% set up start time to tell routines to init trial properly
[task myscreen] = initTrial(task,myscreen);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% init trial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task, myscreen] = initTrial(task,myscreen)

% keep lasttrial information
task.lasttrial = task.thistrial;

% set the segment number
task.thistrial.thisseg = 1;
task.thistrial.gotResponse = 0;

% restart segment clock
task.thistrial.segstart = -inf;

% start trial time
%if (task.timeInTicks)
%  task.thistrial.trialstart = myscreen.tick;
%elseif (task.timeInVols)
%  task.thistrial.trialstart = myscreen.volnum;
%else
%end

% set up start volume for checking for backticks
task.thistrial.startvolnum = myscreen.volnum;

% set the segment length
segminlen = task.segmin;
segmaxlen = task.segmax;

% for time in ticks and vols, we want an integer value
if (task.timeInTicks || task.timeInVols)
  task.thistrial.seglen = segminlen + floor(rand*(segmaxlen-segminlen+1));
else
  task.thistrial.seglen = segminlen + rand*(segmaxlen-segminlen);

  % deal with the segment quantization, if segquant is set to
  % zero there is no effect, otherwise we will round segment
  % lengths to something evenly divisible by segquant
  task.thistrial.seglen(task.segquant~=0) = round((task.thistrial.seglen(task.segquant~=0)-task.segmin(task.segquant~=0))/task.segquant(task.segquant~=0))*task.segquant(task.segquant~=0)+task.segmin(task.segquant~=0);

end

% see if we need to wait for backtick
if task.waitForBacktick && (task.blocknum == 1) && (task.blockTrialnum == 1)
  task.thistrial.waitForBacktick = 1;
  disp(sprintf('Waiting for backtick (`)'));
else
  % trial will start right awway
  task.thistrial.waitForBacktick = 0;
end

% set the button states to zero
task.thistrial.buttonState = [0 0];

% call the init trial callback
if isfield(task.callback,'startTrial')
  [task myscreen] = feval(task.callback.startTrial,task,myscreen);
end

% get trial parameters
for i = 1:task.parameter.n_
  eval(sprintf('task.thistrial.%s = task.block(task.blocknum).parameter.%s(:,task.blockTrialnum);',task.parameter.names_{i},task.parameter.names_{i}));
end

% get randomization parameters
for i = 1:task.randVars.n_
  eval(sprintf('task.thistrial.%s = task.randVars.%s(mod(task.trialnum-1,task.randVars.varlen_(%i))+1);',task.randVars.names_{i},task.randVars.names_{i},i));
end

% the trial is no longer waiting to start
task.thistrial.waitingToInit = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function to reset segment time
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function task = resetSegmentClock(task,myscreen)

% reset the synch volume
task.thistrial.synchVol = -1;

% get amount of time already used, including and
% discrepancy left over from last trial
usedtime = sum(task.thistrial.seglen(1:(task.thistrial.thisseg-1)));

% restart segment clock, if we are using seconds, then fix
% any time discrepancy
if ~(task.timeInVols || task.timeInTicks)
  task.thistrial.segstart = task.thistrial.trialstart-task.timeDiscrepancy+usedtime;
else
  task.thistrial.segstart = task.thistrial.trialstart+usedtime;
end
% get start of segment in real seconds
task.thistrial.segStartSeconds = mglGetSecs;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% write trace if called for
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function myscreen = taskWriteTrace(task,myscreen)

% write trace if called for
if (isfield(task.writeTrace{task.thistrial.thisseg},'tracenum'))
  % write out all the trace variables called for
  thisWriteTrace = task.writeTrace{task.thistrial.thisseg};
  for i = 1:length(thisWriteTrace.tracenum)
    tracenum = thisWriteTrace.tracenum(i)-1+myscreen.stimtrace;
    % get the value of the called for parameter
    paramval = eval(sprintf('task.thistrial.%s(%i)',thisWriteTrace.tracevar{i},thisWriteTrace.tracerow(i)));
    if (thisWriteTrace.usenum(i))
      % find parameter number
      paramval = eval(sprintf('find(paramval == %s(%i,:))',thisWriteTrace.original{i},thisWriteTrace.tracerow(i)));
    end
    eval(sprintf('myscreen = writeTrace(paramval,thisWriteTrace.tracenum(i)-1+myscreen.stimtrace,myscreen,1);',thisWriteTrace.tracevar{i},thisWriteTrace.tracerow(i)));
  end
else
  for i = 1:task.numstimtraces
    myscreen = writeTrace(0,myscreen.stimtrace+i-1,myscreen);
  end
end

