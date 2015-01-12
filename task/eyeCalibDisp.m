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
function myscreen = eyeCalibDisp(myscreen,dispText)

if nargin < 1
  help eyeCalibDisp;
  return
end

% nothing to do with no eye tracker
if ~isfield(myscreen,'eyeTrackerType') || strcmp(lower(myscreen.eyeTrackerType),'none')
  disp(sprintf('(eyeCalibDisp) Eye tracker type set to none. You can change this in mglEditScreenParams'));
  return
end

% set the screen background color
if (myscreen.background ~= 0)
  mglClearScreen(myscreen.background);
else
  mglClearScreen;
end

% display text if called for
if (nargin > 1) && isstr(dispText) && ~isempty(dispText)
  mglTextDraw(dispText,[0 0]);
else
  mglTextDraw('Hit <space> to calibrate eye tracker, <return> to skip.',[0 0]);
end
% flush screen
myscreen = tickScreen(myscreen,[]);


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
      mglClearScreen;myscreen = tickScreen(myscreen,[]);
      return
    end
    if any(keyCodes == myscreen.keyboard.return)
      mglClearScreen;myscreen = tickScreen(myscreen,[]);
      % starting experiment, start the eye tracker
      % but without calibration
      myscreen = startTracker(myscreen,0);
      mglClearScreen;myscreen = tickScreen(myscreen,[]);
      myscreen.fliptime = inf;
      return
    end
    [keyCodes keyTimes] = mglGetKeyEvent([],1);
  end
end

if ~isfield(myscreen,'eyeTrackerType')
  disp(sprintf('(eyeCalibDisp) No eyeTrackerType has been set'));
  return;
end

myscreen = startTracker(myscreen,1);

%%%%%%%%%%%%%%%%%%%%%%
%%   startTracker   %%
%%%%%%%%%%%%%%%%%%%%%%
function myscreen = startTracker(myscreen,calibrate)

if strcmp(lower(myscreen.eyeTrackerType),'eyelink')
  % set up eye tracker
  myscreen.eyetracker.savedata = true;
  myscreen.eyetracker.data = [1 1 1 0]; % don't need link events
  myscreen = initEyeTracker(myscreen, 'Eyelink');
  % run calibration
  if calibrate,myscreen = calibrateEyeTracker(myscreen);end
  % start recording
  if (myscreen.eyetracker.init) && (myscreen.eyetracker.collectEyeData == 1)
    if  ~mglEyelinkRecordingCheck
      % if we are recording stop to reset.
      mglEyelinkRecordingStop();
    end
    mglEyelinkRecordingStart(myscreen.eyetracker.data);
  end
elseif strcmp(lower(myscreen.eyeTrackerType),'calibrate')
  if calibrate,doCalibration(myscreen);end
elseif strcmp(lower(myscreen.eyeTrackerType),'asl')
  myscreen = initEyeTracker(myscreen, 'ASL');
  if calibrate,doCalibration(myscreen);end
elseif isempty(myscreen.eyeTrackerType)
  disp(sprintf('(eyeCalibDisp) No eyeTracker type set in mglEditScreenParams'));
else
  disp(sprintf('(eyeCalibDisp) Unknown eyeTracker type %s',myscreen.eyeTrackerType))
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

% put a pulse out if we are using digio
if myscreen.useDigIO, mglDigIO('digout',0,0);end

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
    if myscreen.useDigIO, mglDigIO('digout',0,255);end
  else
    if myscreen.useDigIO, mglDigIO('digout',0,0);end
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
