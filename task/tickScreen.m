% tickScreen.m
%
%        $Id$
%      usage: tickScreen
%         by: justin gardner
%       date: 12/10/04
%  copyright: (c) 2006 Justin Gardner (GPL see mgl/COPYING)
%    purpose: flip screen and update counter - for MGL
%
function [myscreen task] = tickScreen(myscreen,task)

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get back tick status
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% read the keyboar backtick
thistick = mglGetKeys(myscreen.keyboard.backtick);

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
if ~myscreen.flushOnce
  mglFlush();
% but if flushOnce is set then we flush the screen once
elseif myscreen.flushOnce == 1
  mglFlush();
  myscreen.flushOnce = 2;
  myscreen.startOfFlush = mglGetSecs;
% and then on subsequent calls we just wait 1/framesPerSecond
elseif myscreen.flushOnce > 1
  mglWaitSecs(myscreen.frametime-mglGetSecs(myscreen.startOfFlush));
  myscreen.startOfFlush = mglGetSecs;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% check for dropped frames
%%%%%%%%%%%%%%%%%%%%%%%%%%%
if myscreen.checkForDroppedFrames
  fliptime = mglGetSecs;
  if ((fliptime-myscreen.fliptime) > myscreen.dropThreshold*myscreen.frametime)
    %disp(sprintf('Dropped frame (%0.5f)',fliptime-myscreen.fliptime));
    myscreen.dropcount = myscreen.dropcount+1;
  end
  if (myscreen.fliptime ~= inf)
    myscreen.totalflip = myscreen.totalflip+(fliptime-myscreen.fliptime);
  else
    myscreen.totalflip = 0;
    myscreen.dropcount = 0;
  end
  myscreen.fliptime = fliptime;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% check for esc key
%%%%%%%%%%%%%%%%%%%%%%%%%%%
if mglGetKeys(myscreen.keyboard.esc)
  myscreen.userHitEsc = 1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% update tick
%%%%%%%%%%%%%%%%%%%%%%%%%%%
myscreen.tick = myscreen.tick + 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if called for pause on space bar
%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (myscreen.allowpause && mglGetKeys(myscreen.keyboard.space)) || myscreen.paused
  startPause = mglGetSecs;
  disp(sprintf('PAUSED: hit SPACE to advance a frame RETURN to continue'));
  % wait till space bar is no loner down
  while mglGetKeys(myscreen.keyboard.space)
  end
  keys = 0;
  % then check for return or space
  while ~any(keys)
    keys = mglGetKeys([myscreen.keyboard.return myscreen.keyboard.space]);
  end
  if keys(2),myscreen.paused = 1;else,myscreen.paused = 0;end
  % fix task times
  task = pauseTask(task,mglGetSecs(startPause));
  myscreen.fliptime = mglGetSecs;
end


