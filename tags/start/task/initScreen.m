% initScreen.m
%
%      usage: initScreen(randstate)
%         by: justin gardner
%       date: 12/10/04
%    purpose: init screen parameters (using MGL)
%
function myscreen = initScreen(randstate)

% get globals
global myscreen;

% get globals
global MGL;

% get computer name
myscreen.computer = getHostName;
myscreen.tickcode = hex2dec('35');

% default gamma function uses min=0,max=0,exp=1.8 for all 3 colors
defaultMonitorGamma = 1.8;
defaultGammaFunction = [0 1 1/defaultMonitorGamma 0 1 1/defaultMonitorGamma 0 1 1/defaultMonitorGamma];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% database parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
screenParamsList = {'computerName','displayName','screenNumber',...
		    'screenWidth','screenHeight','displayDistance',...
		    'displaySize','imageWidth','imageHeight',...
		    'framesPerSecond','autoCloseScreen',...
		    'saveData','gammaFunction','gammaTablename'};
screenParams{1} = {'yoyodyne.cns.nyu.edu','',2,1280,1024,57,[31 23],[],[],60,1,0,defaultGammaFunction,''};
screenParams{end+1} = {'Stimulus.local','projector',2,1024,768,57,[31 23],[],[],60,0,50,defaultGammaFunction,''};
screenParams{end+1} = {'Stimulus.local','lcd',2,800,600,157.5,[43.2 32.5],[],[],60,0,50,[0 1 0.4790 0 1 0.4790 0 1 0.4790],''};
screenParams{end+1} = {'eigenstate','',0,1024,768,57,[31 23],[],[],60,1,0,defaultGammaFunction,''};
screenParams{end+1} = {'dhcp.bnf.brain.riken.jp','',0,1024,768,57,[31 23],[],[],60,1,0,defaultGammaFunction,''};
screenParams{end+1} = {'kirkwood','',1,1152,870,[],[],18,24,75,1,0,defaultGammaFunction,''};
screenParams{end+1} = {'alta','',[],1024,768,57,[31 23],[],[],60,1,0,defaultGammaFunction,''};
screenParams{end+1} = {'dsltop','',0,400,300,[],[],18,24,60,1,0,defaultGammaFunction,''};
screenParams{end+1} = {'whistler.cns.nyu.edu','',[],1280, 1024,[],[],18,24,60,1,0,defaultGammaFunction,''};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% find matching database parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
foundComputer = 0;
for pnum = 1:length(screenParams)
  if ~isempty(strfind(myscreen.computer,screenParams{pnum}{1}))
    if isempty(screenParams{pnum}{2}) || (isfield(myscreen,'displayname') && strcmp(myscreen.displayname,screenParams{pnum}{2}))
      foundComputer = 1;
      % if we find a match then set the parameters accordingly
      disp(sprintf('Monitor parameters for: %s',screenParams{pnum}{1}));
      % setup all parameters for the monitor (if the settings are
      % already set then do nothing
      for j = 3:length(screenParams{pnum})
	if ~isfield(myscreen,screenParamsList{j})
	  eval(sprintf('myscreen.%s = screenParams{pnum}{%i};',screenParamsList{j},j));
	end
      end
      if ~isempty(myscreen.displayDistance) & ~isempty(myscreen.displaySize)
	disp(sprintf('%i: %ix%i(pix) dist:%0.1f (cm) size:%0.1fx%0.1f (cm) %iHz save:%i autoclose:%i',myscreen.screenNumber,myscreen.screenWidth,myscreen.screenHeight,myscreen.displayDistance,myscreen.displaySize(1),myscreen.displaySize(2),myscreen.framesPerSecond,myscreen.saveData,myscreen.autoCloseScreen));
      else
	disp(sprintf('%i: %ix%i(pix) %0.1fx%0.1f(deg) %iHz save:%i autoclose:%i',myscreen.screenNumber,myscreen.screenWidth,myscreen.screenHeight,myscreen.imageWidth,myscreen.imageHeight,myscreen.framesPerSecond,myscreen.saveData,myscreen.autoCloseScreen));
      end
    end
  end
end

% check to make sure that we have found the computer in the table
if ~foundComputer
  disp(sprintf('UHOH: Could not find computer %s in initScreen',myscreen.computer));
end

%%%%%%%%%%%%%%%%%
% defaults if they have not been set
%%%%%%%%%%%%%%%%%
if ~isfield(myscreen,'autoCloseScreen'),myscreen.autoCloseScreen = 1;end
if ~isfield(myscreen,'screenNumber'),myscreen.screenNumber = [];end
if ~isfield(myscreen,'screenWidth'),myscreen.screenWidth = 1024;end
if ~isfield(myscreen,'screenHeight'),myscreen.screenHeight = 768;end
if ~isfield(myscreen,'framesPerSecond'),myscreen.framesPerSecond = 60;end
if ~isfield(myscreen,'saveData'),myscreen.saveData = -1;end

% switch to data directory if we are saving data
if isdir('~/data') && (myscreen.saveData>0)
  cd('~/data');
end

% compute the time per frame
myscreen.frametime = 1/myscreen.framesPerSecond;

% save rand number generator state
if ~exist('randstate','var')
  myscreen.randstate = rand('state');
else
  myscreen.randstate = randstate;
  rand('state',randstate);
end

% don't allow pause unless explicitly passed in
if ~isfield(myscreen,'allowpause')
  myscreen.allowpause = 0;
end

% init the MGL screen
if ~isempty(myscreen.screenNumber)
  % laptop setting
  mglOpen(myscreen.screenNumber, myscreen.screenWidth, myscreen.screenHeight);
else
  % otherwise open a default window
  mglOpen;
end

% use visual angle coordinates
% if monitor size is set, then this is a value
% in inches along the diagonal of the screen
if isempty(myscreen.displayDistance) | isempty(myscreen.displaySize)
  if ~isempty(myscreen.imageWidth) & ~isempty(myscreen.imageHeight)
    myscreen.displayDistance = 57;
    myscreen.displaySize(1) = tan(myscreen.imageWidth*pi/180)*myscreen.displayDistance;
    myscreen.displaySize(2) = tan(myscreen.imageHeight*pi/180)*myscreen.displayDistance;
  else
    disp('(initScreen) Could not find display parameters');
    return
  end
elseif ~isempty(myscreen.imageWidth) | ~isempty(myscreen.imageHeight)
  disp('(initScreen) over-riding imageWidth and imageHeight with displayDistance and Size');
end

mglVisualAngleCoordinates(myscreen.displayDistance,myscreen.displaySize);
myscreen.imageWidth = MGL.deviceWidth;
myscreen.imageHeight = MGL.deviceHeight;

% set up indexes appropriately
myscreen.black = 0;myscreen.white = 1;myscreen.gray = 0.5;
myscreen.blackIndex = 0;
myscreen.whiteIndex = 255;
myscreen.grayIndex = 128;
myscreen.inc = myscreen.whiteIndex - myscreen.grayIndex;

% but first go and check if we need to load a table
if isfield(myscreen,'gammaTablename') && ~isempty(myscreen.gammaTablename)
  % load the table 
  if isfile(myscreen.gammaTablename)
    load(myscreen.gammaTablename);
    % the table is a variable called gammaTable that has
    % a gamma table returned by mglGetGammaTable;
    mglSetGammaTable(gammaTable);
    myscreen.gammaTable = gammaTable;
  else
    disp(sprintf('UHOH: Could not find %s',myscreen.gammaTablename));
  end
else
  % display what the settings are
  disp(sprintf('Gamma: red [%0.2f %0.2f %0.2f] green [%0.2f %0.2f %0.2f] blue [%0.2f %0.2f %0.2f] (min max exp)',myscreen.gammaFunction(1),myscreen.gammaFunction(2),myscreen.gammaFunction(3),myscreen.gammaFunction(4),myscreen.gammaFunction(5),myscreen.gammaFunction(6),myscreen.gammaFunction(7),myscreen.gammaFunction(8),myscreen.gammaFunction(9)));
  % and then set it
  mglSetGammaTable(myscreen.gammaFunction);
end

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
      disp(sprintf('UHOH: Background color %s does not exist',myscreen.background));
      myscreen.background = myscreen.black;
    end
  end
else
  myscreen.background = myscreen.black;
end

% set background color  - MGL
mglClearScreen(myscreen.background);
mglFlush();
mglClearScreen(myscreen.background);
mglFlush();

disp(sprintf('imageWidth: %0.2f imageHeight: %0.2f',myscreen.imageWidth,myscreen.imageHeight));

% default paramaters for eye calibration
myscreen.eyecalib.n = 1;
myscreen.eyecalib.fixtime = 1.5;
myscreen.eyecalib.loc = {[5 0],[0 -5],[-5 0],[0 5]};
myscreen.eyecalib.shape = 'spot';
myscreen.eyecalib.size = [1 1]; % deg visual angle
myscreen.eyecalib.color = [255 255 0];
myscreen.eyecalib.refix = 1;
myscreen.eyecalib.prompt = 1;

% init number of ticks
myscreen.tick = 1;
myscreen.volnum = 0;
myscreen.intick = 0;
myscreen.fliptime = inf;
myscreen.dropcount = 0;
myscreen.checkForDroppedFrames = 1;

% keyboard stuff.
myscreen.HID.n = PsychHID('NumDevices');
myscreen.HID.devices = PsychHID('Devices');
% find the keyboard
myscreen.HID.keydev = 0;myscreen.HID.xkeysdev = 0;
for i = 1:myscreen.HID.n
  if (strcmp(myscreen.HID.devices(i).usageName,'Keyboard'))
    if (strfind(myscreen.HID.devices(i).product,'Apple Extended USB Keyboard'))
      myscreen.HID.keydev = i;
    end
    if (strcmp(myscreen.HID.devices(i).product,'Keyboard'))
      myscreen.HID.keydev = i;
    end
    if (strcmp(myscreen.HID.devices(i).product,'Apple Internal Keyboard / Trackpad'))
      myscreen.HID.keydev = i;
    end
    if (strfind(myscreen.HID.devices(i).product,'Xkeys Matrix'))
      myscreen.HID.xkeysdev = i;
    end
  end
end
if (myscreen.HID.keydev == 0)
  disp(sprintf('UHOH: Could not find keyboard\n'));
end
if (myscreen.HID.xkeysdev == 0)
  myscreen.HID.xkeysdev = myscreen.HID.keydev;
end

% get keyboard elements
myscreen.HID.keyelements = PsychHID('Elements',myscreen.HID.keydev);
% get the important code numbers
for i = 1:length(myscreen.HID.keyelements)
  switch (myscreen.HID.keyelements(i).usageValue)
    case { myscreen.tickcode }
      myscreen.HID.keys.tick = i;
    case { hex2dec('29') }
      myscreen.HID.keys.esc = i;
    case { hex2dec('2c') }
      myscreen.HID.keys.space = i;
    case { hex2dec('28') }
      myscreen.HID.keys.enter = i;
  end
end
% get keyboard elements
myscreen.HID.xkeyselements = PsychHID('Elements',myscreen.HID.xkeysdev);
% get the important code numbers
for i = 1:length(myscreen.HID.xkeyselements)
  switch (myscreen.HID.xkeyselements(i).usageValue)
    case { myscreen.tickcode }
      myscreen.HID.xkeys.tick = i;
    case { hex2dec('1e') }
      myscreen.HID.xkeys.nums(1)= i;
    case { hex2dec('1f') }
      myscreen.HID.xkeys.nums(2) = i;
    case { hex2dec('20') }
      myscreen.HID.xkeys.nums(3) = i;
    case { hex2dec('21') }
      myscreen.HID.xkeys.nums(4) = i;
    case { hex2dec('22') }
      myscreen.HID.xkeys.nums(5) = i;
    case { hex2dec('23') }
      myscreen.HID.xkeys.nums(6) = i;
    case { hex2dec('24') }
      myscreen.HID.xkeys.nums(7) = i;
    case { hex2dec('25') }
      myscreen.HID.xkeys.nums(8) = i;
    case { hex2dec('25') }
      myscreen.HID.xkeys.nums(9) = i;
    case { hex2dec('26') }
      myscreen.HID.xkeys.nums(10) = i;
  end
end

%init traces
numinit = 2000;
myscreen.events.n = 0;
myscreen.events.tracenum = zeros(1,numinit);
myscreen.events.data = zeros(1,numinit);
myscreen.events.ticknum = zeros(1,numinit);
myscreen.events.volnum = zeros(1,numinit);
myscreen.events.time = zeros(1,numinit);

myscreen.stimtrace = 5;

% save the beginning of time
myscreen.starttime = datestr(clock);
myscreen.time = GetSecs;

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

% make sure we don't have an existing file in the directory
% that would get overwritten
while(isfile(sprintf('%s.mat',filename)))
  fprintf(0,'UHOH: There is already a file %s...',filename);
  gNumSaves = gNumSaves+1;  tracknum = tracknum+1;
  thedate = [datestr(now,'yy') datestr(now,'mm') datestr(now,'dd')];
  filename = sprintf('%s_stim%02i',thedate,tracknum);
  disp(sprintf('Changing to %s',filename));
end

% now create an output for the tracker
% with the tracknum shift up 8 bits
myscreen.fishcamp = bitshift(tracknum,1);

% set up text
mglTextSet('Helvetica',24,[1 1 1],0,0,0,0,0,0,0);

% set up eye calibration stuff
myscreen.eyecalib.x = [0 0 -5 0  0 0 5 0 0 0];
myscreen.eyecalib.y = [0 0 0 0 -5 0 0 0 5 0];
myscreen.eyecalib.n = length(myscreen.eyecalib.x);
myscreen.eyecalib.size = [0.2 0.2];
myscreen.eyecalib.color = [1 1 0];
myscreen.eyecalib.waittime = 1;

mydisp(sprintf('-----------------------------\n'));
