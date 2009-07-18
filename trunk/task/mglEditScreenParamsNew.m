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

% get parameters for chosen computer
thisScreenParams = screenParams{params.computerNum};

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
paramsInfo{end+1} = {'testSettings',0,'type=pushbutton','buttonString=Test settings','callback',@testSettings,'passParams=1'};

params = mrParamsDialog(paramsInfo,'Set screen parameters');
if isempty(params),return,end

keyboard

%%%%%%%%%%%%%%%%%%%%%%
%%   TestSettings   %%
%%%%%%%%%%%%%%%%%%%%%%
function val = testSettings(params)

val = 0;

disp(sprintf('(mglEditScreenParams:testSettings) Testing settings for %s:%s',params.hostname,params.displayName));

% convert the params returned by the dialog into
% screen params
msc.screenParams{1} = params2screenParams(params);
msc.computer = params.hostname;
msc.displayName = params.displayName;

% now call initScreen with these parameters
msc = initScreen(msc);

% wait a second and then close
mglWaitSecs(1);
endScreen(msc);


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


