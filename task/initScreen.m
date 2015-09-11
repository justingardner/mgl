% initScreen.m
%
%        $Id$
%      usage: myscreen = initScreen(myscreen, randstate)
%         by: justin gardner
%       date: 12/10/04
%  copyright: (c) 2006 Justin Gardner (GPL see mgl/COPYING)
%    purpose: init screen parameters (using mgl)
%
function myscreen = initScreen(myscreen,randstate)

% see if passed in myscreen variable is actually the name of a monitor to open
if exist('myscreen','var') && (isstr(myscreen) || (isnumeric(myscreen) && isscalar(myscreen)))
  displayname = myscreen;
  clear myscreen;
  % see if it is a computer:displayname field
  colonloc = findstr(':',displayname);
  if length(colonloc) == 1
    myscreen.computer = displayname(1:colonloc-1);
    displayname = displayname(colonloc+1:end);
  end
  % set the display name
  myscreen.displayName = displayname;
end

% check the system for any issues with keyboard/mouse
if ~mglSystemCheck(2)
  myscreen = [];
  return
end

% set version number
myscreen.ver = 2.0;

% Get SID
myscreen.SID = mglGetSID;
% check if we have to set sid and it has not been set
if isempty(myscreen.SID) && isequal(mglGetParam('mustSetSID'),1)
  disp(sprintf('(initScreen) !!! You must set a SID before running. !!!'));
  myscreen = [];
  disp(sprintf('Quit out of debug mode K>> by doing dbquit then run mglSetSID'));
  keyboard
end

% get computer name
if ~isfield(myscreen,'computer')
  myscreen.computer = mglGetHostName;
end

% get the computer short name - which is like terranova if the full name is terranova.bnf.brain.riken.edu
myscreen.computerShortname = strtok(myscreen.computer,'.');

% default monitor gamma (used when there is no calibration file)
defaultMonitorGamma = 1.8;

% correct capitalization
if isfield(myscreen,'displayname')
  myscreen.displayName = myscreen.displayname;
  myscreen = rmfield(myscreen,'displayname');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% database parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[screenParams screenParamsFilename] = mglGetScreenParams;

% check for passed in screenParams
if isfield(myscreen,'screenParams')
  screenParams = myscreen.screenParams;
  screenParamsFilename = '';
  rmfield(myscreen,'screenParams');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% convert screenParams to new format and validate that the field names are correct
% and properly captialized
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% list of possible screenParams
screenParamsList = {'computerName', 'displayName', 'screenNumber',...
		    'screenWidth', 'screenHeight', 'displayDistance',...
		    'displaySize', 'framesPerSecond','autoCloseScreen',...
		    'saveData', 'calibType', 'monitorGamma', 'calibFilename', ...
		    'flipHV', 'digin', 'hideCursor', 'displayPos', 'backtickChar',...
		    'responseKeys', 'eyeTrackerType', 'eatKeys','squarePixels',...
		    'calibProportion','simulateVerticalBlank','shiftOrigin',...
		    'crop','cropScreen','scale','scaleScreen'};

for i = 1:length(screenParams)
  %% see if we need to convert from cell array to struct -- old version
  %% was just a cell array of params, new version is a struct with field names
  if ~isstruct(screenParams{i})
    thisScreenParams = screenParams{i};
    screenParams{i} = [];
    for j = 1:min(length(thisScreenParams),length(screenParamsList))
      screenParams{i}.(screenParamsList{j}) = thisScreenParams{j};
    end
  end
  % validate fields
  screenParams = mglValidateScreenParams(screenParams);
end

% if there is no displayName then see if we should use a default
if ~isfield(myscreen,'displayName')
  % if defaultDisplayName is set
  defaultDisplayName = mglGetParam('defaultDisplayName');
  if ~isempty(defaultDisplayName)
    % then check through screen params to see
    % if there is one with that display name
    for i = 1:length(screenParams)
      if isequal(screenParams{i}.displayName,defaultDisplayName)
	% if there is, then set myscreen to use that name
	myscreen.displayName = defaultDisplayName;
      end
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% find matching database parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
foundComputer = 0;
for pnum = 1:length(screenParams)
  if ~isempty(findstr(myscreen.computerShortname,screenParams{pnum}.computerName))
    % if no displayName is asked for or no displayname is set in the screenParams
    % then only accept the computer if we haven't already found it
    if (foundComputer == 0) && (isempty(screenParams{pnum}.displayName) || ~isfield(myscreen,'displayName'))
      foundComputer = pnum;
      % check for matching displayname
    elseif isfield(myscreen,'displayName') && isstr(myscreen.displayName) && strcmp(lower(myscreen.displayName),lower(screenParams{pnum}.displayName))
      foundComputer = pnum;
      % check for matching display number
    elseif isfield(myscreen,'displayName') && isnumeric(myscreen.displayName) && isequal(myscreen.displayName,screenParams{pnum}.screenNumber)
      foundComputer = pnum;
    end
  end
end

% if not found, maybe it is because computerName is not set correctly
% so go through again looking for any match of displayName even if
% the computerName is not a match
if ~foundComputer && isfield(myscreen,'displayName')
  for pnum = 1:length(screenParams)
    % match for display name
    if strcmp(lower(myscreen.displayName),lower(screenParams{pnum}.displayName))
      % choose it then.
      if ~foundComputer
	foundComputer = pnum;
	disp(sprintf('(initScreen) !!! Matching displayName: %s but computerName %s does not mach this computer name: %s !!!',screenParams{pnum}.displayName,screenParams{pnum}.computerName,myscreen.computerShortname));
      end
    end
  end
end

% if not found, maybe it just because displayName is not set correctly
% so go through again looking for any match even if the displayName is
% not a match
if ~foundComputer
  % also, get defaultDisplayName
  defaultDisplayName = mglGetParam('defaultDisplayName');
  for pnum = 1:length(screenParams)
    % choose a matching computer name and if possible one with a matching defaultDisplayName
    if ~foundComputer || isequal(screenParams{pnum}.displayName,defaultDisplayName)
      foundComputer = pnum;
    end
  end
end

% display hail string
disp(sprintf('%s Begin initScreen %s',repmat('=+',1,20),repmat('=+',1,20)));

% display subject ID
if isfield(myscreen,'SID') && ~isempty(myscreen.SID)
  disp(sprintf('(initScreen) SID is: %s',myscreen.SID));
else
  disp(sprintf('(initScreen) No SID has been set'));
end

% check to make sure that we have found the computer in the table
if foundComputer
  % display the match
  if ~isempty(screenParams{foundComputer}.displayName)
    % give warning if we do not have a match of the displayName
    if isfield(myscreen,'displayName') && ~strcmp(screenParams{foundComputer}.displayName,myscreen.displayName)
      disp(sprintf('(initScreen) !!! No display name %s found. Using instead %s !!!',myscreen.displayName,screenParams{foundComputer}.displayName));
    end
    disp(sprintf('(initScreen) Monitor parameters for: %s displayName: %s',screenParams{foundComputer}.computerName,screenParams{foundComputer}.displayName));
  else
    % give warning if we were asked for a specific one
    if isfield(myscreen,'displayName')
      disp(sprintf('(initScreen) !!! No display name %s found. !!!',myscreen.displayName,screenParams{foundComputer}.displayName));
    end
    disp(sprintf('(initScreen) Monitor parameters for: %s',screenParams{foundComputer}.computerName));
  end
  % setup all parameters for the monitor (if the settings are
  % already set in myscreen then do nothing)
  screenParamsFieldnames = fieldnames(screenParams{foundComputer});
  for j = 1:length(screenParamsFieldnames)
    if ~strcmp(screenParamsFieldnames{j},'computerName') && ~strcmp(screenParamsFieldnames{j},'displayName')  
      % if the field doesn't already exist in myscreen
      if ~isfield(myscreen,screenParamsFieldnames{j}) 
	% then set the field
	myscreen.(screenParamsFieldnames{j}) = screenParams{foundComputer}.(screenParamsFieldnames{j});
      end
    end
  end
end

%%%%%%%%%%%%%%%%%
% defaults if they have not been set
%%%%%%%%%%%%%%%%%
if ~isfield(myscreen,'displayName')
  myscreen.displayName = [];
end
if ~isfield(myscreen,'screenNumber')
  myscreen.screenNumber = [];
end
if ~isfield(myscreen,'screenWidth')
  myscreen.screenWidth = [];
end
if ~isfield(myscreen,'screenHeight')
  myscreen.screenHeight = [];
end
if ~isfield(myscreen,'displayDistance')
  myscreen.displayDistance = 57;
end
if ~isfield(myscreen,'displaySize')
  myscreen.displaySize = [31 23];
end
if ~isfield(myscreen,'displayPos')
  myscreen.displayPos = [0 0];
end
if ~isfield(myscreen,'framesPerSecond')
  myscreen.framesPerSecond = 60;
end
if ~isfield(myscreen,'autoCloseScreen')
  myscreen.autoCloseScreen = 1;
end
if ~isfield(myscreen,'saveData')
  myscreen.saveData = -1;
end
if ~isfield(myscreen,'flipHV')
  myscreen.flipHV = [0 0];
end
if ~isfield(myscreen,'digin')
  myscreen.digin = [];
end
if ~isfield(myscreen,'displayName')
  myscreen.displayName = [];
end
if ~isfield(myscreen,'calibType')
  myscreen.calibType = 'None';
end
if ~isfield(myscreen,'hideCursor')
  myscreen.hideCursor = 0;
end
if ~isfield(myscreen,'backtickChar')
  myscreen.backtickChar = '`';
end
if ~isfield(myscreen,'responseKeys')
  myscreen.responseKeys = {'1' '2' '3' '4' '5' '6' '7' '8' '9' '0'};
end
if ~isfield(myscreen,'eatKeys')
  myscreen.eatKeys = 0;
end
if ~isfield(myscreen,'squarePixels')
  myscreen.squarePixels = 0;
end
if ~isfield(myscreen,'calibProportion')
  myscreen.calibProportion = 0.36;
end
if ~isfield(myscreen,'eyeTrackerType')
  myscreen.eyeTrackerType = 'None';
end
if ~isfield(myscreen,'useScreenMask')
  myscreen.useScreenMask = false;
end

myscreen.pwd = pwd;

% setting to ignore initial vols
myscreen.ignoreInitialVols = mglGetParam('ignoreInitialVols');
if isempty(myscreen.ignoreInitialVols) myscreen.ignoreInitialVols = 0;end
disp(sprintf('(initScreen) ignoreInitialVols = %i',myscreen.ignoreInitialVols));
myscreen.ignoredInitialVols = myscreen.ignoreInitialVols;

%%%%%%%%%%%%%%%%%
% print display settings
%%%%%%%%%%%%%%%%%
if foundComputer
  % display the settings
  if ~isempty(myscreen.displayDistance) & ~isempty(myscreen.displaySize)
    disp(sprintf('(initScreen) %0.1f: %ix%i(pix) dist:%0.1f (cm) size:%0.1fx%0.1f (cm) %iHz save:%i autoclose:%i flipHV:[%i %i]',myscreen.screenNumber,myscreen.screenWidth,myscreen.screenHeight,myscreen.displayDistance,myscreen.displaySize(1),myscreen.displaySize(2),myscreen.framesPerSecond,myscreen.saveData,myscreen.autoCloseScreen,myscreen.flipHV(1),myscreen.flipHV(2)));
  end
else
  disp(sprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'));
  if ~isempty(screenParamsFilename)
    if ~isempty(myscreen.displayName)
      disp(sprintf('(initScreen) Could not find computer: %s with display: %s in %s',myscreen.computer,myscreen.displayName,screenParamsFilename));
    else
      disp(sprintf('(initScreen) Could not find computer: %s in screenParams file %s',myscreen.computer,screenParamsFilename));
    end
  else
    disp(sprintf('(initScreen) Could not find computer %s in myscreen.screenParams\n',myscreen.computer));
  end
  disp(sprintf('(initScreen) Using default parameters'));
  disp(sprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'));
end

% decided where to store data
if ~isfield(myscreen,'datadir')
  myscreen.datadir = '~/data';
end

if ~isdir(myscreen.datadir)
  disp(sprintf('(initScreen) Could not find directory %s. Using current directory',myscreen.datadir));
  % use current directory instead
  myscreen.datadir = '';
end


% if subjectID is set then make a special data dir
if isfield(myscreen,'subjectID') || (isfield(myscreen,'SID') && ~isempty(myscreen.SID))
  % subjectID used to be specified. Keeping that, but also now
  % alllowing for setting by mglSetSID (which gets set as myscreen.SID);
  if isfield(myscreen,'subjectID')
    SID = myscreen.subjectID;
  else
    SID = myscreen.SID;
  end
  % first get calling function name
  [st,i] = dbstack;
  callingFunName = st(min(i+1,length(st))).file;
  [dummy1 callingFunName dummy2] = fileparts(callingFunName);
  % if this is not initScreen (i.e. if it is called from a task program)
  if ~isempty(callingFunName) && ~isequal(lower(callingFunName),'initscreen')
    % set data directory to be ~/data / functionname / subjectID
    myscreen.datadir = fullfile(myscreen.datadir,callingFunName);
    if ~isdir(myscreen.datadir)
      mkdir(myscreen.datadir);
    end
    % add subjectID
    if ~isempty(SID)
      myscreen.datadir = fullfile(myscreen.datadir,SID);
      if ~isdir(myscreen.datadir)
	mkdir(myscreen.datadir);
      end
    end
  end
  if isfield(myscreen,'subjectFolder')
    myscreen.datadir = fullfile(myscreen.datadir,myscreen.subjectFolder);
    if ~isdir(myscreen.datadir),mkdir(myscreen.datadir);end
  end
  disp(sprintf('(initScreen) Saving data into %s',myscreen.datadir));
end

% compute the time per frame
myscreen.frametime = 1/myscreen.framesPerSecond;

% get matlab version
matlabVersion = version;
myscreen.matlab.version = matlabVersion;
[matlabMajorVersion matlabVersion] = strtok(matlabVersion,'.');
myscreen.matlab.majorVersion = str2num(matlabMajorVersion);
myscreen.matlab.minorVersion = str2num(strtok(matlabVersion,'.'));

% initialize digital port
myscreen.useDigIO = 0;
if isfield(myscreen,'digin') 
  if ~isempty(myscreen.digin) && isfield(myscreen.digin,'use') && isequal(myscreen.digin.use,1)
    % set like we are using digio
    myscreen.useDigIO = myscreen.digin.use;
    % validate portNum and give message. If we fail the validation set useDigIO back to false
    if isempty(myscreen.digin.portNum) || ~isnumeric(myscreen.digin.portNum) || ~isequal(length(myscreen.digin.portNum),1) || ~any(myscreen.digin.portNum==[0:9])
      disp(sprintf('(initScreen) !!! portNum for digital input should be set to a number like 0, 1 or 2 to specify which port on the NI device you want to read for digital input. Not checking digIO !!!'));
      myscreen.useDigIO = false;
    end
    % validate digital acquisition line
    if ~isempty(myscreen.digin.acqLine)
      if ~isnumeric(myscreen.digin.acqLine) || ~isequal(length(myscreen.digin.acqLine),1) || ~any(myscreen.digin.acqLine==[0:7])
	disp(sprintf('(initScreen) !!! No valid acqLine has been set for digital magnet acquisition pulses (should be a number between 0-7 which specifies which line to read to specify magnet acquisitions (TRs) !!!'));
	myscreen.digin.acqLine = -1;
      end
    else
      myscreen.digin.acqLine = -1;
    end
    % validate digital acquisition type
    if ~isequal(myscreen.digin.acqLine,-1) && (isempty(myscreen.digin.acqType) || ~isnumeric(myscreen.digin.acqType) || ~all(ismember(myscreen.digin.acqType,[0 1])))
	disp(sprintf('(initScreen) !!! No valid acqType has been set for digital acquisition. acqType specifies when a trigger is considered to signal an acquisition - if set to 1 that means to count when digital in has gone high, if set to 0 means to count when digital in has gone low. If set to [0 1] specifies both of these count as events !!!'));
    end
    % check response lines
    if ~all(ismember(myscreen.digin.responseLine,0:9))
      disp(sprintf('(initScreen) !!! The responseLines for digio should be set to numbers from 0 to 7 which specify which lines of digital input correspond to subject button presses !!!'));
    end
    % check response types
    if ~isempty(myscreen.digin.responseLine) && (isempty(myscreen.digin.responseType) || ~isnumeric(myscreen.digin.responseType) || ~all(ismember(myscreen.digin.responseType,[0 1])))
	disp(sprintf('(initScreen) !!! No valid responseType has been set for digital acquisition. responseType specifies when a response button digital pulse is considered to signal a subject response - if set to 1 that means to count when digital in has gone high, if set to 0 means to count when digital in has gone low. If set to [0 1] specifies both of these count as events !!!'));
    end
    % try to open the port
    digioRetval = mglDigIO('init',myscreen.digin.portNum);
    if isempty(digioRetval)
      disp(sprintf('(initScreen) !!! Failed to open Digitial IO ports. Only using keyboard backticks now! You many need to compile digio using mglMake(''digio'')!!!'));
    end
    if isequal(digioRetval,0)
      disp(sprintf('(initScreen) !!! Failed to open Digitial IO ports. Only using keyboard backticks now!!!'));
      myscreen.useDigIO = 0;
    else
      % grab any pending events
      mglDigIO('digin');
    end
  end
end

% decide which rand algorithim to use
if (myscreen.matlab.majorVersion>=7) && (myscreen.matlab.minorVersion>=4)
  myscreen.randstate.type = 'twister';
else
  myscreen.randstate.type = 'state';
end

% save rand number generator state
if ~exist('randstate','var') || isempty(randstate)
  % no passed in value, set to a random state
  myscreen.randstate.state = sum(100*clock);
else
  % use passed in randstate
  if ~isstruct(randstate)
    % set the state
    myscreen.randstate.state = randstate;
    % old way, in which the 'state' value was returned
    if ~isscalar(randstate)
      myscreen.randstate.type = 'state';
    end
    %new way in which a structure is saved
  else
    myscreen.randstate = randstate;
  end
end
% now set the state of the random number generator
rand(myscreen.randstate.type,myscreen.randstate.state);

% don't allow pause unless explicitly passed in
if ~isfield(myscreen,'allowpause')
  myscreen.allowpause = 0;
end
myscreen.paused = 0;

% get info about openGL renderer
openGLinfo = [];
if exist('opengl')==2
  if isempty(mglGetParam('displayNumber'))
    openGLinfo = opengl('data');
  end
end

% set device origin if called for - this will shift the screen origin by the set amount
if isfield(myscreen,'shiftOrigin') && (length(myscreen.shiftOrigin) >= 2)
  % get how much shift is called for
  deviceOrigin = myscreen.shiftOrigin(:)';
  deviceOrigin(isnan(deviceOrigin)) = 0;
  if length(deviceOrigin) < 3,deviceOrigin(3) = 0;end
  % display it
  if ~all(deviceOrigin == 0)
    disp(sprintf('(initScreen) Shifting screen origin by [%0.3f %0.3f %0.3f] deg',deviceOrigin(1),deviceOrigin(2),deviceOrigin(3)));
  end
  % set the device origin this is used by mglVisualAngleCoordinates when
  % setting the coordinate frame
  mglSetParam('deviceOrigin',deviceOrigin);
else
  mglSetParam('deviceOrigin',[0 0 0]);
end

% init the mgl screen
if ~isempty(myscreen.screenNumber)
  if isempty(mglResolution(myscreen.screenNumber))
    disp(sprintf('(initScreen) !!! Screen %i does not exist !!!',myscreen.screenNumber));
    myscreen = [];
    return
  end
  % setting with specified screenNumber
  mglOpen(myscreen.screenNumber, myscreen.screenWidth, myscreen.screenHeight, myscreen.framesPerSecond);
  % move the screen if it is a windowed context, and displayPos has been set.
  if myscreen.screenNumber < 1
    if length(myscreen.displayPos) == 2
      mglMoveWindow(myscreen.displayPos(1),myscreen.displayPos(2)+myscreen.screenHeight);
    end
  end
else
  % otherwise open a default window
  mglOpen;
  myscreen.screenWidth = mglGetParam('screenWidth');
  myscreen.screenHeight = mglGetParam('screenHeight');
end

% check to make sure we opened up correctly
if isequal(mglGetParam('displayNumber'),-1)
  disp(sprintf('(initScreen) Unable to open screen'));
  keyboard
end

% use visual angle coordinates
% if monitor size is set, then this is a value
% in inches along the diagonal of the screen
if isempty(myscreen.displayDistance) | isempty(myscreen.displaySize)
  disp('(initScreen) Could not find display parameters');
  return
end

% set whether to use square voxels
mglSetParam('visualAngleSquarePixels',myscreen.squarePixels);
% and what proportion to calibrate off of
mglSetParam('visualAngleCalibProportion',myscreen.calibProportion);

% set the scaling (this used to artifically scale the monitor dims
% from what they should be based on distance). You might want to
% do this if you want to artificially scale the whole display
% of a program without rewriting the code.
if isfield(myscreen,'scale') && myscreen.scale && isfield(myscreen,'scaleScreen') && ~any(myscreen.scaleScreen==0) && (length(myscreen.scaleScreen) == 2)
  disp(sprintf('(initScreen) !!! Artificially setting the dimensions by %0.3f x %0.3f of what they should be based on the monitor size and distance !!!',myscreen.scaleScreen(1),myscreen.scaleScreen(2)));
  mglSetParam('visualAngleScale',myscreen.scaleScreen(:)');
else
  mglSetParam('visualAngleScale',[]);
end
  
% now set visual angle coordinates
mglVisualAngleCoordinates(myscreen.displayDistance,myscreen.displaySize);
myscreen.imageWidth = mglGetParam('deviceWidth');
myscreen.imageHeight = mglGetParam('deviceHeight');

% set the crop region (this is simply the imageWidth and imageHeight)
if isfield(myscreen,'crop') && myscreen.crop && isfield(myscreen,'cropScreen') && (length(myscreen.cropScreen)==2)
  if myscreen.cropScreen(1) > 0
    myscreen.imageWidth = myscreen.cropScreen(1);
  end
  if myscreen.cropScreen(2) > 0
    myscreen.imageHeight = myscreen.cropScreen(2);
  end
  disp(sprintf('(initScreen) Croping image dimensions to %0.3f x %0.3f',myscreen.imageWidth,myscreen.imageHeight));
end

% flip the screen appropriately
if myscreen.flipHV(1)
  disp('(initScreen) Flipping coordinates horizontally');
  mglHFlip;
end
if myscreen.flipHV(2)
  disp('(initScreen) Flipping coordinates vertically');
  mglVFlip;
end

% set up indexes appropriately
myscreen.black = 0;myscreen.white = 1;myscreen.gray = 0.5;
myscreen.blackIndex = 0;
myscreen.whiteIndex = 255;
myscreen.grayIndex = 128;
myscreen.inc = myscreen.whiteIndex - myscreen.grayIndex;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Gamma correction of monitor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% but first go and check if we need to load a table
gammaNotSet = 1;

switch myscreen.calibType
 case {'None'}
  disp(sprintf('(initScreen) No gamma correction is being applied'));
 case {'Specify particular calibration','Find latest calibration'}
  if strcmp(myscreen.calibType,'Specify particular calibration')
    calibFilename = myscreen.calibFilename;
    % if the user specified a particular name for the calibration file.
    % this could either be an exact filename, or it could be one of a standard
    % set i.e. 0001_yoyodyne_LCD2_061013, so we check for those types
    % if we can't find the exact match
    [calibPath calibFilename] = fileparts(calibFilename);
    calibFilename = fullfile(calibPath,calibFilename);
    if ~isfile(sprintf('%s.mat',calibFilename))
      disp(sprintf('(initScreen) Could not find calibFilename: %s\n',calibFilename));
      calibFilename = getCalibFilename(myscreen,calibFilename);
    end
  else
    calibFilename = getCalibFilename(myscreen,myscreen.computer);
    if isempty(calibFilename)
      disp(sprintf('(initScreen) !!! No monitor calibration file found !!!'));
    end
  end
  % no go and try to use that calibration
  if ~isempty(calibFilename)
    if isfile(sprintf('%s.mat',calibFilename))
      load(calibFilename);
      if exist('calib','var') && isfield(calib,'table')
	myscreen.gammaTable = calib.table;
	mglSetGammaTable(myscreen.gammaTable);
	gammaNotSet = 0;
	[calibPath calibFilename] = fileparts(calibFilename);
	disp(sprintf('(initScreen) Gamma: Set to table from calibration file %s created on %s',calibFilename,calib.date));
	myscreen.calibFilename = calibFilename;
	myscreen.calibFullFilename = fullfile(calibPath,calibFilename);
      else
	disp(sprintf('(initScreen) !!! Calibration file %s does not have a valid calibration table !!!',calibFilename));
      end
    else
      disp(sprintf('(initScreen) ****Could not find montior calibration file %s***',calibFilename));
    end
  end
 case {'Gamma 1.8','Gamma 2.2','Specify gamma'}
  if strcmp(myscreen.calibType,'Gamma 1.8')
    myscreen.monitorGamma = 1.8;
  elseif strcmp(myscreen.calibType,'Gamma 2.2')
    myscreen.monitorGamma = 2.2;
  end
  if isempty(myscreen.monitorGamma)
    disp(sprintf('(initScreen) Not applying any gamma correction for this monitor'));
  else
    % display what the settings are
    disp(sprintf('(initScreen) Correcting for monitor gamma of %0.2f',myscreen.monitorGamma));

    % now get current gamma table
    gammaTable = mglGetParam('initialGammaTable');
    % and use linear interpolation to correct the current table to
    % make it 1/monitor gamma.
    correctedValues = ((0:1/255:1).^(1/myscreen.monitorGamma));
    gammaTable.redTable = interp1(0:1/255:1,gammaTable.redTable,correctedValues);
    gammaTable.greenTable = interp1(0:1/255:1,gammaTable.greenTable,correctedValues);
    gammaTable.blueTable = interp1(0:1/255:1,gammaTable.blueTable,correctedValues);
    % and set the table
    mglSetGammaTable(gammaTable);
  end
end

% keep initial gamma table
myscreen.initScreenGammaTable = mglGetGammaTable;

% if movieMode then 
if mglGetParam('movieMode') == 1
  % bring up the movie window and order it behind
  mglMovie('openWindow');
  mglMovie('moveWindowBehind');
  % and set background color to transparent
  myscreen.background = [0 0 0 0];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Gamma correction of monitor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% choose color for background
if isfield(myscreen,'background')
  if isstr(myscreen.background) 
    if strcmp(myscreen.background,'white')
      myscreen.background = myscreen.white;
    elseif strcmp(myscreen.background,'black')
      myscreen.background = myscreen.black;
    elseif strcmp(myscreen.background,'gray')
      myscreen.background = myscreen.gray;
    else
      disp(sprintf('(initScreen) Background color %s does not exist',myscreen.background));
      myscreen.background = myscreen.black;
    end
  end
else
  myscreen.background = myscreen.black;
end

% set up stencil mask if called for
if myscreen.useScreenMask
  % check for valid function
  if exist(myscreen.screenMaskFunction) == 2
    % check stencil bits
    if myscreen.screenMaskStencilNum <= mglGetParam('stencilBits')
      % clear screen
      mglClearScreen(0);
      % start stencil drawing
      mglStencilCreateBegin(myscreen.screenMaskStencilNum);
      % call the function to draw the stencil
      feval(myscreen.screenMaskFunction,myscreen);
      % and end stencil creation
      mglStencilCreateEnd(myscreen.screenMaskStencilNum);
      mglClearScreen(0);
      % This is an unusual global that is used to tell mglClearScreen
      % to use a mask when clearing the screen. Its a separate global
      % for speed because mglClearScreen is usually within frame updates.
      % Here we set it to the stencil number
      global mglGlobalClearWithMask;
      mglGlobalClearWithMask = myscreen.screenMaskStencilNum;
      % set the stencil
      mglStencilSelect(myscreen.screenMaskStencilNum);
    else
      disp(sprintf('(initScreen) !!! screenMaskStencilNum should be a number between 1 and %i, but is set to %i !!!',mglGetParam('stencilBits'),myscreen.screenMaskStencilNum));
    end
  else
    disp(sprintf('(initScreen) !!! Could not mask screen. Screen mask function: %s does not exist. !!!',myscreen.screenMaskFunction));
  end
end

% set background color  - mgl
mglClearScreen(myscreen.background);
mglFlush();
mglClearScreen(myscreen.background);
mglFlush();

disp(sprintf('(initScreen) imageWidth: %0.2f imageHeight: %0.2f',myscreen.imageWidth,myscreen.imageHeight));

% init number of ticks
myscreen.tick = 1;
myscreen.totaltick = 1;
myscreen.totalflip = 0;
myscreen.volnum = 0;
myscreen.intick = 0;
myscreen.fliptime = inf;
myscreen.dropcount = 0;
myscreen.checkForDroppedFrames = 1;
myscreen.dropThreshold = 1.05;

% set keyboard info
myscreen.keyboard.esc = 54;
myscreen.keyboard.return = 37;
myscreen.keyboard.space = mglCharToKeycode({' '});
% check if the backtick character is a number, then it means
% that it should be interpreted as a keycode otherwise
% it is a character
if isnumeric(myscreen.backtickChar)
  myscreen.keyboard.backtick = myscreen.backtickChar;
else
  myscreen.keyboard.backtick = mglCharToKeycode({myscreen.backtickChar});
end
% get the response keys
if ~isfield(myscreen.keyboard,'nums')
  % go through the settings, converting any characters to keyCodes
  for i = 1:length(myscreen.responseKeys)
    if isnumeric(myscreen.responseKeys{i})
      keyCode = myscreen.responseKeys{i};
    else
      keyCode = mglCharToKeycode({myscreen.responseKeys{i}});
    end
    myscreen.keyboard.nums(i) = keyCode;
  end
end
if myscreen.eatKeys
  disp(sprintf('(initScreen) Eating keys'));
  mglEatKeys(myscreen);
end
myscreen.keyCodes = [];
myscreen.keyTimes = [];

%init traces
numinit = 3000;
myscreen.events.n = 0;
myscreen.events.tracenum = zeros(1,numinit);
myscreen.events.data = zeros(1,numinit);
myscreen.events.ticknum = zeros(1,numinit);
myscreen.events.volnum = zeros(1,numinit);
myscreen.events.time = zeros(1,numinit);

%% a new struct indicates all trace names
% first stimtrace is reserved for acq pulses
myscreen.traceNames{1} = 'volume';
% second is for segment times
myscreen.traceNames{2} = 'segmentTime';
% third is for response times
myscreen.traceNames{3} = 'responseTime';
% fourth is for task phase
myscreen.traceNames{4} = 'taskPhase';
% fifth is for fix task
myscreen.traceNames{5} = 'fixationTask';
% sixth is for volumes that are ignored
myscreen.traceNames{6} = 'ignoredVolumes';
%% addTraces now provides a safe way to add traces
%% stimtrace is now a legacy variable which could be
%% deprecated in a future version. numTraces specifies
%% the number of traces and traceName the name
myscreen.numTraces = 7;
%% legacy if you use stimtace without addTraces, you will
%% get a free trace
myscreen.stimtrace = 7;

% save the beginning of time
myscreen.starttime = datestr(clock);
myscreen.time = mglGetSecs;

global gNumSaves;

% get the number of the next save file, so that
% we can put that into the eye tracker xdat
if (isempty(gNumSaves))
  tracknum = 1;
else
  tracknum = gNumSaves+1;
end

% get filename
thedate = [datestr(now,'yy') datestr(now,'mm') datestr(now,'dd')];
filename = sprintf('%s_stim%02i',thedate,tracknum);

% now create an output for the tracker
% with the tracknum shift up 8 bits
myscreen.fishcamp = bitshift(tracknum,1);

% set up text
mglTextSet('Helvetica',24,[1 1 1],0,0,0,0,0,0,0);

% set up eye calibration stuff
myscreen.eyecalib.prompt = 1;
%myscreen.eyecalib.x = [0 0 -5 0  0 0 5 0 0 0];
%myscreen.eyecalib.y = [0 0  0 0 -5 0 0 0 5 0];
myscreen.eyecalib.x = [0 0 -5 0  0 0 5 0 0 0 3.5 0 -3.5 0  3.5 0 -3.5 0];
myscreen.eyecalib.y = [0 0  0 0 -5 0 0 0 5 0 3.5 0 -3.5 0 -3.5 0  3.5 0];
myscreen.eyecalib.n = length(myscreen.eyecalib.x);
myscreen.eyecalib.size = [0.2 0.2];
myscreen.eyecalib.color = [1 1 0];
myscreen.eyecalib.waittime = 1;

% set up eye calibration stuff
% eyetracker is now used generically, it holds information about 
% any tracker that is initialized. when eyetracker.init is false
% the initEyeTracker function hasn't been run or was unsuccessful
if ~isfield(myscreen, 'eyetracker') || ~isfield(myscreen.eyetracker, 'init')
  myscreen.eyetracker.init = 0;
  myscreen.eyetracker.eyepos = [nan nan];
  myscreen.eyetracker.callback = [];
end

if ~isfield(myscreen.eyetracker,'collectEyeData')
  myscreen.eyetracker.collectEyeData = 1;
end

% init stimulus names if it does not exist already
if ~isfield(myscreen,'stimulusNames')
  myscreen.stimulusNames = {};
end

% default values
myscreen.userHitEsc = 0;
if isfield(myscreen,'simulateVerticalBlank') && myscreen.simulateVerticalBlank
  myscreen.flushMode = inf;
  disp(sprintf('(initScreen) Simulating vertical blank period by using mglFlushAndWait instead of mglFlush'));
else
  % check if we are using an ATI radeon 5xxx card
  if isfield(openGLinfo,'Renderer')
    if strncmp('ATI Radeon HD 5',openGLinfo.Renderer,15)
      disp(sprintf('(initScreen) !!! You are apparently using an ATI Radeon HD 5xxx series display card !!!'));
      disp(sprintf('             We have found that mglFlush may return immediately rather than waiting'));
      disp(sprintf('             for a vertical blank signal. You may want to set simulateVerticalBlank'));
      disp(sprintf('             in mglEditScreenParams. See here'));
      disp(sprintf('             http://gru.brain.riken.jp/doku.php/mgl/knownIssues#vertical_blanking_using_ati_videocards_radeon_hd'));
    end
  end
  myscreen.flushMode = 0;
end
myscreen.makeTraces = 0;
myscreen.numTasks = 0;

% if this is movieMode then set flushMode to simulate timing of flush
% without actually doing a flush (since the transparent openGL screen
% takes too long to flush
if isequal(mglGetParam('movieMode'),1)
  myscreen.flushMode = 2;
end

% get all pending keyboard events
mglGetKeyEvent([],1);

% hide mouse
if myscreen.hideCursor
  mglDisplayCursor(0);
else
  mglDisplayCursor(1);
end

% display hail string
disp(sprintf('%s End initScreen %s',repmat('=+',1,20),repmat('=+',1,20)));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% gets the name of the gamma calibration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function filename = getCalibFilename(myscreen,hostname)

% get the ouptut filename, first if there are dots in
% the name get the beginning, that way we don't
% have to deal with differences between
% computername.nework.edu and computername...
if ~isempty(strfind(hostname,'.'))
  hostname = strread(hostname,'%s','delimiter','.');
  hostname = hostname{1};
end

% get where the display directory is
displayDir = mglGetParam('displayDir');
if isempty(displayDir)
  % default if displayDir is not set to mgl/task/displays
  displayDir = sprintf('%s/displays',fileparts(which('initScreen')));
end
filenames = dir(fullfile(displayDir,sprintf('*%s*',hostname)));

% init variables
maxnum = 0;
filename = '';

% now look at the files we have and choose the one with the highest
% sequence number
for i = 1:length(filenames)
  filenum = strread(filenames(i).name,'%s','delimiter','_');
  filenum = str2num(filenum{1});
  if (filenum > maxnum)
    maxnum = filenum;
    [path name] = fileparts(filenames(i).name);
    filename = fullfile(displayDir,name);
  end
end

