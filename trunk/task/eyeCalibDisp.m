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

if nargin < 1
  help eyeCalibDisp;
  return
end

% set the screen background color
if (myscreen.background ~= 0)
  mglClearScreen(myscreen.background);
end
% display text if called for
if (nargin > 1) && isstr(dispText) && ~isempty(dispText)
  mglTextDraw(dispText,[0 0]);
else
  mglTextDraw('Hit <space> to calibrate eye tracker, <return> to skip.',[0 0]);
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

if strcmp(lower(myscreen.eyeTrackerType),'eyelink')
  % set up eye tracker
  myscreen.eyetracker.savedata = true;
  myscreen.eyetracker.data = [1 1 1 0]; % don't need link events
  myscreen = initEyeTracker(myscreen, 'Eyelink');
  myscreen = calibrateEyeTracker(myscreen);

  % start recording
  if (myscreen.eyetracker.init) && (myscreen.eyetracker.collectEyeData == 1)
    if  ~mglEyelinkRecordingCheck
      % if we are recording stop to reset.
      mglEyelinkRecordingStop();
    end
    mglPrivateEyelinkRecordingStart(myscreen.eyetracker.data);
  end
elseif strcmp(lower(myscreen.eyeTrackerType),'calibrate')
  doCalibration(myscreen);
elseif isempty(myscreen.eyeTrackerType)
  disp(sprintf('(eyeCalibDisp) No eyeTracker type set in mglEditScreenParams'));
else
  disp(sprintf('(eyeCalibDisp) Unknown eyeTracker type %s',myscreen.eyeTrackerTYpe))
end

  
%%%%%%%%%%%%%%%%%%%%%
%    waitSecsEsc    %
%%%%%%%%%%%%%%%%%%%%%
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

%%%%%%%%%%%%%%%%%%%%%%%
%    doCalibration    %
%%%%%%%%%%%%%%%%%%%%%%%
function doCalibration(myscreen)

% put fixation in center of screen to allow subject to get there in time
mglClearScreen;
mglGluDisk(0,0,myscreen.eyecalib.size/2,myscreen.eyecalib.color);
mglFlush;
if waitSecsEsc(2,myscreen) == -1,return,end

% make sure eye tracker is on and recording that this is an eyecalibration
%myscreen.fishcamp = bitor(myscreen.fishcamp,bin2dec('101'));
%fishcamp(1,myscreen.fishcamp);
%XXX writeDigPort(16,2);

for j = 1:myscreen.eyecalib.n
  mglClearScreen;
  mglGluDisk(myscreen.eyecalib.x(j),myscreen.eyecalib.y(j),myscreen.eyecalib.size/2,myscreen.eyecalib.color);
  mglFlush;
  if ((myscreen.eyecalib.x(j) ~= 0) || (myscreen.eyecalib.y(j) ~= 0))
%XXX    writeDigPort(48,2);
  else
%XXX    writeDigPort(16,2);
  end
  startTime = mglGetSecs;
  if ~isinf(myscreen.eyecalib.waittime)
    while (myscreen.eyecalib.waittime > (mglGetSecs-startTime));
      [keyCodes keyTimes] = mglGetKeyEvent([],1);
      if any(keyCodes==myscreen.keyboard.esc)
        mglClearScreen;mglFlush;
        mglClearScreen;mglFlush;
        return
      end
    end
  else
    input(sprintf('Hit ENTER to continue'));
  end
end
mglClearScreen;mglFlush;
mglClearScreen;mglFlush;

% turn off trace for eye calibration
%myscreen.fishcamp = bitand(hex2dec('FF01'),myscreen.fishcamp);
%fishcamp(1,myscreen.fishcamp);
% reset fliptime
myscreen.fliptime = inf;
