% tickScreen.m
%
%        $Id$
%      usage: tickScreen
%         by: justin gardner
%       date: 12/10/04
%  copyright: (c) 2006 Justin Gardner (GPL see mgl/COPYING)
%    purpose: flip screen and update counter - for mgl
%
function [myscreen task] = tickScreen(myscreen,task)

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get back tick status
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get all pending keyboard events
[myscreen.keyCodes myscreen.keyTimes] = mglGetKeyEvent([],1);

% see if there was a back tick
keytick = find(myscreen.keyboard.backtick == myscreen.keyCodes);
if ~isempty(keytick)
  volTime = myscreen.keyTimes(keytick(1));
end

% read digio pulses if need be
if myscreen.useDigIO
  digin = mglDigIO('digin');
  if ~isempty(digin)
    % see if there is an acq pulse
    acqPulse = find(myscreen.digin.acqLine == digin.line);
    if ~isempty(acqPulse)
      acqPulse = find(ismember(digin.type(acqPulse),myscreen.digin.acqType));
      if ~isempty(acqPulse)
	volTime = digin.when(acqPulse(1));
	acqPulse = 1;
      else
	acqPulse = 0;
      end
    else
      acqPulse = 0;
    end
    % use either volume or backtick to signal volume acq
    keytick = acqPulse | ~isempty(keytick);
    % see if one of the response lines has been set 
    % first check to see if any digin line matches the response line
    [isResponse pulseWhich] = ismember(digin.line,myscreen.digin.responseLine);
    % now get the info for those response lines
    isResponse = find(isResponse);
    pulseType = digin.type(isResponse);
    pulseWhen = digin.when(isResponse);
    pulseWhich = pulseWhich(isResponse);
    % now check whether that line has the right response (i.e. is it 0 or 1)
    isResponse = find(ismember(pulseType,myscreen.digin.responseType));
    % and get the info for those responses
    pulseWhich = pulseWhich(isResponse);
    pulseWhen = pulseWhen(isResponse);
    % and store as keyCodes and keyTimes
    myscreen.keyCodes = [myscreen.keyCodes myscreen.keyboard.nums(pulseWhich)];
    myscreen.keyTimes = [myscreen.keyTimes pulseWhen];
  end
end

% record volume
if (keytick)
  if myscreen.ignoreInitialVols
    % if we are to ignore them, ignore and decrement counter
    myscreen.ignoreInitialVols = myscreen.ignoreInitialVols - 1;
    % write to ignored volume trace
    myscreen = writeTrace(1,6,myscreen,1,volTime);
  else
    % record the volume
    myscreen = writeTrace(1,1,myscreen,1,volTime);
    myscreen.volnum = myscreen.volnum+1;
  end
  %  disp(sprintf('myscreen.volnum = %i',myscreen.volnum));
end

if myscreen.eyetracker.init
  %% get eye position 
  [task myscreen] = feval(myscreen.eyetracker.callback.getPosition,task,myscreen);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% flip screen
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% normally we flush every screen update
if myscreen.flushMode==0
  mglFlush();
  % but if flushMode is set to one then we flush the screen once
elseif myscreen.flushMode == 1
  mglFlush();
  myscreen.flushMode = -1;
elseif myscreen.flushMode == 2
  mglNoFlushWait();
elseif myscreen.flushMode == inf
  % this simulates the vertical blanking time
  % for some display cards which don't wait
  % the appropriate time (e.g. ATI Radeon HD 5700 series)
  mglFlushAndWait();
else
  myscreen.fliptime = inf;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% check for dropped frames
%%%%%%%%%%%%%%%%%%%%%%%%%%%
if myscreen.checkForDroppedFrames && (myscreen.flushMode>=0)
  fliptime = mglGetSecs;
  if ((fliptime-myscreen.fliptime) > myscreen.dropThreshold*myscreen.frametime)
    myscreen.dropcount = myscreen.dropcount+1;
  end
  if (myscreen.fliptime ~= inf)
    myscreen.totalflip = myscreen.totalflip+(fliptime-myscreen.fliptime);
    myscreen.totaltick = myscreen.totaltick+1;
  end
  myscreen.fliptime = fliptime;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% check for esc key
%%%%%%%%%%%%%%%%%%%%%%%%%%%
if any(myscreen.keyCodes == myscreen.keyboard.esc);
  myscreen.userHitEsc = 1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% update tick
%%%%%%%%%%%%%%%%%%%%%%%%%%%
myscreen.tick = myscreen.tick + 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if called for pause on space bar
%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (myscreen.allowpause && any(myscreen.keyCodes == myscreen.keyboard.space)) || myscreen.paused
  startPause = mglGetSecs;
  disp(sprintf('PAUSED: hit SPACE to advance a frame RETURN to continue'));
  keyCodes = [];
  % then check for return or space
  while isempty(intersect(keyCodes,[myscreen.keyboard.return myscreen.keyboard.space]))
    [keyCodes keyTimes] = mglGetKeyEvent([],1);
  end
  if any(keyCodes == myscreen.keyboard.space)
    myscreen.paused = 1;
  else
    myscreen.paused = 0;
  end
  % fix task times
  task = pauseTask(task,mglGetSecs(startPause));
  myscreen.fliptime = mglGetSecs;
end

