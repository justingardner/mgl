% tickScreen.m
%
%        $Id$
%      usage: tickScreen
%         by: justin gardner
%       date: 12/10/04
%  copyright: (c) 2006 Justin Gardner (GPL see mgl/COPYING)
%    purpose: flip screen and update counter - for MGL
%
function myscreen = tickScreen(myscreen,task)

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get back tick status
%%%%%%%%%%%%%%%%%%%%%%%%%%%
thistick = mglGetKeys(myscreen.keyboard.backtick);
ttltick = readDigPort & 1;

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
mglFlush();

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% check for dropped frames
%%%%%%%%%%%%%%%%%%%%%%%%%%%
if myscreen.checkForDroppedFrames
  fliptime = GetSecs;
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
  % make sure the variable myscreen is set in caller context
  assignin('caller','myscreen',myscreen);
  % use try/catch to return to sender
  error('taskend');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% update tick
%%%%%%%%%%%%%%%%%%%%%%%%%%%
myscreen.tick = myscreen.tick + 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if called for pause on space bar
%%%%%%%%%%%%%%%%%%%%%%%%%%%
if myscreen.allowpause && mglGetKeys(myscreen.keyboard.space)
  mydisp(sprintf('PAUSED: hit RETURN to continue'));
  while ~mglGetKeys(myscreen.keyboard.return)
  end
end


