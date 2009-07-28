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
  myscreen.displayname = displayname;
end

% set version number
myscreen.ver = 2.0;

% get computer name
if ~isfield(myscreen,'computer')
  myscreen.computer = mglGetHostName;
end

% default monitor gamma (used when there is no calibration file)
defaultMonitorGamma = 1.8;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% database parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[screenParams screenParamsFilename] = mglGetScreenParams;

% check for passed in screenParams
if isfield(myscreen,'screenParams')
  screenParams = cat(2,myscreen.screenParams,screenParams);
  screenParamsFilename = '';
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% convert screenParams to new format and validate that the field names are correct
% and properly captialized
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% list of possible screenParams
screenParamsList = {'computerName','displayName','screenNumber',...
		    'screenWidth','screenHeight','displayDistance',...
		    'displaySize','framesPerSecond','autoCloseScreen',...
		    'saveData','calibType','monitorGamma','calibFilename','flipHV','digin'};

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
  thisFieldNames = fieldnames(screenParams{i});
  for j = 1:length(thisFieldNames)
    % match the field in the screenParamsList (do case insensitive)
    whichField = find(strcmp(lower(thisFieldNames{j}),lower(screenParamsList)));
    % if no match, report an error, but continue on
    if isempty(whichField)
      disp(sprintf('(initScreen) UHOH! Unrecogonized field %s in screenParams{%i}',thisFieldNames{j},i));
    else
      % now remove it from screenParams and then add it back -- this is simply
      % to insure that the capitilization is correct
      fieldVal = screenParams{i}.(thisFieldNames{j});
      screenParams{i} = rmfield(screenParams{i},thisFieldNames{j});
      screenParams{i}.(screenParamsList{whichField}) = fieldVal;
    end
    % check for displayName
    if ~isfield(screenParams{i},'displayName') screenParams{i}.displayName = '';end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% find matching database parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
foundComputer = 0;
for pnum = 1:length(screenParams)
  if ~isempty(strfind(myscreen.computer,screenParams{pnum}.computerName))
    % if no displayName is asked for or no displayname is set in the screenParams
    % then only accept the computer if we haven't already found it
    if (foundComputer == 0) && (isempty(screenParams{pnum}.displayName) || ~isfield(myscreen,'displayname'))
      foundComputer = pnum;
    % check for matching displayname
    elseif isfield(myscreen,'displayname') && isstr(myscreen.displayname) && strcmp(myscreen.displayname,screenParams{pnum}.displayName)
      foundComputer = pnum;
    % check for matching display number
    elseif isfield(myscreen,'displayname') && isnumeric(myscreen.displayname) && isequal(myscreen.displayname,screenParams{pnum}.screenNumber)
      foundComputer = pnum;
    end
  end
end

% check to make sure that we have found the computer in the table
if foundComputer
  % display the match
  if ~isempty(screenParams{foundComputer}.displayName)
    disp(sprintf('(initScreen) Monitor parameters for: %s displayName: %s',screenParams{foundComputer}.computerName,screenParams{foundComputer}.displayName));
  else
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
if ~isfield(myscreen,'displayName'),myscreen.displayName = [];end
if ~isfield(myscreen,'screenNumber'),myscreen.screenNumber = [];end
if ~isfield(myscreen,'screenWidth'),myscreen.screenWidth = [];end
if ~isfield(myscreen,'screenHeight'),myscreen.screenHeight = [];end
if ~isfield(myscreen,'displayDistance'),myscreen.displayDistance = 57;end
if ~isfield(myscreen,'displaySize'),myscreen.displaySize = [31 23];end
if ~isfield(myscreen,'framesPerSecond'),myscreen.framesPerSecond = 60;end
if ~isfield(myscreen,'autoCloseScreen'),myscreen.autoCloseScreen = 1;end
if ~isfield(myscreen,'saveData'),myscreen.saveData = -1;end
if ~isfield(myscreen,'flipHV'),myscreen.flipHV = [0 0];end
if ~isfield(myscreen,'digin'),myscreen.digin = [];end
if ~isfield(myscreen,'displayName'),myscreen.displayName = [];end
myscreen.pwd = pwd;

%%%%%%%%%%%%%%%%%
% print display settings
%%%%%%%%%%%%%%%%%
if foundComputer
  % display the settings
  if ~isempty(myscreen.displayDistance) & ~isempty(myscreen.displaySize)
    disp(sprintf('(initScreen) %i: %ix%i(pix) dist:%0.1f (cm) size:%0.1fx%0.1f (cm) %iHz save:%i autoclose:%i flipHV:[%i %i]',myscreen.screenNumber,myscreen.screenWidth,myscreen.screenHeight,myscreen.displayDistance,myscreen.displaySize(1),myscreen.displaySize(2),myscreen.framesPerSecond,myscreen.saveData,myscreen.autoCloseScreen,myscreen.flipHV(1),myscreen.flipHV(2)));
  end
else
  if ~isempty(screenParamsFilename)
    disp(sprintf('(initScreen) Could not find computer %s in screenParams file %s\n',myscreen.computer,screenParamsFilename));
  else
    disp(sprintf('(initScreen) Could not find computer %s in myscreen.screenParams\n',myscreen.computer));
  end
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

% compute the time per frame
myscreen.frametime = 1/myscreen.framesPerSecond;

% get matlab version
matlabVersion = version;
myscreen.matlab.version = matlabVersion;
[matlabMajorVersion matlabVersion] = strtok(matlabVersion,'.');
myscreen.matlab.majorVersion = str2num(matlabMajorVersion);
myscreen.matlab.minorVersion = str2num(strtok(matlabVersion,'.'));

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

% init the mgl screen
if ~isempty(myscreen.screenNumber)
  % setting with specified screenNumber
  mglOpen(myscreen.screenNumber, myscreen.screenWidth, myscreen.screenHeight, myscreen.framesPerSecond);
else
  % otherwise open a default window
  mglOpen;
  myscreen.screenWidth = mglGetParam('screenWidth');
  myscreen.screenHeight = mglGetParam('screenHeight');
end

% use visual angle coordinates
% if monitor size is set, then this is a value
% in inches along the diagonal of the screen
if isempty(myscreen.displayDistance) | isempty(myscreen.displaySize)
  disp('(initScreen) Could not find display parameters');
  return
end

mglVisualAngleCoordinates(myscreen.displayDistance,myscreen.displaySize);
myscreen.imageWidth = mglGetParam('deviceWidth');
myscreen.imageHeight = mglGetParam('deviceHeight');

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
      if ~isfile(sprintf('%s.mat',calibFilename))
	calibFilename = getCalibFilename(myscreen,calibFilename);
      end
    else
      calibFilename = getCalibFilename(myscreen,myscreen.computer);
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
myscreen.keyboard.backtick = mglCharToKeycode({'`'});
if ~isfield(myscreen.keyboard,'nums')
  myscreen.keyboard.nums = mglCharToKeycode({'1' '2' '3' '4' '5' '6' '7' '8' '9' '0'});
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
%% addTraces now provides a safe way to add traces
%% stimtrace is now a legacy variable which could be
%% deprecated in a future version. numTraces specifies
%% the number of traces and traceName the name
myscreen.numTraces = 5;
%% legacy if you use stimtace without addTraces, you will
%% get a free trace
myscreen.stimtrace = 6;

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

% init stimulus names if it does not exist already
if ~isfield(myscreen,'stimulusNames')
  myscreen.stimulusNames = {};
end

% default values
myscreen.userHitEsc = 0;
myscreen.flushMode = 0;
myscreen.makeTraces = 0;
myscreen.numTasks = 0;

% initialize digital port
myscreen.useDigIO = 0;
if isfield(myscreen,'digin') 
  if ~isempty(myscreen.digin) && isfield(myscreen.digin,'use') && isequal(myscreen.digin.use,1)
    % we are using digio
    myscreen.useDigIO = myscreen.digin.use;
    % try to open the port
    if isempty(mglDigIO('init',myscreen.digin.portNum))
      disp(sprintf('(initScreen) Failed to open Digitial IO ports. Only using keyboard backticks now!'));
      myscreen.useDigIO = 0;
    else
      % grab any pending events
      mglDigIO('digin');
    end
  end
end

% get all pending keyboard events
mglGetKeyEvent([],1);

%%%%%%%%%%%%%%%%%%%%%%%%%%
% check if it is a file
%%%%%%%%%%%%%%%%%%%%%%%%%%
function retval = isfile(filename)

if (nargin ~= 1)
  help isfile;
  return
end

% open file
fid = fopen(filename,'r');

% check to see if there was an error
if (fid ~= -1)
  fclose(fid);
  retval = 1;
else
  retval = 0;
end

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

% now look in the current directory for displays
filenames = dir(fullfile(myscreen.pwd,sprintf('displays/*%s*',hostname)));

% if we haven't found any files in current directory then look in task directory
if length(filenames) == 0
  defaultdir = sprintf('%s/displays/*%s*',fileparts(which('initScreen')),hostname);
  filenames = dir(defaultdir);
end

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
    filename = sprintf('%s/task/displays/%s',fileparts(fileparts(which('initScreen'))),name);
  end
end

