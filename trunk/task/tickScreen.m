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
thistick = find(myscreen.keyboard.backtick == myscreen.keyCodes);
if ~isempty(thistick)
  volTime = myscreen.keyTimes(thistick(1));
end

% read digio pulses if need be
if myscreen.useDigIO
  digin = mglDigIO('digin');
  if ~isempty(digin)
    % see if there is an acq pulse
    acqPulse = which(myscreen.digin.acqLine == digin.line);
    if ~isempty(acqPulse)
      acqPulse = which(ismember(digin.type(acqPulse),myscreen.digin.acqType));
      if ~isempty(acqPulse)
	volTime = digin.time(acqPulse(1));
      end
      acqPulse = 1;
    else
      acqPulse = 0;
    end
    % use either volume or backtick to signal volume acq
    thistick = ttltick | thistick;
    % see if one of the response lines has been set 
    [responsePulse whichResponse] = ismember(digin.line,myscreen.digin.responseLine);
    responsePulse = ismember(digin.type(responsePulse),myscreen.digin.responseType);
    myscreen.keyCodes = [myscreen.keyCodes myscreen.keyboard.nums(whichResponse(responsePulse))];
    myscreen.keyTimes = [myscreen.keyTimes digin.time(responsePulse)];
  end
end

% record volume
if (thistick)
  myscreen = writeTrace(1,1,myscreen,0,volTime);
  myscreen.volnum = myscreen.volnum+1;
  disp(sprintf('myscreen.volnum = %i',myscreen.volnum));
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
  if any(keyCodes == myscreen.keyboard.space),myscreen.paused = 1;else,myscreen.paused = 0;end
  % fix task times
  task = pauseTask(task,mglGetSecs(startPause));
  myscreen.fliptime = mglGetSecs;
end


