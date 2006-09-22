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
if (task{tnum}.blocknum == 0) || (task{tnum}.trialnum > task{tnum}.block(task{tnum}.blocknum).trialn) 
  % if we have finished how many blocks were called for
  % then we need to go on to the next task
  if (task{tnum}.blocknum == task{tnum}.numBlocks)
    tnum = tnum+1;
    [task myscreen tnum] = updateTask(task, myscreen, tnum);
    return
  end
  % otherwise init a new block and continue on
  [task{tnum} myscreen] = initBlock(task{tnum},myscreen);
end

% if we have finished how many trials were called for go to next task
if (task{tnum}.trialnumTotal > task{tnum}.numTrials)
  tnum = tnum+1;
  [task myscreen tnum] = updateTask(task,myscreen,tnum);
  return
end

% update trial
[task myscreen tnum] = updateTrial(task, myscreen, tnum);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% update trial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task, myscreen tnum] = updateTrial(task, myscreen, tnum)

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
  myscreen = taskWriteTrace(task{tnum},myscreen);
  if task{tnum}.writeSegmentsTrace
    myscreen = writeTrace(1,task{tnum}.writeSegmentsTrace,myscreen,1);
  end
  % restart segment clock and continue on
  % as if the segment just started
  if task{tnum}.timeInTicks
    task{tnum}.thistrial.trialstart = myscreen.tick;
    task{tnum}.thistrial.segstart = myscreen.tick;
  elseif task{tnum}.timeInVols
    task{tnum}.thistrial.trialstart = myscreen.volnum;
    task{tnum}.thistrial.segstart = myscreen.volnum;
  else
    task{tnum}.thistrial.trialstart = mglGetSecs;
    task{tnum}.thistrial.segstart = mglGetSecs;
  end
  task{tnum} = resetSegmentClock(task{tnum},myscreen);
  % get trial parameters
  if task{tnum}.thistrial.thisseg == 1
    for i = 1:task{tnum}.parameterN
      eval(sprintf('task{tnum}.thistrial.%s = task{tnum}.block(task{tnum}.blocknum).parameter.%s(:,task{tnum}.trialnum);',task{tnum}.parameterNames{i},task{tnum}.parameterNames{i}));
    end
  end
  % set stimulus parameters
  [task{tnum} myscreen] = feval(task{tnum}.callback.startSegment,task{tnum},myscreen);
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
    segover = 1;
  end
end

% update the segment if necessary
if (segover)
  task{tnum}.thistrial.thisseg = task{tnum}.thistrial.thisseg + 1;
  % if we have completed all segments then we are done
  if (task{tnum}.thistrial.thisseg > length(task{tnum}.thistrial.seglen))
    % end the current trial
    if isfield(task{tnum}.callback,'endTrial')
      [task{tnum} myscreen]= feval(task{tnum}.callback.endTrial,task{tnum},myscreen);
    end
    % update the trial number
    task{tnum}.trialnum = task{tnum}.trialnum + 1;
    task{tnum}.trialnumTotal = task{tnum}.trialnumTotal+1;
    task{tnum}.thistrial.waitingToInit = 1;
    % now we have to update the task
    [task myscreen tnum] = updateTask(task,myscreen,tnum);
    return
  end
  % restart segment clock
  task{tnum} = resetSegmentClock(task{tnum},myscreen);
  % write out appropriate trace
  myscreen = taskWriteTrace(task{tnum},myscreen);
  if task{tnum}.writeSegmentsTrace
    myscreen = writeTrace(task{tnum}.thistrial.thisseg,task{tnum}.writeSegmentsTrace,myscreen,1);
  end
  % set stimulus parameters
  [task{tnum} myscreen] = feval(task{tnum}.callback.startSegment,task{tnum},myscreen);
end

% if we have to collect observer response, then look for that
if (task{tnum}.getResponse(task{tnum}.thistrial.thisseg))
  % get keyboard state
  buttons = mglGetKeys(myscreen.keyboard.nums);
  % if a button was pressed, then record response
  if (any(buttons) && (~isequal(buttons,task{tnum}.thistrial.buttonState)))
    task{tnum}.thistrial.buttonState = buttons;
    if isfield(task{tnum}.callback,'trialResponse')
      [task{tnum} myscreen] = feval(task{tnum}.callback.trialResponse,task{tnum},myscreen);
    end
  end
  % remember the current button state
  task{tnum}.thistrial.buttonState = buttons;
end

% update the stimuli
[task{tnum} myscreen] = feval(task{tnum}.callback.drawStimulus,task{tnum},myscreen);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% init block
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task myscreen] = initBlock(task,myscreen)

% start up a new block
% select a randomization of trial parameters
task.blocknum = task.blocknum+1;
% get a randomperm for use for total randomization
completeRandperm = randperm(task.parameterTotalN);
% create a randomization of the parameters
innersize = 1;
for paramnum = 1:task.parameterN
  paramnums = [];
  for rownum = 1:task.parameterSize(paramnum,1)
    lastcol = 0;
    for paramreps = 1:(task.parameterTotalN/task.parameterSize(paramnum,2))/innersize
      % if we need to randomize, then do it here so that
      % arrays with multiple rows have different randomizations
      if task.random > 0
	thisparamnums = randperm(task.parameterSize(paramnum,2));
      else
	thisparamnums = 1:task.parameterSize(paramnum,2);
      end
      % spread it out over inner dimensions
      thisparamnums = thisparamnums*repmat(eye(length(thisparamnums)),1,innersize);
      thisparamnums = reshape(reshape(thisparamnums,length(thisparamnums)/innersize,innersize)',1,length(thisparamnums));
      % stick into array appropriately
      paramnums(rownum,lastcol+1:lastcol+length(thisparamnums)) = thisparamnums;
      lastcol = lastcol+length(thisparamnums);
    end
  end
  % need to convert it
  for rownum = 1:task.parameterSize(paramnum,1)
    % and then convert the numbers into proper subscripts to
    % actually get the proper stimulus values
    paramnums(rownum,:) = (paramnums(rownum,:)-1)*task.parameterSize(paramnum,1)+rownum;
    % if we complete randomization then do it here
    if task.random == 1
      paramnums(rownum,:) = paramnums(rownum,completeRandperm);
    end
  end
  % now go and set this blocks parameters appropriately
  eval(sprintf('task.block(task.blocknum).parameter.%s = task.parameter.%s(paramnums);',task.parameterNames{paramnum},task.parameterNames{paramnum}));
  
  % update the size of the inner dimensions
  innersize = innersize*task.parameterSize(paramnum,2);
end

% set the total number of trials in block
task.block(task.blocknum).trialn = task.parameterTotalN;

% set the initial trial
task.trialnum = 0;

% call the init block callback
if isfield(task.callback,'startBlock')
  [task myscreen] = feval(task.callback.startBlock,task,myscreen);
end

% set up start time to tell routines to init trial properly
[task myscreen] = initTrial(task,myscreen);
task.trialnum = 1;
task.trialnumTotal = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% init trial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task, myscreen] = initTrial(task,myscreen)

% set the segment number
task.thistrial.thisseg = 1;
task.thistrial.gotResponse = 0;

% restart segment clock
task.thistrial.segstart = -inf;

% start trial time
if (task.timeInTicks)
  task.thistrial.trialstart = myscreen.tick;
elseif (task.timeInVols)
  task.thistrial.trialstart = myscreen.volnum;
else
  task.thistrial.trialstart = mglGetSecs;
end

% set up start volume for checking for backticks
task.thistrial.startvolnum = myscreen.volnum;

% set the segment length
segminlen = task.segmin;
segmaxlen = task.segmax;

% for time in ticks and vols, we want an integer value
if (task.timeInTicks || task.timeInVols)
  task.thistrial.seglen = segminlen + floor(rand*(segmaxlen-segminlen+1));
else
  task.thistrial.seglen = segminlen + (segmaxlen-segminlen);

  % deal with the segment quantization, if segquant is set to
  % zero there is no effect, otherwise we will round segment
  % lengths to something evenly divisible by segquant
  task.thistrial.seglen(task.segquant~=0) = round((task.thistrial.seglen(task.segquant~=0)-task.segmin(task.segquant~=0))/task.segquant(task.segquant~=0))*task.segquant(task.segquant~=0)+task.segmin(task.segquant~=0);

end

% see if we need to wait for backtick
if task.waitForBacktick && (task.blocknum == 1) && (task.trialnum == 0)
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

% the trial is no longer waiting to start
task.thistrial.waitingToInit = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function to reset segment time
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function task = resetSegmentClock(task,myscreen)

% get amount of time already used
usedtime = sum(task.thistrial.seglen(1:(task.thistrial.thisseg-1)));

% restart segment clock
task.thistrial.segstart = task.thistrial.trialstart+usedtime;

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
    paramval = eval(sprintf('task.block(task.blocknum).parameter.%s(%i,task.trialnum)',thisWriteTrace.tracevar{i},thisWriteTrace.tracerow(i)));
    if (thisWriteTrace.usenum(i))
      % find parameter number
      paramval = eval(sprintf('find(paramval == task.parameter.%s(%i,:))',thisWriteTrace.tracevar{i},thisWriteTrace.tracerow(i)));
    end
    eval(sprintf('myscreen = writeTrace(paramval,thisWriteTrace.tracenum(i)-1+myscreen.stimtrace,myscreen,1);',thisWriteTrace.tracevar{i},thisWriteTrace.tracerow(i)));
  end
else
  for i = 1:task.numstimtraces
    myscreen = writeTrace(0,myscreen.stimtrace+i-1,myscreen);
  end
end

