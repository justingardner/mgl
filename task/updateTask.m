% updateTask - update the task in running in stimulus programs
%
%        $Id$
%      usage: [task, myscreen, tnum] = updateTask(task,myscreen,tnum)
%         by: justin gardner, eric dewitt
%       date: 2006-04-27
%  copyright: (c) 2006 Justin Gardner (GPL see mgl/COPYING)
%     inputs: stimulus,task,myscreen,tnum
%    outputs: stimulus task myscreen tnum
%    purpose: runs experimental tasks
%
function [task, myscreen, tnum] = updateTask(task,myscreen,tnum)

% make sure we have a valid active task
if tnum > length(task)
  return
end

% set the random state
randstate = rand(myscreen.randstate.type);
rand(task{tnum}.randstate.type,task{tnum}.randstate.state);

% if we have finished how many trials were called for go to next task
if (task{tnum}.trialnum > task{tnum}.numTrials)
  tnum = tnum+1;
  % write out the phase
  myscreen = writeTrace(tnum,task{tnum-1}.phaseTrace,myscreen);
  if myscreen.eyetracker.init && tnum <= numel(task)
    [task{tnum} myscreen] = feval(myscreen.eyetracker.callback.nextTask,task{tnum},myscreen);
  end
  [task myscreen tnum] = updateTask(task,myscreen,tnum);
  % reset it to what it was before this call
  rand(myscreen.randstate.type,randstate);
  return
end

% check for a new block
if (task{tnum}.blocknum == 0) || (task{tnum}.blockTrialnum > task{tnum}.block(task{tnum}.blocknum).trialn) 
  % if we have finished how many blocks were called for
  % then we need to go on to the next task
  if (task{tnum}.blocknum == task{tnum}.numBlocks)
    tnum = tnum+1;
    % write out the phase
    myscreen = writeTrace(tnum,task{tnum-1}.phaseTrace,myscreen);
    if myscreen.eyetracker.init && tnum <= numel(task)
      [task{tnum} myscreen] = feval(myscreen.eyetracker.callback.nextTask,task{tnum},myscreen);
    end
    [task myscreen tnum] = updateTask(task, myscreen, tnum);
    % reset it to what it was before this call
    rand(myscreen.randstate.type,randstate);
    return
  end
  % otherwise init a new block and continue on
  [task{tnum} myscreen] = initBlock(task{tnum},myscreen,tnum);
end

% update trial
[task myscreen tnum] = updateTrial(task, myscreen, tnum);

% remember the status of the random number generator
if tnum<=length(task) & isfield(task{tnum},'randstate') 
  task{tnum}.randstate.state = rand(task{tnum}.randstate.type);
end
rand(myscreen.randstate.type,randstate);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% update trial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task, myscreen tnum] = updateTrial(task, myscreen, tnum)

if task{tnum}.thistrial.waitingToInit
  % init the trial
  [task{tnum} myscreen] = initTrial(task{tnum},myscreen,tnum);
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
      disp(sprintf('(updateTask) Backtick recorded: Starting trial'));
      % clear waiting status
      task{tnum}.thistrial.waitForBacktick = 0;
    end
  end
  % write out appropriate trace
  myscreen = writeTrace(1,task{tnum}.segmentTrace,myscreen,1);
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
  if myscreen.eyetracker.init 
    %% call eyetracker segment callback
    [task{tnum} myscreen] = feval(myscreen.eyetracker.callback.startSegment,task{tnum},myscreen);
  end

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

% there are situations in which for the trial in the sequence
% we are waiting for a volume to end the trial, but will enver
% get one since the scan is over. Yet, we still want to end the
% trial to end the experiment, so we are going to have fudge
% on the last volume. 
if task{tnum}.fudgeLastVolume
  % see if we are in the last trial for numTrials, or the
  % last trial of the last block for numBlocks
  if (task{tnum}.trialnum == task{tnum}.numTrials) || ...
	((task{tnum}.blocknum == task{tnum}.numBlocks) && (task{tnum}.blockTrialnum == task{tnum}.block(task{tnum}.blocknum).trialn))
    if ~isfield(task{tnum}.thistrial,'fudgeLastVolume')
      % see if we are in the last segment
      if task{tnum}.thistrial.thisseg == length(task{tnum}.thistrial.seglen)
	% make sure we have satisfied all but the last volume
	% for the trial (this could either be due to a synchToVol
	% waiting for the volume to end, or with timeInVols we have
	% gotten all but the last volume
	segmentExpired = 0;
	if task{tnum}.synchToVol(task{tnum}.thistrial.thisseg)
	  if task{tnum}.timeInTicks == 1
	    if (myscreen.tick - task{tnum}.thistrial.segstart) >= task{tnum}.thistrial.seglen(task{tnum}.thistrial.thisseg)
	      segmentExpired = 1;
	    end
	    % check end of segment in seconds
	  else
	    if (mglGetSecs-task{tnum}.thistrial.segstart) >= task{tnum}.thistrial.seglen(task{tnum}.thistrial.thisseg)
	      segmentExpired = 1;
	    end
	  end
	else
	  % check number of volumes
	  if task{tnum}.timeInVols 
	    if ((myscreen.volnum - task{tnum}.thistrial.segstart)+1) >= task{tnum}.thistrial.seglen(task{tnum}.thistrial.thisseg)
	      segmentExpired = 1;
	    end
	  end
	end
	% if segmentExpired gets set then it means that the segment has ended and
	% is just waiting for the volume (which will never come, so now we
	% set the fudgeLastVolume field so that it will end at 1 average volume
	% time away from now.
	if segmentExpired
	  % find the average volume time
	  volumeTimes = myscreen.events.time((myscreen.events.data == 1) & (myscreen.events.tracenum==1));
	  % we will only do this correction, if we can get
	  % a valid averageVolume Time
	  if ~isempty(volumeTimes)
	    % get time of last volume
	    task{tnum}.thistrial.averageVolumeTime = mean(diff(volumeTimes));
	    task{tnum}.thistrial.fudgeLastVolume = volumeTimes(end)+task{tnum}.thistrial.averageVolumeTime;
	  end
	end
      end
      % if there is a fudgeLastVolume field then it means
      % we should end the segment, once the proper amount of time has elapsed
      % this is the actual piece of code in here which causes the
      % segment to end by setting segover to 1
    else
      if mglGetSecs > task{tnum}.thistrial.fudgeLastVolume
	disp(sprintf('(updateTask) Used fudgeLastVolume to end last trial of task (averageVolumeTime=%0.2f)',task{tnum}.thistrial.averageVolumeTime));
	segover = 1;
      end
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
    if myscreen.eyetracker.init 
      %% call eyetracker endTrial callback
      [task{tnum} myscreen] = feval(myscreen.eyetracker.callback.endTrial,task{tnum},myscreen);
    end
    % if there are calculated random variables, save them
    if task{tnum}.randVars.calculated_n_
      for nVar = 1:task{tnum}.randVars.calculated_n_
	% check to make sure that the value in the calculated variable is not
	% set to empty (if it is, then we warn and ignore), otherwise
	% we set the stored calculated variable was set to (in the user
	% program) in task.thistrial
	if ~isempty(task{tnum}.thistrial.(task{tnum}.randVars.calculated_names_{nVar}))
	  if ~iscell(task{tnum}.randVars.(task{tnum}.randVars.calculated_names_{nVar})) && isscalar(task{tnum}.thistrial.(task{tnum}.randVars.calculated_names_{nVar}))
	    % scalar calculated var gets an array
	    eval(sprintf('task{tnum}.randVars.%s(task{tnum}.trialnum) = task{tnum}.thistrial.%s;',task{tnum}.randVars.calculated_names_{nVar},task{tnum}.randVars.calculated_names_{nVar}));
	  else
	    % non-scalar calculated var gets a *cell* array
	    eval(sprintf('task{tnum}.randVars.%s{task{tnum}.trialnum} = task{tnum}.thistrial.%s;',task{tnum}.randVars.calculated_names_{nVar},task{tnum}.randVars.calculated_names_{nVar}));
	  end
	else
	  disp(sprintf('(updateTask) !!! randVar %s set to empty for trial %i, leaving as default value of %s',task{tnum}.randVars.calculated_names_{nVar},task{tnum}.trialnum,task{tnum}.randVars.(task{tnum}.randVars.calculated_names_{nVar})(task{tnum}.trialnum)));
	end
      end
    end
    % we collect the calculated randVars from thistrial and place them
    % back into the randVar array.
    % this
    % update the trial number
    task{tnum}.blockTrialnum = task{tnum}.blockTrialnum + 1;
    task{tnum}.trialnum = task{tnum}.trialnum+1;
    % set the trial to init when it hits updateTrial again 
    % (this will happen from the updateTask called below)
    task{tnum}.thistrial.waitingToInit = 1;
    % now we have to update the task
    [task myscreen tnum] = updateTask(task,myscreen,tnum);
    % make sure that random number generator is in correct state
    if tnum<=length(task) & isfield(task{tnum},'randstate') 
      rand(task{tnum}.randstate.type,task{tnum}.randstate.state);
    end
    return
  end
  % restart segment clock
  task{tnum} = resetSegmentClock(task{tnum},myscreen);
  % write out appropriate trace
  myscreen = writeTrace(task{tnum}.thistrial.thisseg,task{tnum}.segmentTrace,myscreen,1);

  % call segment start callback
  if myscreen.eyetracker.init
    %% call eyetracker trial callback
    [task{tnum} myscreen] = feval(myscreen.eyetracker.callback.startSegment,task{tnum},myscreen);
  end
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
  % check keyboard if that is what is being asked for (code 1 or 2) 1
  % is just keyboard check 2 is an old call for checking keyboard but
  % staying in a tight loop for gettine better reaction time data (not
  % necessary anymore because the keyboard events are being returned
  % by the system with nanosecond precision timing. 3 means get both
  % keyboard and mouse events and 4 means just mouse
  task{tnum}.thistrial.mouseButton = [];
  % get keyboard state
  buttons = ismember(myscreen.keyboard.nums,myscreen.keyCodes);
  if any(task{tnum}.getResponse(task{tnum}.thistrial.thisseg)==[1 2 3])
    % if a button was pressed, then record response
    if (any(buttons) && (~isequal(buttons,task{tnum}.thistrial.buttonState)))
      % set the button state to pass
      task{tnum}.thistrial.buttonState = buttons;
      task{tnum}.thistrial.whichButton = find(buttons);
      task{tnum}.thistrial.whichButton = task{tnum}.thistrial.whichButton(1);
      % get the time of the button press
      whichKeyCode = find(myscreen.keyboard.nums(task{tnum}.thistrial.whichButton)==myscreen.keyCodes);
      responseTime = myscreen.keyTimes(whichKeyCode(1));
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
  end
  % remember the current button state
  task{tnum}.thistrial.buttonState = buttons;
  % check mouse state if getResponse is set to 3
  if any(task{tnum}.getResponse(task{tnum}.thistrial.thisseg)==[3 4])
    % get the mouse state
    [task{tnum}.thistrial.mouseButton task{tnum}.thistrial.mouseWhen task{tnum}.thistrial.mouseX task{tnum}.thistrial.mouseY] = mglGetMouseEvent(0,1);
    % remove events that happened before this segment
    goodEvents = task{tnum}.thistrial.mouseWhen > task{tnum}.thistrial.segStartSeconds;
    if ~isempty(task{tnum}.thistrial.mouseButton)
      task{tnum}.thistrial.mouseButton = task{tnum}.thistrial.mouseButton(goodEvents);
      task{tnum}.thistrial.mouseWhen = task{tnum}.thistrial.mouseWhen(goodEvents);
      task{tnum}.thistrial.mouseX = task{tnum}.thistrial.mouseX(goodEvents);
      task{tnum}.thistrial.mouseY = task{tnum}.thistrial.mouseY(goodEvents);
    end
    % if there was a mouse down event
    if ~isempty(task{tnum}.thistrial.mouseButton)
      responseTime = task{tnum}.thistrial.mouseWhen;
      % write out an event (code the mouse events as negative numbers to
      % distinguish them from keyboard events
      myscreen = writeTrace(-task{tnum}.thistrial.mouseButton,task{tnum}.responseTrace,myscreen,1,responseTime);
      % get reaction time
      task{tnum}.thistrial.reactionTime = responseTime-task{tnum}.thistrial.segStartSeconds;
      if isfield(task{tnum}.callback,'trialResponse')
	[task{tnum} myscreen] = feval(task{tnum}.callback.trialResponse,task{tnum},myscreen);
      end
      % and set that we have got a response
      task{tnum}.thistrial.gotResponse = task{tnum}.thistrial.gotResponse+1;
    end
  end
end

% update the stimuli, but only if we are actually updating the screen
if myscreen.flushMode >= 0
  [task{tnum} myscreen] = feval(task{tnum}.callback.screenUpdate,task{tnum},myscreen);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% init block
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task myscreen] = initBlock(task,myscreen,phase)

% start up a new block
% select a randomization of trial parameters
task.blocknum = task.blocknum+1;

% set the randstate here. This is so that the randomization that
% happens here is independent of other uses of the rand variable
% that way if you want to recreate the order of trials, you
% can reset the rand state in initTask from the one that is saved
randstate = rand(task.randstate.type);
rand(task.randstate.type,task.randstate.blockState);

% update the parameter order for this block
% using the randomization callback, if this
% pass previous block if it is available
if task.blocknum > 1
  task.block(task.blocknum) = feval(task.callback.rand,task.parameter,task.block(task.blocknum-1));
else
  task.block(task.blocknum) = feval(task.callback.rand,task.parameter,[]);
end

% now keep the randstate
task.randstate.blockState = rand(task.randstate.type);
rand(task.randstate.type,randstate);

% set the initial trial
task.blockTrialnum = 1;

% call the init block callback
if isfield(task.callback,'startBlock')
  [task myscreen] = feval(task.callback.startBlock,task,myscreen);
end
if myscreen.eyetracker.init
  %% call eyetracker block callback
  [task myscreen] = feval(myscreen.eyetracker.callback.startBlock,task,myscreen);
end

% set up start time to tell routines to init trial properly
[task myscreen] = initTrial(task,myscreen,phase);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% init trial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task, myscreen] = initTrial(task,myscreen,phase)

% keep lasttrial information
task.lasttrial = task.thistrial;

% set the phase num of the trial
task.thistrial.thisphase = phase;

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

% here we deal with precomputed seglen
if isequal(task.seglenPrecompute,false)
  % set the segment length
  [seglen task] = getTaskSeglen(task);
  task.thistrial.seglen = seglen;
else
  % note that if seglens are precomputed, also anything else having to do
  % with semgents need to be recomputed (i.e. you may want to compute
  % synchToVol or getResponse on a trial by trial basis - for example,
  % you may have trials in which on different trials the synchToVol changes
  % or which segment is the response segment changes.Whatever fields
  % there are in seglenPrecompute get placed into task at this stage
  for iField = 1:task.seglenPrecompute.nFields
    % get the name of the field getting set from precompute
    fieldName = (task.seglenPrecompute.fieldNames{iField});
    % get what cell to take (i.e. if the field only has one row
    % then we will take that otherwise there should be one cell for
    % each trial) If we have multiple trials, but less than the current 
    % trial number than cycle through the rows
    fieldRow = mod(task.trialnum-1,task.seglenPrecompute.(fieldName).nTrials)+1;
    task.thistrial.(fieldName) = task.seglenPrecompute.(fieldName).vals{fieldRow};
  end
  % now get the seglen for this trial (note that seglen is a cell array
  % which allows for trials with different numbers of segments)
  fieldRow = mod(task.trialnum-1,task.seglenPrecompute.seglen.nTrials)+1;
  task.thistrial.seglen = task.seglenPrecompute.seglen.vals{fieldRow};
end

% see if we need to wait for backtick
if task.waitForBacktick && (task.blocknum == 1) && (task.blockTrialnum == 1)
  task.thistrial.waitForBacktick = 1;
  backtick = mglKeycodeToChar(myscreen.keyboard.backtick);
  disp(sprintf('(updateTask) Waiting for backtick (%s)',backtick{1}));
else
  % trial will start right awway
  task.thistrial.waitForBacktick = 0;
end

% set the button states to zero
task.thistrial.buttonState = [0 0];

% get trial parameters
for i = 1:task.parameter.n_
  eval(sprintf('task.thistrial.%s = task.block(task.blocknum).parameter.%s(:,task.blockTrialnum);',task.parameter.names_{i},task.parameter.names_{i}));
end

% get randomization parameters
for i = 1:task.randVars.n_
  % get the variable name we are working on
  thisRandVarName = task.randVars.names_{i};
  if iscell(task.randVars.(thisRandVarName))
    % if the precomputed list is a cell array then grab from that cell array
    task.thistrial.(thisRandVarName) = task.randVars.(thisRandVarName){mod(task.trialnum-1,task.randVars.varlen_(i))+1};
  else
    % otherwise grab from a regular array
    task.thistrial.(thisRandVarName) = task.randVars.(thisRandVarName)(mod(task.trialnum-1,task.randVars.varlen_(i))+1);
  end
end

% call the init trial callback
if isfield(task.callback,'startTrial')
  [task myscreen] = feval(task.callback.startTrial,task,myscreen);
end    
if myscreen.eyetracker.init
  %% call eyetracker trial callback
  [task myscreen] = feval(myscreen.eyetracker.callback.startTrial,task,myscreen);
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

