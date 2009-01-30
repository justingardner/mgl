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
% read the keyboar backtick
%thistick = mglGetKeys(myscreen.keyboard.backtick);

% get all pending keyboard events
[myscreen.keyCodes myscreen.keyTimes] = mglGetKeyEvent([],1);

thistick = any(myscreen.keyboard.backtick == myscreen.keyCodes);

% read the TTL pulse (comment out to prevent reading digital port)
%ttltick = readDigPort;
%ttltick = (ttltick>0) && (ttltick&1);
%thistick = ttltick | thistick;

% if we are transitioning into a tick down state
% then this is the beginning of a new volume
if (thistick)
  if (myscreen.intick == 0)
    myscreen = writeTrace(1,1,myscreen);
    myscreen.intick = 1;
    myscreen.volnum = myscreen.volnum+1;
    %fishcamp(1,bitor(myscreen.fishcamp,bin2dec('10')));
  end
else
  if (myscreen.intick)
    myscreen = writeTrace(0,1,myscreen);
    myscreen.intick = 0;
    %fishcamp(1,myscreen.fishcamp);
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


