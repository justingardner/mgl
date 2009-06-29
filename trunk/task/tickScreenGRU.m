% tickScreenGRU.m
%
%        $Id: tickScreen.m 441 2009-01-30 04:50:34Z justin $
%      usage: tickScreen
%         by: justin gardner
%       date: 12/10/04
%  copyright: (c) 2006 Justin Gardner (GPL see mgl/COPYING)
%    purpose: flip screen and update counter - for mgl - modified for use at RIKEN with
%             digital ports
%
function [myscreen task] = tickScreenGRU(myscreen,task)

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get back tick status
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get all pending keyboard events
[myscreen.keyCodes myscreen.keyTimes] = mglGetKeyEvent([],1);

% look for a backtick (this can always be used to trigger a volume)
thistick = any(myscreen.keyboard.backtick == myscreen.keyCodes);

% read the TTL pulse for the acquisition
digport = readDigPort(myscreen.digin.portnum);
ttltick = bitand(bitshift(digport,-myscreen.digin.acqline),1);
% check that value has changed from last ttltick (since here
% the ttl value changes for each volume
if ~isequal(myscreen.ttltick,ttltick)
  myscreen.ttltick = ttltick;
  ttltick = 1;
else
  ttltick = 0;
end
thistick = ttltick | thistick;

% get the subject responses this will mimic hitting the button keys
ttlbuttons = bitand(bitshift(digport,-myscreen.digin.responseline),1);
% now set the keycodes as if the number corresponding to any responseline that is
% set to 1 had been pressed
ttlbuttons = find(ttlbuttons);
if ~isempty(ttlbuttons)
  myscreen.keyCodes = [myscreen.keyCodes myscreen.keyboard.nums(ttlbuttons)];
  myscreen.keyTimes = [myscreen.keyTimes repmat(mglGetSecs,1,length(ttlbuttons))];
end

% if we are transitioning into a tick down state
% then this is the beginning of a new volume
if (thistick)
  if (myscreen.intick == 0)
    myscreen = writeTrace(1,1,myscreen);
    myscreen.intick = 1;
    myscreen.volnum = myscreen.volnum+1;
  end
else
  if (myscreen.intick)
    myscreen = writeTrace(0,1,myscreen);
    myscreen.intick = 0;
  end
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


