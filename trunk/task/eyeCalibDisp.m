% eyeCalibDisp.m
%
%        $Id$
%      usage: myscreen = eyeCalibDisp(myscreen,<dispText>)
%         by: justin gardner
%       date: 12/10/04
%  copyright: (c) 2006 Justin Gardner (GPL see mgl/COPYING)
%    purpose: run eye calibration routine, dispText is optional argument that
%             will display the passed in text before the eye calibration routinei
%

% TODO: make this function generic with respect to the eyetracker used
function myscreen = eyeCalibDisp(myscreen,dispText)

% set the screen background color
if (myscreen.background ~= 0)
  mglClearScreen(myscreen.background);
end
% display text if called for
if (nargin > 1) && isstr(dispText) && ~isempty(dispText)
  mglTextDraw(dispText,[0 0]);
end
% flush screen
myscreen = tickScreen(myscreen);


if (myscreen.eyecalib.prompt)
  % check for space key
  disp(sprintf('-----------------------------'));
  disp(sprintf('Hit SPACE to do eye calibration'));
  disp(sprintf('ENTER to skip eye calibration'));
  disp(sprintf('Esc aborts at any time'));
  disp(sprintf('-----------------------------'));
  drawnow;
  keyCodes=[];
  while ~any(keyCodes==myscreen.keyboard.space)
    if any(keyCodes == myscreen.keyboard.esc)
      mglClearScreen;myscreen = tickScreen(myscreen);
      return
    end
    if any(keyCodes == myscreen.keyboard.return)
      mglClearScreen;myscreen = tickScreen(myscreen);
      % starting experiment, start the eye tracker
%XXX      writeDigPort(16,2);
      %myscreen.fishcamp = bitor(myscreen.fishcamp,1);
      %fishcamp(1,myscreen.fishcamp);
      % reset fliptime
      mglClearScreen;myscreen = tickScreen(myscreen);
      myscreen.fliptime = inf;
      return
    end
    [keyCodes keyTimes] = mglGetKeyEvent([],1);
  end
end

% set up eye tracker
myscreen.eyetracker.savedata = true;
myscreen.eyetracker.data = [1 1 1 0]; % don't need link events
myscreen = initEyeTracker(myscreen, 'Eyelink');
myscreen = calibrateEyeTracker(myscreen);

function retval = waitSecsEsc(waitTime,myscreen)

retval = 1;
startTime = mglGetSecs;
while mglGetSecs(startTime) <= waitTime
  [keyCodes keyTimes] = mglGetKeyEvent([],1);
  if any(keyCodes==myscreen.keyboard.esc)
    retval = -1;
    return
  end
end