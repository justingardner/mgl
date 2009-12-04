% mglEditScreenParams.m
%
%        $Id:$ 
%      usage: mglEditScreenParams()
%         by: justin gardner
%       date: 07/17/09
%    purpose: 
%
function retval = mglEditScreenParams()

% check arguments
if ~any(nargin == [0])
  help mglEditScreenParams
  return
end

% check for mrParamsDialog
if ~exist('mrParamsDialog')
  disp(sprintf('(mglEditScreenParams) You must have mrTools in your path to run the GUI for this function.'));
  disp(sprintf('(mglEditScreenParams) You can download the mrTools utilties by doing the following from a shell:\n\nsvn checkout http://cbi.nyu.edu/svn/mrToosl/trunk/mrUtilities/MatlabUtilities mrToolsUtilities\n\nand then add the path in matlab:\n\naddpath(''mrToolsUtilities'')'));
  return
end

% get the screenParams
screenParams = mglGetScreenParams;
if isempty(screenParams)
  screenParams{1} = defaultScreenParams;
end

% get the hostname
hostname = mglGetHostName;

% get the name of the valid computers
hostnameList = {};displayNames = {};computerNum = 1;
for i = 1:length(screenParams)
  hostnameList{end+1} = screenParams{i}.computerName;
  displayNames{end+1} = screenParams{i}.displayName;
  if isequal(screenParams{i}.computerName,mglGetHostName)
    computerNum = i;
  end
end


% set up params for choosing which computer to edit
paramsInfo{1} = {'computerNum',computerNum,sprintf('minmax=[1 %i]', length(hostnameList)),'incdec=[-1 1]'};
paramsInfo{end+1} = {'computerName',hostnameList,'type=string','group=computerNum','editable=0'};
paramsInfo{end+1} = {'displayName',displayNames,'type=string','group=computerNum','editable=0'};
paramsInfo{end+1} = {'addDisplay',0,'type=pushButton','buttonString=Add Display','callback',@addDisplay,'passParams=1','Add a new display to the list'};
paramsInfo{end+1} = {'deleteDisplay',0,'type=pushButton','buttonString=Delete Display','callback',@deleteDisplay,'passParams=1','Delete this display from the screenParams'};
paramsInfo{end+1} = {'revertDisplay','','type=pushButton','buttonString=Revert Display','callback',@revertDisplay,'passParams=1','Revert parameters to default parameters for this screen'};

% bring up dialog box
params = mrParamsDialog(paramsInfo, sprintf('Choose computer/display (you are now on: %s)',hostname));
if isempty(params),return,end

% add this display if asked for
if isequal(params.addDisplay,'add')
  screenParams{end+1} = defaultScreenParams;
end

% delete computers list
if isequal(params.deleteDisplay,'delete')
  for i = 1:length(params.computerName)
    screenParams{i}.computerName = params.computerName{i};
  end
end

% revert displays
revertDisplay = str2num(params.revertDisplay);
for i = 1:length(revertDisplay)
  screenParams{revertDisplay(i)} = defaultScreenParams(screenParams{revertDisplay(i)});
end

% get parameters for chosen computer
computerNum = params.computerNum;
thisScreenParams = screenParams{computerNum};

% get some parameters for the screen
useCustomScreenSettings = 1;
screenNumber = thisScreenParams.screenNumber;
if isempty(screenNumber),screenNumber = 1;useCustomScreenSettings=0;end
screenWidth = thisScreenParams.screenWidth;
if isempty(screenWidth),screenWidth = 800;end
screenHeight = thisScreenParams.screenHeight;
if isempty(screenHeight),screenHeight = 600;end
framesPerSecond = thisScreenParams.framesPerSecond;
if isempty(framesPerSecond),framesPerSecond = 60;end

% see if the calibration options should be enabled or not.
if strcmp(thisScreenParams.calibType,'Specify particular calibration')
  enableCalibFilename = 'enable=1';
else
  enableCalibFilename = 'enable=0';
end
% see if the calibration options should be enabled or not.
if strcmp(thisScreenParams.calibType,'Specify gamma')
  enableMonitorGamma = 'enable=1';
else
  enableMonitorGamma = 'enable=0';
end

%set up the paramsInfo
paramsInfo = {};
paramsInfo{end+1} = {'computerName',thisScreenParams.computerName,'The name of the computer for these screen parameters'};
paramsInfo{end+1} = {'displayName',thisScreenParams.displayName,'The display name for these settings. This can be left blank if there is only one display on this computer for which you will be using mgl. If instead there are multiple displays, then you will need screen parameters for each display, and you should name them appropriately. You then call initScreen(displayName) to get the settings for the correct display'};
paramsInfo{end+1} = {'useCustomScreenSettings',useCustomScreenSettings,'type=checkbox','If you leave this unchecked then mgl will open up with default screen settings (i.e. the display will be chosen as the last display in the list and the screenWidth and ScreenHeight will be whatever the current settings are. This is sometimes useful for when you are on a development computer -- rather than the one you are running experiments on'};
paramsInfo{end+1} = {'screenNumber',screenNumber,'type=numeric','minmax=[0 inf]','incdec=[-1 1]','The screen number to use on this display. 0 is for a windowed contex.','round=1','contingent=useCustomScreenSettings'};
paramsInfo{end+1} = {'screenWidth',screenWidth,'type=numeric','minmax=[0 inf]','incdec=[-1 1]','round=1','contingent=useCustomScreenSettings','The width in pixels of the screen'};
paramsInfo{end+1} = {'screenHeight',screenHeight,'type=numeric','minmax=[0 inf]','incdec=[-1 1]','round=1','contingent=useCustomScreenSettings','The height in pixels of the screen'};
paramsInfo{end+1} = {'framesPerSecond',framesPerSecond,'type=numeric','minmax=[0 inf]','incdec=[-1 1]','round=1','contingent=useCustomScreenSettings','Refresh rate of monitor'};
paramsInfo{end+1} = {'displayDistance',thisScreenParams.displayDistance,'type=numeric','minmax=[0 inf]','incdec=[-1 1]','Distance in cm to the display from the eyes. This is used for figuring out how many pixels correspond to a degree of visual angle'};
paramsInfo{end+1} = {'displaySize',thisScreenParams.displaySize,'type=array','minmax=[0 inf]','Width and height of display in cm. This is used for figuring out how many pixels correspond to a degree of visual angle'};
paramsInfo{end+1} = {'autoCloseScreen',thisScreenParams.autoCloseScreen,'type=checkbox','Check if you want endScreen to automatically do mglClose at the end of your experiment.'};
paramsInfo{end+1} = {'flipHorizontal',thisScreenParams.flipHV(1),'type=checkbox','Click if you want initScreen to set the coordinates so that the screen is horizontally flipped. This may be useful if you are viewing the screen through mirrors'};
paramsInfo{end+1} = {'flipVertical',thisScreenParams.flipHV(2),'type=checkbox','Click if you want initScreen to set the coordinates so that the screen is vertically flipped. This may be useful if you are viewing the screen through mirrors'};
paramsInfo{end+1} = {'hideCursor',thisScreenParams.hideCursor,'type=checkbox','Click if you want initScreen to hide the mouse for this display.'};
paramsInfo{end+1} = {'saveData',thisScreenParams.saveData,'type=numeric','incdec=[-1 1]','minmax=[-1 inf]','Sets whether you want to save an stim file which stores all the parameters of your experiment. You will probably want to save this file for real experiments, but not when you are just testing your program. So on the desktop computer set it to 0. This can be 1 to always save a data file, 0 not to save data file,n>1 saves a data file only if greater than n number of volumes have been collected)'};
paramsInfo{end+1} = {'calibType',putOnTopOfList(thisScreenParams.calibType,{'None','Find latest calibration','Specify particular calibration','Gamma 1.8','Gamma 2.2','Specify gamma'}),'Choose how you want to calibrate the monitor. This is for gamma correction of the monitor. Find latest calibration works with calibration files stored by moncalib, and will look for the latest calibration file in the directory task/displays that matches this computer and display name. If you want to specify a particular file then select that option and specify the calibration file in the field below. If you don''t have a calibration file created by moncalib then you might try to correct for a standard gamma value like 1.8 (mac computers) or 2.2 (PC computers). Or a gamma value of your choosing','callback',@calibTypeCallback,'passParams=1'};
paramsInfo{end+1} = {'calibFilename',thisScreenParams.calibFilename,'Specify the calibration filename. This field is only used if you use Specify particular calibration from above',enableCalibFilename};
paramsInfo{end+1} = {'monitorGamma',thisScreenParams.monitorGamma,'type=numeric','Specify the monitor gamma. This is only used if you set Specify Gamma above',enableMonitorGamma};
paramsInfo{end+1} = {'diginUse',thisScreenParams.digin.use,'type=checkbox','Click this if you want to use the National Instruments cards digital io for detecting volume acquisitions and subject responses. If you use this, the keyboard will still work (i.e. you can still press backtick and response numbers. This uses the function mglDigIO -- and you will need to make sure that you have compiled mgl/util/mglPrivateDigIO.c'};
paramsInfo{end+1} = {'diginPortNum',thisScreenParams.digin.portNum,'type=numeric','This is the port that should be used for reading. For NI USB-6501 devices it can be one of 0, 1 or 2','incdec=[-1 1]','minmax=[0 inf]','contingent=diginUse','round=1'};
paramsInfo{end+1} = {'diginAcqLine',thisScreenParams.digin.acqLine,'type=numeric','This is the line from which to read the acquisition pulse (i.e. the one that occurs every volume','incdec=[-1 1]','minmax=[0 7]','contingent=diginUse','round=1'};
paramsInfo{end+1} = {'diginAcqType',num2str(thisScreenParams.digin.acqType),'type=string','This is how to interpert the digial signals for the acquisition. If you want to trigger when the signal goes low then set this to 0. If you want trigger when the signal goes high, set this to 1. If you want to trigger when the signal changes state (i.e. either low or high), set to [0 1]','contingent=diginUse'};
paramsInfo{end+1} = {'diginResponseLine',num2str(thisScreenParams.digin.responseLine),'type=string','This is the lines from which to read the subject responses. If you want to specify line 1 and line 3 for subject response 1 and 2, you would enter [1 3], for instance. You can have up to 7 different lines for subject responses.','minmax=[0 7]','contingent=diginUse','round=1'};
paramsInfo{end+1} = {'diginResponseType',num2str(thisScreenParams.digin.responseType),'type=string','This is how to interpert the digial signals for the responses. If you want to trigger when the signal goes low then set this to 0. If you want trigger when the signal goes high, set this to 1. If you want to trigger when the signal changes state (i.e. either low or high), set to [0 1]','contingent=diginUse'};
paramsInfo{end+1} = {'testDigin',0,'type=pushbutton','buttonString=Test digin','callback',@testDigin,'passParams=1','Click to test the digin settings'};
paramsInfo{end+1} = {'testSettings',0,'type=pushbutton','buttonString=Test screen params','callback',@testSettings,'passParams=1','Click to test the monitor settings'};

% display parameter choosing dialog
if ~isequal(thisScreenParams.computerName,'DELETE')
  params = mrParamsDialog(paramsInfo,'Set screen parameters');
  if isempty(params),return,end
  screenParams{computerNum} = params2screenParams(params);
end

% delete scans
deleteScreenParams = screenParams;
screenParams = {};
for i = 1:length(deleteScreenParams)
  if ~isequal(deleteScreenParams{i}.computerName,'DELETE');
    screenParams{end+1} = deleteScreenParams{i};
  end
end

% save
mglSetScreenParams(screenParams);

%%%%%%%%%%%%%%%%%%%%%%%%%
%%   testOpenDisplay   %%
%%%%%%%%%%%%%%%%%%%%%%%%%
function msc = testOpenDisplay(params)

msc = [];
disp(sprintf('(mglEditScreenParams:testSettings) Testing settings for %s:%s',params.computerName,params.displayName));

% test to see if the screenNumber is valid
if params.screenNumber > length(mglDescribeDisplays)
  msgbox(sprintf('(mglEditScreenParams) Screen number %i is out of range for %s: [0 %i]',params.screenNumber,params.computerName,length(mglDescribeDisplays)));
  return
end

% check if the screen number is 0 since for that we can't change the dimensions
if params.screenNumber == 0
  global mglEditScreenParamsScreenWidth;
  global mglEditScreenParamsScreenHeight;
  if ~isempty(mglEditScreenParamsScreenWidth) || ~isempty(mglEditScreenParamsScreenHeight) 
    if (~isequal(mglEditScreenParamsScreenWidth,params.screenWidth) || ~isequal(mglEditScreenParamsScreenHeight,params.screenHeight))
      msgbox(sprintf('(mglEditScreenParams) For windowed contexts, you cannot change the width/height of the window after you have opened it once, so this screen will not accurately reflect the current parameters. So, rather than [%i %i], this window will display as [%i %i]. To try the new parameters, you will need to restart matlab. ',params.screenWidth,params.screenHeight,mglEditScreenParamsScreenWidth,mglEditScreenParamsScreenWidth,params.screenHeight));
    end
  else
    mglEditScreenParamsScreenWidth = params.screenWidth;
    mglEditScreenParamsScreenHeight = params.screenHeight;
  end
end

% convert the params returned by the dialog into
% screen params
msc.screenParams{1} = params2screenParams(params);
msc.computer = params.computerName;
msc.displayName = params.displayName;
msc.allowpause = 0;

% now call initScreen with these parameters
msc = initScreen(msc);

%%%%%%%%%%%%%%%%%%%%%%
%%   TestSettings   %%
%%%%%%%%%%%%%%%%%%%%%%
function val = testSettings(params)

val = 0;

msc = testOpenDisplay(params);
if isempty(msc),return,end

% display some text on the screen
mglTextSet('Helvetica',32,[1 1 1 1],0,0,0,0,0,0,0);
mglTextDraw(sprintf('Testing settings for %s:%s',params.computerName,params.displayName),[0 -5]);

% wait for five seconds
if thisWaitSecs(15,params)<=0,endScreen(msc);return,end

% show the monitor dims
mglMonitorDims(-1);
if thisWaitSecs(15,params)<=0,endScreen(msc);return,end

% show fine gratings
mglTestGamma(-1);
% show info about gamma
calibType = sprintf('calibType: ''%s''',msc.calibType);
switch msc.calibType
 case {'Specify particular calibration','Find latest calibration'}
    if isempty(msc.calibFilename)
      calibType = sprintf('%s (No calibration found)',calibType);
    else
      calibType = sprintf('%s calibFilename: %s',calibType,msc.calibFilename);
    end
  case {'Gamma 1.8','Gamma 2.2','Specify gamma'}
    calibType = sprintf('%s monitor gamma: %0.2f',calibType,msc.monitorGamma);
end
mglTextDraw(calibType,[0 -6]);
if thisWaitSecs(15,params)<=0,endScreen(msc);return,end

testTickScreen(30,params,msc);

% close screen and return
msc.autoCloseScreen = 1;
endScreen(msc);

%%%%%%%%%%%%%%%%%%%%%%
%%   testTickScreen %%
%%%%%%%%%%%%%%%%%%%%%%
function retval = testTickScreen(waitTime,params,msc)

startTime = mglGetSecs;
lastButtons = [];
while (mglGetSecs(startTime)<waitTime) && ~msc.userHitEsc

  % clear screen
  mglClearScreen(0);

  % draw some text
  mglTextDraw(sprintf('volnum: %i',msc.volnum),[0 -3]);
  if msc.useDigIO
    digioStr = sprintf('portNum: %i acqLine: %i acqType: %s responseLine: %s responseType: %s',msc.digin.portNum,msc.digin.acqLine,num2str(msc.digin.acqType),num2str(msc.digin.responseLine),num2str(msc.digin.responseType));
    mglTextDraw(digioStr,[0 -6]);
  else
    mglTextDraw(sprintf('Digital I/O is disabled'),[0 -6]);
  end
  if ~isempty(lastButtons)
    mglTextDraw(sprintf('Last button press: %s at %0.2f',num2str(lastButtons),lastTime),[0 0]);
  end
  mglTextDraw(sprintf('Hit ESC to quit.',params.computerName,params.displayName),[0 3.5]);

  % tick screen
  msc = tickScreen(msc,[]);

  % look for next button press
  buttons = find(ismember(msc.keyboard.nums,msc.keyCodes));
  if ~isempty(buttons)
    lastButtons = buttons;
    lastTime = msc.keyTimes(1)-startTime;
  end
end

%%%%%%%%%%%%%%%%%%%
%%   testDigin   %%
%%%%%%%%%%%%%%%%%%%
function retval = testDigin(params)

retval = 0;

% how long to wait for
waitTime = 60;

% open screen for textVersion
screenParams = params2screenParams(params);
if ~screenParams.digin.use
  disp(sprintf('(mglEditScreenParams:testDigin) Digin is not being used'));
  return
end

% get start time
startTime = mglGetSecs;

% start digin (set digout port to just be whatever digin is not)
if mglDigIO('init',screenParams.digin.portNum,mod(screenParams.digin.portNum+1,3)) == 0
  disp(sprintf('(mglEditScreenParams:testDigin) Failed to initialize digital IO port'));
  return
end

disp(sprintf('(mglEditScreenParams:testDigin) Testing settings for %s:%s',params.computerName,params.displayName));
disp(sprintf('(mglEditScreenParams:testDigin) PortNum: %i acqLine: %i acqType: %s responseLine: %s responseType: %s',screenParams.digin.portNum,screenParams.digin.acqLine,num2str(screenParams.digin.acqType),num2str(screenParams.digin.responseLine),num2str(screenParams.digin.responseType)));
disp(sprintf('(mglEditScreenParams:testDigin) To quit hit ESC'));

% init keyboard listener and clear events
mglListener('init');
  
% get any pending events
[keyCode when charCode] = mglGetKeyEvent(0,1);

volNum = 0;volTime = startTime;nums = [];times = [];
while ((mglGetSecs-startTime) < waitTime)
  [keyCode when charCode] = mglGetKeyEvent(0,1);
  if ~isempty(charCode)
    % check for return or space or ESC
    if any(keyCode == 37) || any(charCode == ' ') || any(keyCode == 54)
      retval = 1;
      disp(sprintf('(mglEditScreenParams:testDigin) End digin test'));
      mglDigIO('quit');
      mglListener('quit');
      return
    end
  end
  % get status of digital ports
  digin = mglDigIO('digin');
  if ~isempty(digin)
    % see if there is an acq pulse
    acqPulse = find(screenParams.digin.acqLine == digin.line);
    if ~isempty(acqPulse)
      acqPulse = find(ismember(digin.type(acqPulse),screenParams.digin.acqType));
      if ~isempty(acqPulse)
	volTime = digin.when(acqPulse(1));
	volNum = volNum+1;
	disp(sprintf('Volume number: %i Time of last volume: %0.3f',volNum,volTime-startTime));
      end
    end
    % see if one of the response lines has been set 
    [responsePulse whichResponse] = ismember(digin.line,screenParams.digin.responseLine);
    responsePulse = ismember(digin.type(responsePulse),screenParams.digin.responseType);
    nums =  whichResponse(responsePulse);
    times = digin.when(responsePulse);
    if ~isempty(nums)
      disp(sprintf('Response: %s (time: %s)',num2str(nums),num2str(times-startTime)));
    end
  end
end

retval = 1;
disp(sprintf('(mglEditScreenParams:testDigin) End digin test'));
mglDigIO('quit');
mglListener('quit');
return

%%%%%%%%%%%%%%%%%%%%%%
%%   thisWaitSecs   %%
%%%%%%%%%%%%%%%%%%%%%%
function retval = thisWaitSecs(waitTime,params,drawText)

if nargin < 3, drawText = 1;end

% tell the user what they can do
if drawText
  mglTextDraw(sprintf('Hit return to continue or ESC to quit.',params.computerName,params.displayName),[0 3.5]);
  mglFlush();
end
% get start time
startTime = mglGetSecs;

% now wait in loop here, listening to see if the user hits esc (abort) or return/space (continue)
while ((mglGetSecs-startTime) < waitTime)
  [keyCode when charCode] = mglGetKeyEvent(0,1);
  if ~isempty(charCode)
    disp(charCode);
    % check for return or space
    if any(keyCode == 37) || any(charCode == ' ')
      retval = 1;
      return
    end
    % check for ESC
    if any(keyCode == 54)
      retval = -1;
      return
    end
  end
end
retval = 0;
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%   params2screenParams   %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function screenParams = params2screenParams(params)

% get host/display name
screenParams.computerName = params.computerName;
screenParams.displayName = params.displayName;

% get screen settings
if params.useCustomScreenSettings
  screenParams.screenNumber = params.screenNumber;
  screenParams.screenWidth = params.screenWidth;
  screenParams.screenHeight = params.screenHeight;
  screenParams.framesPerSecond = params.framesPerSecond;
else
  screenParams.screenNumber = [];
  screenParams.screenWidth = [];
  screenParams.screenHeight = [];
  screenParams.framesPerSecond = 60;
end

% get display settings
screenParams.displayDistance = params.displayDistance;
screenParams.displaySize = params.displaySize;
screenParams.flipHV = [params.flipHorizontal params.flipVertical];
screenParams.autoCloseScreen = params.autoCloseScreen;
screenParams.hideCursor = params.hideCursor;

% get file saving settings
screenParams.saveData = params.saveData;

% calibration info
screenParams.calibType = params.calibType;
screenParams.calibFilename = params.calibFilename;
screenParams.monitorGamma = params.monitorGamma;

% digio
screenParams.digin.use = params.diginUse;
screenParams.digin.portNum = params.diginPortNum;
screenParams.digin.acqLine = params.diginAcqLine;
if ~isempty(params.diginAcqType)
  screenParams.digin.acqType = str2num(params.diginAcqType);
else
  screenParams.digin.acqType = [];
end
if ~isempty(params.diginResponseLine) 
  screenParams.digin.responseLine = str2num(params.diginResponseLine);
else
  screenParams.digin.responseLine = [];
end
if ~isempty(params.diginResponseType)
  screenParams.digin.responseType = str2num(params.diginResponseType);
else
  screenParams.digin.responseType = [];
end  


%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%   calibTypeCallback   %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
function calibTypeCallback(params)

% this is used to gray out the calibFilename and monitorGamma settins depending
% on what option the user selects for calibType
if strcmp(params.calibType,'Specify particular calibration')
  mrParamsEnable('calibFilename',1);
else
  mrParamsEnable('calibFilename',0);
end
if strcmp(params.calibType,'Specify gamma')
  mrParamsEnable('monitorGamma',1);
else
  mrParamsEnable('monitorGamma',0);
end

%%%%%%%%%%%%%%%%%%%%
%%   addDisplay   %%
%%%%%%%%%%%%%%%%%%%%
function retval = addDisplay(params)

retval = 'add';
if ~isequal(params.addDisplay,'add')
  params.computerName = {params.computerName{:},mglGetHostName};
  params.displayName = {params.displayName{:},''};
  params.computerNum = length(params.computerName);
  mrParamsSet(params);
end

%%%%%%%%%%%%%%%%%%%%%%%
%%   deleteDisplay   %%
%%%%%%%%%%%%%%%%%%%%%%%
function retval = deleteDisplay(params)

retval = 'delete';
params.computerName{params.computerNum} = 'DELETE';
params.displayName{params.computerNum} = 'DELETE';
mrParamsSet(params);

%%%%%%%%%%%%%%%%%%%%%%%
%%   revertDisplay   %%
%%%%%%%%%%%%%%%%%%%%%%%
function retval = revertDisplay(params)

retval = sprintf('%s %i',params.revertDisplay,params.computerNum);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%   defaultScreenParams   %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function screenParams = defaultScreenParams(screenParams)

% get host/display name
if nargin < 1
  screenParams.computerName = mglGetHostName;
  screenParams.displayName = '';
end

displays = mglDescribeDisplays;

% get screen settings
params.useCustomScreenSettings = 0;
screenParams.screenNumber = length(displays);
screenParams.screenWidth = displays(end).screenSizePixel(1);
screenParams.screenHeight = displays(end).screenSizePixel(2);
screenParams.framesPerSecond = displays(end).refreshRate;

% get display settings
screenParams.displayDistance = 57;
screenParams.displaySize = [50.8 38.1];
screenParams.flipHV = [0 0];
screenParams.hideCursor = 0;
screenParams.autoCloseScreen = 1;

% get file saving settings
screenParams.saveData = 0;

% calibration info
screenParams.calibType = 'None';
screenParams.calibFilename = '';
screenParams.monitorGamma = [];

% digio
screenParams.digin.use = 0;
screenParams.digin.portNum = 2;
screenParams.digin.acqLine = 0;
screenParams.digin.acqType = 1;
screenParams.digin.responseLine = [1 2 3 4 5 6 7];
screenParams.digin.responseType = 1;
