% mglTestScreenParams.m
%
%      usage: mglTestScreenParams(<msc>)
%         by: justin gardner
%       date: 06/29/16
%    purpose: Taken out of mglEditScreenParams so that it can be run separately.
%      usage: mglTestScreenParams (opens default screen)
%             mglTestScreenParams('screenName') opens up a specific screen
%
function retval = mglTestScreenParams(msc)

% check arguments
if ~any(nargin == [0 1])
  help mglTestScreenParams
  return
end

% if no arguments then just open up a default screen
if nargin < 1
  msc = initScreen;
elseif isstr(msc)
  % if input argument is a name then open up that screen
  msc = initScreen(msc);
end

% check for bad open
if isempty(msc)
  disp(sprintf('(mglTestScreenParams) Unable to open a valid screen'));
  return
end

% default to value of 0
val = 0;
msc.autoCloseScreen = 1;

% display some text on the screen
mglTextSet('Helvetica',32,[1 1 1 1],0,0,0,0,0,0,0);
mglTextDraw(sprintf('Testing settings for %s:%s',msc.computer,msc.displayName),[0 -5]);

% wait for fifteen seconds maximum and then quit (just in case the screen doesn't open properly)
if thisWaitSecs(15,msc)<=0,endScreen(msc);return,end

% from now on just continue to run until uer hits ESC
waitTime = inf;

% show the monitor dims
mglMonitorDims(-1);
% draw bounding box
imageWidth = msc.imageWidth;
imageHeight = msc.imageHeight;
deviceWidth = mglGetParam('deviceWidth');
deviceHeight = mglGetParam('deviceHeight');
% right hand side
mglPolygon([imageWidth/2 imageWidth/2 deviceWidth deviceWidth imageWidth/2],[-deviceHeight deviceHeight deviceHeight -deviceHeight -deviceHeight],[0 0 0]);
% left hand side
mglPolygon([-imageWidth/2 -imageWidth/2 -deviceWidth -deviceWidth -imageWidth/2],[-deviceHeight deviceHeight deviceHeight -deviceHeight -deviceHeight],[0 0 0]);
% top
mglPolygon([-deviceWidth deviceWidth deviceWidth -deviceWidth -deviceWidth],[imageHeight/2 imageHeight/2 deviceHeight deviceHeight imageHeight/2],[0 0 0]);
% bottom 
mglPolygon([-deviceWidth deviceWidth deviceWidth -deviceWidth -deviceWidth],[-imageHeight/2 -imageHeight/2 -deviceHeight -deviceHeight -imageHeight/2],[0 0 0]);

[~,t] = system('hostname');
if strfind(t,'oban')
    degOffset = atan(10/msc.displayDistance)*180/pi;
    mglLines2(-degOffset,-30,-degOffset,30,1,[1 0 0]);
    mglLines2(degOffset,-30,degOffset,30,1,[1 0 0]);
end
if thisWaitSecs(waitTime,msc)<=0,endScreen(msc);return,end

% show fine gratings
mglTestGamma(-1);
% show info about gamma
calibType = sprintf('calibType: ''%s''',msc.calibType);
calibType2 = '';
switch msc.calibType
 case {'Specify particular calibration','Find latest calibration'}
    if isempty(msc.calibFilename)
      calibType2 = sprintf('No calibration found');
    else
      calibType2 = sprintf('calibFilename: %s',msc.calibFilename);
    end
  case {'Gamma 1.8','Gamma 2.2','Specify gamma'}
    calibType2 = sprintf('monitor gamma: %0.2f',msc.monitorGamma);
end
imageHeight = mglGetParam('deviceHeight');
mglTextDraw(calibType,[0 -imageHeight/8]);
mglTextDraw(calibType2,[0 -2*imageHeight/8]);
if thisWaitSecs(waitTime,msc)<=0,endScreen(msc);return,end

testTickScreen(waitTime,msc);

% close screen and return
endScreen(msc);

%%%%%%%%%%%%%%%%%%%%%%
%%   testTickScreen %%
%%%%%%%%%%%%%%%%%%%%%%
function retval = testTickScreen(waitTime,msc)

startTime = mglGetSecs;
lastButtons = [];

% get the backtick char
backtickChar = mglKeycodeToChar(msc.keyboard.backtick);
backtickChar = backtickChar{1};

imageHeight = mglGetParam('deviceHeight');

while (mglGetSecs(startTime)<waitTime) && ~msc.userHitEsc

  % clear screen
  mglClearScreen(0);

  % draw some text
  mglTextDraw(sprintf('Volume number (%s): %i',backtickChar,msc.volnum),[0 -3]);
  if msc.useDigIO
    digioStr = sprintf('portNum: %i acqLine: %i acqType: %s responseLine: %s responseType: %s',msc.digin.portNum,msc.digin.acqLine,num2str(msc.digin.acqType),num2str(msc.digin.responseLine),num2str(msc.digin.responseType));
    mglTextDraw(digioStr,[0 -imageHeight/8]);
  else
    mglTextDraw(sprintf('Digital I/O is disabled'),[0 -imageHeight/8]);
  end
  if ~isempty(lastButtons)
    mglTextDraw(sprintf('Last button press: %s (%s) at %0.2f',num2str(lastButtons),paramsNum2str(msc.responseKeys{lastButtons(end)}),lastTime),[0 0]);
  end
  mglTextDraw(sprintf('Hit ESC to quit.'),[0 3.5]);

  % tick screen
  msc = tickScreen(msc,[]);

  % look for next button press
  buttons = find(ismember(msc.keyboard.nums,msc.keyCodes));
  if ~isempty(buttons)
    lastButtons = buttons;
    lastTime = msc.keyTimes(1)-startTime;
  end
end

%%%%%%%%%%%%%%%%%%%%%%
%%   thisWaitSecs   %%
%%%%%%%%%%%%%%%%%%%%%%
function retval = thisWaitSecs(waitTime,msc,drawText)

if nargin < 3, drawText = 1;end

% tell the user what they can do
if drawText
  mglTextDraw(sprintf('Hit return to continue or ESC to quit.',msc.computer,msc.displayName),[0 3.5]);
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

%%%%%%%%%%%%%%%%%%%%%%%
%%   paramsNum2str   %%
%%%%%%%%%%%%%%%%%%%%%%%
function c = paramsNum2str(c)

if isnumeric(c)
  c = sprintf('k%i',c);
end

