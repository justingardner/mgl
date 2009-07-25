% mglEditScreenParams.m
%
%        $Id:$ 
%      usage: mglEditScreenParams()
%         by: justin gardner
%       date: 07/17/09
%    purpose: 
%
function retval = mglEditScreenParamsNew()

% check arguments
if ~any(nargin == [0])
  help mglEditScreenParams
  return
end

% get the screenParams
screenParams = mglGetScreenParams(0);
if isempty(screenParams),return,end

% get the hostname
hostname = mglGetHostName;

% get the name of the valid computers
hostnameList = {};displayNames = {};
for i = 1:length(screenParams)
  hostnameList{end+1} = screenParams{i}.computerName;
  displayNames{end+1} = screenParams{i}.displayName;
end

% set up params for choosing which computer to edit
paramsInfo{1} = {'computerNum',1,sprintf('minmax=[1 %i]', length(hostnameList)),'incdec=[-1 1]'};
paramsInfo{end+1} = {'hostname',hostnameList,'type=string','group=computerNum','editable=0'};
paramsInfo{end+1} = {'displayName',displayNames,'type=string','group=computerNum','editable=0'};

% bring up dialog box
params = mrParamsDialog(paramsInfo, sprintf('Choose computer/display (you are now on: %s)',hostname));
if isempty(params),return,end
computerNum = params.computerNum;

% get parameters for chosen computer
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
paramsInfo{end+1} = {'hostname',thisScreenParams.computerName,'editable=0','The name of the computer for these screen parameters'};
paramsInfo{end+1} = {'displayName',thisScreenParams.displayName,'editable=0','The display name for these settings. This can be left blank if there is only one display on this computer for which you will be using mgl. If instead there are multiple displays, then you will need screen parameters for each display, and you should name them appropriately. You then call initScreen(displayName) to get the settings for the correct display'};
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
paramsInfo{end+1} = {'saveData',thisScreenParams.saveData,'type=numeric','incdec=[-1 1]','minmax=[-1 inf]','Sets whether you want to save an stim file which stores all the parameters of your experiment. You will probably want to save this file for real experiments, but not when you are just testing your program. So on the desktop computer set it to 0. This can be 1 to always save a data file, 0 not to save data file,n>1 saves a data file only if greater than n number of volumes have been collected)'};
paramsInfo{end+1} = {'calibType',putOnTopOfList(thisScreenParams.calibType,{'None','Find latest calibration','Specify particular calibration','Gamma 1.8','Gamma 2.2','Specify gamma'}),'Choose how you want to calibrate the monitor. This is for gamma correction of the monitor. Find latest calibration works with calibration files stored by moncalib, and will look for the latest calibration file in the directory task/displays that matches this computer and display name. If you want to specify a particular file then select that option and specify the calibration file in the field below. If you don''t have a calibration file created by moncalib then you might try to correct for a standard gamma value like 1.8 (mac computers) or 2.2 (PC computers). Or a gamma value of your choosing','callback',@calibTypeCallback,'passParams=1'};
paramsInfo{end+1} = {'calibFilename',thisScreenParams.calibFilename,'Specify the calibration filename. This field is only used if you use Specify particular calibration from above',enableCalibFilename};
paramsInfo{end+1} = {'monitorGamma',thisScreenParams.monitorGamma,'type=numeric','Specify the monitor gamma. This is only used if you set Specify Gamma above',enableMonitorGamma};
paramsInfo{end+1} = {'testSettings',0,'type=pushbutton','buttonString=Test settings','callback',@testSettings,'passParams=1','Click to test the monitor settings'};

% display parameter choosing dialog
params = mrParamsDialog(paramsInfo,'Set screen parameters');
if isempty(params),return,end

% convert the params into screenparams and save
screenParams{computerNum} = params2screenParams(params);
mglSetScreenParams(screenParams);


%%%%%%%%%%%%%%%%%%%%%%
%%   TestSettings   %%
%%%%%%%%%%%%%%%%%%%%%%
function val = testSettings(params)

val = 0;

disp(sprintf('(mglEditScreenParams:testSettings) Testing settings for %s:%s',params.hostname,params.displayName));

% test to see if the screenNumber is valid
if params.screenNumber > length(mglDescribeDisplays)
  msgbox(sprintf('(mglEditScreenParams) Screen number %i is out of range for %s: [0 %i]',params.screenNumber,params.hostname,length(mglDescribeDisplays)));
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
msc.computer = params.hostname;
msc.displayName = params.displayName;

% now call initScreen with these parameters
msc = initScreen(msc);

% display some text on the screen
mglTextSet('Helvetica',32,[1 1 1 1],0,0,0,0,0,0,0);
mglTextDraw(sprintf('Testing settings for %s:%s',params.hostname,params.displayName),[0 -5]);

% wait for five seconds
if thisWaitSecs(15,params)<=0,endScreen(msc);return,end

% show the monitor dims
mglMonitorDims(-1);
if thisWaitSecs(15,params)<=0,endScreen(msc);return,end

% show fine gratings
mglTestGamma(-1);
if thisWaitSecs(15,params)<=0,endScreen(msc);return,end

% close screen and return
endScreen(msc);

%%%%%%%%%%%%%%%%%%%%%%
%%   thisWaitSecs   %%
%%%%%%%%%%%%%%%%%%%%%%
function retval = thisWaitSecs(waitTime,params)

% tell the user what they can do
mglTextDraw(sprintf('Hit return to continue or ESC to quit.',params.hostname,params.displayName),[0 3.5]);
mglFlush();

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
screenParams.computerName = params.hostname;
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

% get file saving settings
screenParams.saveData = params.saveData;

% calibration info
screenParams.calibType = params.calibType;
screenParams.calibFilename = params.calibFilename;
screenParams.monitorGamma = params.monitorGamma;

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

