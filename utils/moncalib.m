% moncalib.m
%
%      usage: To run a calibration:
%             calib = moncalib; 
%
%             To display a previously run calibration
%             moncalib(calib);
%
%             Options that you can use:
%             calib = moncalib('numRepeats=4','stepsize=1/256',...
%               numRepeats = number of repeats of each measurement to make when measuring luminance
%               stepsize = step size to measure luminance values in. Use 1/256 to check every value in an 8 bit display
%               initWaitTime = number of seconds to wait at beginning for prep time
%               screenNumber = The screen number to test, default is [].
%               spectrum = Set to 1 to measure spectrum for basic colors, default to 0
%               gamma = Set to 1 to measure the monitor gamma, default is 1
%               gammaEachChannel = Set to 1 to measure the monitor gamma for each color channel separately, default is 0
%               exponent = Set to 1 to fit the gamma with an exponential, default is 0
%               tableTest = Test the inverted table for linearization, default = 1
%               bitTest = Test for 10 bit gamma, default = 0
%               bitTestBits = Change number of bits to test gamma table for, default=10
%               bitTestNumRepeats = Number of repeated measurements to take, default = 16
%               bitTestN = Number of increments in luminance to test, default=12
%               bitTestBase = Base luminance to test from, default = 0.8
%               reset = Set to 1 to reset settings, otherwise this will use the same communication settings each time you run
%               verbose = Set to 1 for minimal messages, 2 for messages about each measurement, 0 for quiet. Default=1
%               serialPortFun = Changes which function to use for serial communications. This defaults to 
%                               comm, which is distributed with mgl. You can set to 'comm:SerialComm' to use
%                               the SerialComm function provided with PsychToolbox. Or you can set to 'serial'
%                               for using the Matlab serial port object - but note that this still has bugs (see code
%                               comments below in parseArgs function...
%               commTest = Set to 1 if you just want to test communication with the photometer
%
%             Old calling style:
%               calib = moncalib(screenNumber,stepsize,numRepeats,testTable,bitTest,initWaitTime)
%               stepsize is how finely you want to measure luminance changes (value < 1.0) (default is 1/256)
%               numRepeats is the number of repeats you want to make of the measurements (default is 4)
%         by: justin gardner & jonas larsson
%       date: 10/02/06
%    purpose: routine to do monitor calibration
%             uses PhotoResearch PR650, Minolta or Topcon  photometer/colorimeter
% 
%             To test the serial port connection to your device, run like:
%
%             moncalib('commTest=1');
%
%             This works by using the serial port interface
%             to the PR650 and the comm library from the
%             mathworks site:
%
%http://www.mathworks.com/matlabcentral/fileexchange/loadFile.do?objectId=4952&objectType=file
%
%             There is no 64 bit support for the comm library. 
%
%             If you want to rewrite this function to use a different
%             serial port interface function, then you just need
%             to change the functions initSerialPort, closeSerialPort
%             readSerialPort and writeSerialPort
%
%             If you want to change this function to use a different
%             photometer then you need to add specific
%             photometerInit and photometerMeasure (and optionally photometerSpectrumMeasure) for
%             your photometer 
%
%             If you pass it in a calib matlab structure that it has
%             saved then it will display the calibration. It will
%             also continue with a calibration that has only partially
%             been finished (like if you forced a quit in the middle)
%             The function saves the calibration file after each step
%
%             If you set testTable to 1 (default is 1) it will also run
%             a test to see if you have actually succeeded in linearizing the table
% 
%             If you set bitTest to 1 (default 0) it will run a test to see
%             if your display card supports 10 bit gamma tables (the graph on
%             the right should look like a linear rise in luminance as we
%             step in units of 1/1024 the output. If it is 8 bit, it will look like
%             a step function.
%
%             initWaitTime can be set so that you have however many seconds you set
%             it to to leave the room before the calibration starts. (default 0)
%
function calib = moncalib(varargin)

% parse arguments
[calib todo] = parseArgs(nargin,varargin);
if isempty(calib),return,end

% test photometer
if todo.photometerTest
  photometerTest;
  return
end

if todo.setupCalib
  % setup the calibration / i.e. ask user about
  % whether to use serial port or manual, open
  % up serial port and initialize photometer
  % and get save names, etc.
  [calib portNum photometerNum todo] = setupCalib(calib,todo);
  if photometerNum == -1,return,end
  if portNum == 0,return,end
end

% display settings
if todo.dispSettings
  dispSettings(calib,todo);
end

% initial wait time.
if todo.initWaitTime > 0
  disp(sprintf('(moncalib) Starting in %i seconds',todo.initWaitTime));
  drawnow;
  mglWaitSecs(todo.initWaitTime);
end

% collect spectrum for various colors
if todo.measureSpectrum
  % measure the spectrum for each color value
  calib = measureSpectrum(calib,portNum,photometerNum,{[1 0 0],[0 1 0],[0 0 1],[0 0 0],[1 1 1],[1 1 0],[1 0 1],[0 1 1]});
  % save the file
  saveCalib(calib);
end
% display spectrum
if todo.displaySpectrum,displaySpectrum(calib);end

% measure the gamma output of each color channel separately
if todo.measureGammaEachChannel
  % run the calibration
  calib = measureGammaEachChannel(calib,portNum,photometerNum);
  % save the file
  saveCalib(calib);
end
if todo.displayGammaEachChannel,displayGammaEachChannel(calib),end

% measure the gamma output of the monitor and build inverse table for linearizing output
if todo.measureGamma
  % run the calibration
  calib = measureGamma(calib,portNum,photometerNum);
  % save the file
  saveCalib(calib);
end

% fit an exponent
if todo.fitExponent,calib = fitGammaExponent(calib);end

% display the gamma
if todo.displayGamma,displayGamma(calib,todo);end

% display the exponent
if todo.displayExponent,displayExponent(calib);end


if todo.testExponent
  % test the exponent fit
  calib = testExponent(calib,portNum,photometerNum);
  % save the file
  saveCalib(calib);
end

% display the testExponent
if todo.displayTestExponent,displayTestExponent(calib);end
  
if todo.testTable
  % test the inverse table
  calib = testTable(calib,portNum,photometerNum);
  % save the file
  saveCalib(calib);
end

% display the test of the inverted table
if todo.displayTestTable,displayTestTable(calib);end

if todo.bitTest
  % run the bit test
  calib = bitTest(calib,portNum,photometerNum);
  % save the file
  saveCalib(calib);
end

% display the bit test
if todo.displayBitTest,displayBitTest(calib);end

if todo.setupCalib
  % finish up
  % close the serial port, it may be better to just leave it
  % open, so that it you don't have to restart the photometer each time
  %if ~isempty(portNum)
  %  closeSerialPort(portNum);
  %mglCend

  % close the screen
  mglClose;

  % set end time
  calib.finishedAt = datestr(now);

  % save the file
  saveCalib(calib);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function that sets the gamma table to all the values in val
% and checks the luminance
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function retval = measureOutput(portNum,photometerNum,outputValues,numRepeats,setGamma)

global verbose;

% default to setting gamma values, not clor values
if ~exist('setGamma','var'),setGamma=1;,end

% clear and flush screen
mglClearScreen(0);mglFlush;

measuredLuminanceSte = [];measuredLuminance = [];
measuredXSte = [];measuredX = [];
measuredYSte = [];measuredY = [];
if verbose == 1,disppercent(-inf,'(moncalib) Measuring luminance');end
for val = outputValues
  % set the gamma table so that we display this luminance value
  if setGamma
    if (verbose>1),disp(sprintf('Setting gamma table output to %f',val));end
    mglSetGammaTable(val*ones(256,1));
  else
    if (verbose>1),disp(sprintf('Setting screen output to %f',val));end
    mglClearScreen(val);mglFlush;
  end
  % wait a bit to make sure it has changed
  mglWaitSecs(0.1);
  % measure the luminace
  for repeatNum = 1:numRepeats
    gotMeasurement = 0;badMeasurements = 0;
    while ~gotMeasurement
      % get the measurement from the photometer 
      [thisMeasuredLuminance(repeatNum) thisMeasuredX(repeatNum) thisMeasuredY(repeatNum)] = photometerMeasure(portNum,photometerNum);
      % check to see if it is a bad measurement
      if isnan(thisMeasuredLuminance(repeatNum))
	% if it is and, we have already tried three times, then give up
	badMeasurements = badMeasurements+1;
	if (badMeasurements > 3)
	  disp(sprintf('UHOH: Failed to get measurement 3 times, settint to 0'));
	  thisMeasuredLuminance(repeatNum) = 0;
	  gotMeasurement = 1;
	end
	% otherwise we whave the measurement, so keep going
      else
	gotMeasurement = 1;
      end
    end
  end
  % now take median over all repeats of measurement
  measuredLuminance(end+1) = median(thisMeasuredLuminance(1:numRepeats));
  measuredLuminanceSte(end+1) = std(thisMeasuredLuminance(1:numRepeats))/sqrt(numRepeats);
  measuredX(end+1) = median(thisMeasuredX(1:numRepeats));
  measuredXSte(end+1) = std(thisMeasuredX(1:numRepeats))/sqrt(numRepeats);
  measuredY(end+1) = median(thisMeasuredY(1:numRepeats));
  measuredYSte(end+1) = std(thisMeasuredY(1:numRepeats))/sqrt(numRepeats);
  if (verbose>1),disp(sprintf('Luminance = %0.4f',measuredLuminance(end)));end
  if verbose == 1,disppercent((find(val==outputValues)-1)/length(outputValues));end
end
if (verbose == 1),disppercent(inf);end

% pack it up
retval.outputValues = outputValues;
retval.luminance = measuredLuminance;
retval.x = measuredX;
retval.y = measuredY;
retval.luminanceSte = measuredLuminanceSte;
retval.xSte = measuredXSte;
retval.ySte = measuredYSte;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function that sets the gamma table to all the values in val
% and checks the luminance, this version is similar to above
% but allows for color input triplets rather than a single 
% luminance value for outputValues
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function retval = measureOutputColor(portNum,photometerNum,outputValues,numRepeats,setGamma)

global verbose;

% default to setting gamma values, not clor values
if ~exist('setGamma','var'),setGamma=1;,end

% clear and flush screen
mglClearScreen(0);mglFlush;

measuredLuminanceSte = [];measuredLuminance = [];
measuredXSte = [];measuredX = [];
measuredYSte = [];measuredY = [];
if verbose == 1,disppercent(-inf,'(moncalib:measureOutputColor) Measuring luminance');end
for i = 1:length(outputValues)
  val = outputValues{i};
  % set the gamma table so that we display this luminance value
  if setGamma
    if (verbose>1),disp(sprintf('(moncalib:measureOutputColor) Setting gamma table output to %s',num2str(val)));end
    mglSetGammaTable(repmat(val(:),1,256)');
  else
    if (verbose>1),disp(sprintf('(moncalib:measureOutputColor) Setting screen output to %s',num2str(val)));end
    mglClearScreen(val);mglFlush;
  end
  % wait a bit to make sure it has changed
  mglWaitSecs(0.1);
  % measure the luminace
  for repeatNum = 1:numRepeats
    gotMeasurement = 0;badMeasurements = 0;
    while ~gotMeasurement
      % get the measurement from the photometer
      [thisMeasuredLuminance(repeatNum) thisMeasuredX(repeatNum) thisMeasuredY(repeatNum)] = photometerMeasure(portNum,photometerNum);
      % check to see if it is a bad measurement
      if isnan(thisMeasuredLuminance(repeatNum))
	% if it is and, we have already tried three times, then give up
	badMeasurements = badMeasurements+1;
	if (badMeasurements > 3)
	  disp(sprintf('(moncalib:measureOutputColor) UHOH: Failed to get measurement 3 times, settint to 0'));
	  thisMeasuredLuminance(repeatNum) = 0;
	  gotMeasurement = 1;
	end
	% otherwise we whave the measurement, so keep going
      else
	gotMeasurement = 1;
      end
    end
  end
  % now take median over all repeats of measurement
  measuredLuminance(end+1) = median(thisMeasuredLuminance(1:numRepeats));
  measuredLuminanceSte(end+1) = std(thisMeasuredLuminance(1:numRepeats))/sqrt(numRepeats);
  measuredX(end+1) = median(thisMeasuredX(1:numRepeats));
  measuredXSte(end+1) = std(thisMeasuredX(1:numRepeats))/sqrt(numRepeats);
  measuredY(end+1) = median(thisMeasuredY(1:numRepeats));
  measuredYSte(end+1) = std(thisMeasuredY(1:numRepeats))/sqrt(numRepeats);
  if (verbose>1),disp(sprintf('(moncalib:measureOutputColor) Luminance = %0.4f',measuredLuminance(end)));end
  if verbose == 1,disppercent(i/length(outputValues));end
end
if (verbose == 1),disppercent(inf);end

% pack it up
retval.outputValues = outputValues;
retval.luminance = measuredLuminance;
retval.x = measuredX;
retval.y = measuredY;
retval.luminanceSte = measuredLuminanceSte;
retval.xSte = measuredXSte;
retval.ySte = measuredYSte;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% display a figure that shows measurements
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function dispLuminanceFigure(table,color,normalize)

if nargin < 3,normalize = 0;end
if iscell(table.outputValues)
  % for color values choose max output value
  for i = 1:length(table.outputValues)
    outputValues(i) = max(table.outputValues{i});
  end
else
  outputValues = table.outputValues;
end
  
% normalize to 1
if normalize
  luminance = (table.luminance-min(table.luminance))/(max(table.luminance)-min(table.luminance));
else
  luminance = table.luminance;
end

if ~exist('color','var'),color = 'k';end
if ~all(table.luminanceSte==0)
  errorbar(outputValues,luminance,table.luminanceSte,sprintf('%so-',color));
else
  plot(outputValues,luminance,sprintf('%so-',color));
end
xlabel('output value');

if normalize
  ylabel('Normalized luminance');
else
  ylabel('luminance (cd/m^-2)');
end

drawnow;

%%%%%%%%%%%%%%%%%%%%%%%%
%%   photometerInit   %%
%%%%%%%%%%%%%%%%%%%%%%%%
function retval = photometerInit(portNum,photometerNum)


switch photometerNum
 case {1}
  retval = photometerInitPR650(portNum);
 case {2,3}
  retval = photometerInitMinolta(portNum);
 case {4}
  retval = photometerInitTopcon(portNum);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%   photometerMeasure   %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [luminance x y] = photometerMeasure(portNum,photometerNum)

% if doing manual input
if isempty(portNum)
  luminance = getnum('Enter luminance measurement: ');
  x = 0;
  y = 0;
  return
end

% otherwise choose the right photometer
switch photometerNum
 case {1}
  [luminance x y] = photometerMeasurePR650(portNum);
 case {2,3}
  [luminance x y] = photometerMeasureMinolta(portNum,photometerNum);
 case {4}
  [luminance x y] = photometerMeasureTopcon(portNum);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%   photometerSpectrumMeasure   %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [wavelength radiance] = photometerSpectrumMeasure(portNum,photometerNum)

wavelength = [];
radiance = [];

% if doing manual input
if isempty(portNum)
  disp(sprintf('(photometerSpectrumMeasure) Spectrum measurement disabled in auto mode'));
  return
end

% otherwise choose the right photometer
switch photometerNum
 case {1}
  [wavelength radiance] = photometerSpectrumMeasurePR650(portNum);
 case {2,3}
  disp(sprintf('(photometerSpectrumMeasure) Spectrum measurement not available for Minolta'));
 case {4}
  [wavelength radiance] = photometerSpectrumMeasureTopcon(portNum);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% init the pr650 photometer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function retval = photometerInitPR650(portNum)

clc
retval = -1;
response = 0;
while(response == 0)

  input(sprintf('Please turn on the PR650 and within 5 seconds press enter: '));
  % send a command, any command will do. We set the backlight on
  writeSerialPort(portNum,sprintf('B3\n'));
  % tell the user what to expect
  disp(sprintf('\nThe backlight on the back panel of the PR650'))
  disp(sprintf('should be on and it should now say:\n'));
  disp(sprintf('=================='));
  disp(sprintf('PR-650 REMOTE MODE'));
  disp(sprintf('(CTRL) s/w V1.19'));
  disp(sprintf('\nCMD B'));
  disp(sprintf('==================\n'));
  response = askuser('Does it look like this');
  if (response == 0)
    disp(sprintf('Either you have failed to send a command within 5 seconds'));
    disp(sprintf('or you have the wrong serial port number. If you think'));
    disp(sprintf('you have the wrong serial port number, quit and start over'));
    disp(sprintf('otherwise you can power cycle the PR650 and try again'));
    tryAgain = askuser(sprintf('Try again'));
    if tryAgain == 0,return,end
  end
end

% turn off the backlight
writeSerialPort(portNum,sprintf('B0\n'));

% set up measurement parameters
% integrate over how many ms. 0 is adaptive, otherwise 10-6000 is
% number of ms
integrationTime = 0;
% number of measurement averages to use from 01-99
averageCount = 1;
% the last 1 here specifies measuring in unis of cd*m-2 or lux
% set to 0 for footLamberts/footcandles
writeSerialPort(portNum,sprintf('S,,,,,%i,%i,1\n',integrationTime,averageCount));

retval = 1;
clc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% measure luminance with the PR650 photometer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [luminance x y] = photometerMeasurePR650(portNum)

% retrieve any info that is pending from the photometer
readSerialPort(portNum,1024);
% now take a measurement and read
writeSerialPort(portNum,sprintf('M1\n'));
writeSerialPort(portNum,sprintf('D1\n'));

% read the masurement
len = length('QQ,U,Y.YYYYEsee,.xxxx,.yyyy');
str = '';readstr = 'start';
while ~isempty(readstr) || (length(str)<len)
  readstr = readSerialPort(portNum,256);
  str = [str readstr];
  mglWaitSecs(0.1);
end

% read the string
[quality units Y x y] = strread(str,'%d%d%n%n%n','delimiter',',');

errorNum = [0 1 3 4 5 6 7 8 10 12 13 14 16 17 18 19 20 21 29 30];
errorMsg = {'Measurement okay','No EOS signal at start of measurement',...
	    'No start signal','No EOS signal to start integration time',...
	    'DMA failure','No EOS signal after Changed to SYNC mode',...
	    'Unable to sync to light source','Sync lost during measurement',...
	    'Weak light signal','Unspecified hardware malfunction',...
	    'Software error','No sample in L*u*v* or L*a*b* calculation',...
	    'Adaptive integration taking too much time finding correct integration time indicating possible variable light source.',...
	    'Main battery is low','Low light level','Light level too high (overload)',...
	    'No sync signal','RAM error','Corrupted data','Noisy signal'};

% the last one should be the measurement
i = length(quality);
thisMessageNum = find(quality(i)==errorNum);
if isempty(thisMessageNum)
  thisMessageNum = -1;
  thisMessage = '';
else
  thisMessage = errorMsg{thisMessageNum(1)};
end
global verbose
if ((verbose>1) || thisMessageNum),disp(sprintf('%s Luminance=%f cd/m^-2 (1931 CIE x)=%f (1931 CIE y)=%f',thisMessage,Y(i),x(i),y(i)));end

if quality(i) ~= 0
  luminance = nan;
  x = nan;
  y = nan;
else
  luminance = Y(i);
  x = x(i);
  y = y(i);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% init the minolta photometer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function retval = photometerInitMinolta(portNum)

clc
retval = -1;
response = 0;
while(response == 0)

   disp(sprintf('Please turn on the LS100 and press the white F key at the same time.'));
   disp(sprintf('\nThe LCD panel on the LS100 should end with a "C"\n'));
   response = askuser('Is there a "C" at the end');
   if (response == 0)
       disp(sprintf('You probably need to turn off the LS100 and try again'));
       tryAgain = askuser(sprintf('Try again'));
       if tryAgain == 0,return,end
   end
end

retval = 1;
clc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% measure luminance with the minolta photometer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [luminance x y] = photometerMeasureMinolta(portNum,photometerNum)

% retrieve any info that is pending from the photometer
readSerialPort(portNum,1024);
% now take a measurement and read
writeSerialPort(portNum,['MES',13,10]);  % send a measure signal to LS100

% read the masurement
str = '';readstr = 'start';
while isempty(str) || ~isempty(readstr) 
   readstr = readSerialPort(portNum,16);
   str = [str readstr];
   mglWaitSecs(0.2);
end


errorNum = {'00', '01', '11', '10', '19', '20', '30'};
errorMsg = {'Offending command','Setting error',...
   'Memory value error','Measuring range over',...
   'Display range over','EEPROM error','Battery exhausted'};

if strcmp(str(1:2),'OK')
   thisMessage = '';
   [mstatus,data]=strread(str,'%s%f','delimiter',' ');
   mstatus=char(mstatus);
   % this is only valid for the L100, I think. -j. 
   if photometerNum == 2
     if ~strcmp(mstatus(6:7),'Cc')
       disp('(moncalib) Make sure the measurement unit is cd/m2');
     end
   end
elseif strcmp(str(1:2),'ER')
   thisMessage = errorMsg{find(strcmp(errorNum,str(3:4)))};
   data=nan;
else
  % check to see if we have high bits set - this is some problam with 
  % the pluggable serial adaptor
  if any(bitand(double(str),128)')
    disp(sprintf('(moncalib) It appears that the high bit (8) is set in the message comming back from the serial device. This should never be the case since we are doing 7 bit communication. This is probably a driver error whcih we have noticed on the Plugable driver. We were never able to get that USB/Serial adaptor to work with Minolta, so consider purchasing a Keyspan USA-19HS USB/Serial device instead.'));
  end
  thisMessage = sprintf('(moncalib) Unknown error: %s',str);
  data = nan;
end

% return data different for LS100 or CS100A
if photometerNum == 2
  %LS100 does not measure color
  luminance = data;
  x=0;y=0;
else
  luminance = data(1);
  if length(data)>=3
    x = data(2);
    y = data(3);
  else
    x = 0;
    y = 0;
  end
end

global verbose
if verbose, disp(sprintf('%s Luminance=%f cd/m^-2 ',thisMessage, luminance));end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% init the topcon photometer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function retval = photometerInitTopcon(portNum)

retval = -1;

clc
disp(sprintf('First make sure that the topcon has the correct serial port settings, by pushing the [MODE] key for about 2 seconds to enter the function mode. Then push the [ENTER] key four times to set the RS-232C Parameters. The settings should be Baud rate: 9600, Length=8, parity=NONE, Stop bit=1. Use the [CHANGE],[ROTATION] & [ENTER] keys accordingly.'));
disp(sprintf('\nThen make sure that the data communication method is set to Normal Type. From the function mode (see above) hit [ENTER] five times. It should say:\n\n* CS900 ON/OFF *\n* Normal Type\n')); 
response = 0;
while ~response
  response = askuser('Are you ready');
end
disp(sprintf('If the program hangs after this, you may want to try again after rebooting the computer'));

% retrieve any info that is pending from the photometer
response = readLineSerialPort(portNum);
while ~isempty(response)
  response = readLineSerialPort(portNum);
end

disp(sprintf('(moncalib:photometerInitTopcon) Sending RM to set photometer into remote mode.'));
% set to remote mode
writeSerialPort(portNum,['RM' char(13) char(10)]);
response = '';
while isempty(response)
  response = readLineSerialPort(portNum);
end
if ~strcmp(response(1:2),'OK')
  disp(sprintf('(moncalib:photometerInitTopcon) Got %s, rather than OK. Somethingis wrong',response(1:max(1,end-2))));
  if ~askuser('Do you still want to continue ')
    return
  end
end

% Don't need the spectral radiance data, so set to D1 data mode
disp(sprintf('(moncalib:photometerInitTopcon) Sending D1 to photometer to set data output mode to not return spectral radiance data.'));
writeSerialPort(portNum,['D1' char(13) char(10)]);
response = '';
while isempty(response)
  response = readLineSerialPort(portNum);
end
if ~strcmp(response(1:2),'OK')
  disp(sprintf('(moncalib:photometerInitTopcon) Got %s, rather than OK from TOPCON when trying to set data output mode to D1 (no spectral radiance data)',response(1:max(1,end-2))));
  if ~askuser('Do you still want to continue ');
    return
  end
else
  disp(sprintf('(moncalib:photometerInitTopcon) Received response: %s',response));
end
retval = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%   photometerMeasureTopcon   %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [luminance x y] = photometerMeasureTopcon(portNum)

global verbose;

luminance = -1;x = 0;y = 0;
% retrieve any info that is pending from the photometer
response = readLineSerialPort(portNum);
while ~isempty(response)
  response = readLineSerialPort(portNum);
end

% now send measurement
writeSerialPort(portNum,['ST',13,10]);

% make sure we got an ok
response = '';
while isempty(response)
  response = readLineSerialPort(portNum);
end
if ~strcmp(response(1:2),'OK')
  disp(sprintf('(moncalib:photometerMeasureTopcon) Got %s, rather than OK from TOPCON when trying to make a measurement',response));
  keyboard
end

% read the measurement
values = [];thisline = '';keepReading = 2;
% keep reading until we get the END signal
while keepReading
  % try to read the next line of data
  thisline = readLineSerialPort(portNum);
   % if we got something grab it.
   if ~isempty(thisline)
     if ~isempty(str2num(thisline))
       values(end+1) = str2num(thisline);
     elseif (length(thisline)>=3) && strcmp(thisline(1:3),'END')
       keepReading = 0;
     end
   end
end

if length(values) >= 11
  if verbose>1
    disp(sprintf('(moncalib) Measuring field: %i Integral time: %i ms Radiance: %f Wm-^2sr^-1\nLuminance: %f cd/m^2\nX: %f Y: %f Z: %f x: %f y: %f u: %f v: %f',values(1),values(2),values(3),values(4),values(5),values(6),values(7),values(8),values(9),values(10),values(11)));
  end
  luminance = values(4);
  x = values(8);
  y = values(9);
else
  disp(sprintf('(moncalib:photometerMeasureTopcon) Uhoh, not enough data values read'));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%   photometerSpectrumMeasurePR650   %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [wavelength radiance] = photometerSpectrumMeasurePR650(portNum)

global verbose;
wavelength = [];
radiance = [];

% retrieve any info that is pending from the photometer
response = readLineSerialPort(portNum);
while ~isempty(response)
  response = readLineSerialPort(portNum);
end

% now take a measurement and read
writeSerialPort(portNum,sprintf('M0\n'));
writeSerialPort(portNum,sprintf('D5\n'));

% read the masurement
% The length doesn't really have to be exact here - guesing this number
% but if comm is very slow, it might time out before getting this many
len = 1700;
str = '';readstr = 'start';
while ~isempty(readstr) || (length(str)<len)
  readstr = readSerialPort(portNum,256);
  str = [str readstr];
  mglWaitSecs(0.1);
end

% this is a bit of a hack to find the point in the string
% where measurements start. (measurements are wavelength
% followed by measurement - comma separaterd). There is some
% preamble that presumably carries the error codes and other
% info, but don't have the manual to know what those are
startWavelength = 380;
start = findstr(str,sprintf('%04i.',startWavelength));

% parse string
[wavelength radiance] = strread(str(22:end),'%f%f','delimiter',',');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%   photometerSpectrumMeasure   %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [wavelength radiance] = photometerSpectrumMeasureTopcon(portNum)

global verbose;
wavelength = [];
radiance = [];

% retrieve any info that is pending from the photometer
response = readLineSerialPort(portNum);
while ~isempty(response)
  response = readLineSerialPort(portNum);
end

% set mode to make spectrum measurement
writeSerialPort(portNum,['D0',13,10]);
response = '';
while isempty(response)
  response = readLineSerialPort(portNum);
end
if ~strcmp(response(1:2),'OK')
  disp(sprintf('(moncalib:photometerSpectrumMeasureTopcon) Got %s, rather than OK from TOPCON when trying to set data output mode to D0 (spectral radiance data)',response(1:max(1,end-2))));
  if ~askuser('Do you still want to continue ');
    return
  end
else
  if verbose>1
    disp(sprintf('(moncalib:photometerSpectrumMeasureTopcon) Received response: %s',response));
  end
end

% now send measurement
writeSerialPort(portNum,['ST',13,10]);

% make sure we got an ok
response = '';
while isempty(response)
  response = readLineSerialPort(portNum);
end
if ~strcmp(response(1:2),'OK')
  disp(sprintf('(moncalib:photometerSpectrumMeasureTopcon) Got %s, rather than OK from TOPCON when trying to make a measurement',response));
  keyboard
end

% read the measurement
values = [];thisline = '';keepReading = 2;valuepairs = [];
% keep reading until we get the END signal
while keepReading
  % try to read the next line of data
  thisline = readLineSerialPort(portNum);
   % if we got something grab it.
   if ~isempty(thisline)
     if ~isempty(str2num(thisline))
       if length(str2num(thisline)) == 2
	 % get wavelength and radiance data
	 valuepairs(1:2,end+1) = str2num(thisline);
       else
	 %get regular luminance measurements
	 values(end+1) = str2num(thisline);
       end
     elseif (length(thisline)>=3) && strcmp(thisline(1:3),'END')
       keepReading = 0;
     end
   end
end

if length(values) >= 11
  if verbose>1
    disp(sprintf('(moncalib) Measuring field: %i Integral time: %i ms Radiance: %f Wm-^2sr^-1\nLuminance: %f cd/m^2\nX: %f Y: %f Z: %f x: %f y: %f u: %f v: %f',values(1),values(2),values(3),values(4),values(5),values(6),values(7),values(8),values(9),values(10),values(11)));
  end
end

if ~isempty(valuepairs)
  wavelength = valuepairs(1,:);
  radiance = valuepairs(2,:);
  if verbose>1
    disp(sprintf('(moncalib:photometerSpectrumMeasureTopcon) Measured spectrum from wavelength %0.1f:%0.1f',min(wavelength),max(wavelength)));
  end
end

% set mode back to color measurement
writeSerialPort(portNum,['D1',13,10]);
response = '';
while isempty(response)
  response = readLineSerialPort(portNum);
end
if ~strcmp(response(1:2),'OK')
  disp(sprintf('(moncalib:photometerSpectrumMeasureTopcon) Got %s, rather than OK from TOPCON when trying to set data output mode to D1 (no spectral radiance data)',response(1:max(1,end-2))));
else
  if verbose>1
    disp(sprintf('(moncalib:photometerSpectrumMeasureTopcon) Received response: %s',response));
  end
end

%%%%%%%%%%%%%%%%%%%%%%%
%    initSeriaPort    %
%%%%%%%%%%%%%%%%%%%%%%%
function portNum = initSerialPort(photometerNum,portNum)

if nargin < 2, portNum = [];end

% minolta uses 4800/e/7/2
if any(photometerNum == [2 3])
  baudRate = 4800;
  parity = 'e';
  dataLen = 7;
  stopBits = 2;
else
  baudRate = 9600;
  parity = 'n';
  dataLen = 8;
  stopBits = 1;
end  

global gSerialPortFun
if strcmp(strtok(gSerialPortFun,':'),'comm')
  portNum = initSerialPortUsingComm(baudRate,parity,dataLen,stopBits,portNum);
elseif strcmp(gSerialPortFun,'serial')
  portNum = initSerialPortUsingSerial(baudRate,parity,dataLen,stopBits,portNum);
else
  disp(sprintf('(moncalib:initSerialPort) Unknown serial device program %s',gSerialPortFun));
  portNum = 0;
end
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% close the serial port
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function closeSerialPort(portNum)

global gSerialPortFun
if strcmp(strtok(gSerialPortFun,':'),'comm')
  closeSerialPortUsingComm(portNum);
elseif strcmp(gSerialPortFun,'serial')
  closeSerialPortUsingSerial(portNum);
else
  disp(sprintf('(moncalib:closeSerialPort) Unknown serial device program %s',gSerialPortFun));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% write to the serial port
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function writeSerialPort(portNum, str)

global gSerialPortFun

if strcmp(strtok(gSerialPortFun,':'),'comm')
  writeSerialPortUsingComm(portNum,str);
elseif strcmp(gSerialPortFun,'serial')
  writeSerialPortUsingSerial(portNum,str);
else
  disp(sprintf('(moncalib:writeSerialPort) Unknown serial device program %s',gSerialPortFun));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% read from the serial port
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function str = readSerialPort(portNum, numbytes)

global gSerialPortFun
if strcmp(strtok(gSerialPortFun,':'),'comm')
  str = readSerialPortUsingComm(portNum,numbytes);
elseif strcmp(gSerialPortFun,'serial')
  str = readSerialPortUsingSerial(portNum,numbytes);
else
  disp(sprintf('(moncalib:readSerialPort) Unknown serial device program %s',gSerialPortFun));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% read one line (ending in 0xA) from the serial port
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function str = readLineSerialPort(portNum)

global gSerialPortFun
if strcmp(strtok(gSerialPortFun,':'),'comm')
  str = readLineSerialPortUsingComm(portNum);
elseif strcmp(gSerialPortFun,'serial')
  str = readLineSerialPortUsingSerial(portNum);
else
  disp(sprintf('(moncalib:readSerialPort) Unknown serial device program %s',gSerialPortFun));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    initSeriaPortUsingSerial    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function portNum = initSerialPortUsingSerial(baudRate,parity,dataLen,stopBits,portNum)

portNum = 0;
% This should be working for Topcon with a Plugable USB/Serial adaptor. 
%
% It does not seem to work for Minolta. And this seems to be something about setting the 7 bit mode, I think.
% For minolta, whatever I do, I.e. send MES with CR/LF it returns characters that look like they are ER
% except they have the top bit set (so they are 128 too big). This should be impossible when doing 7 bit communication
% mode, so must be some bug in the driver. Minolta does seem to work with the Keyspan USA-19HS adaptor
%
% Anyway, it works now for Topcon so the serial port itself must be working correctly
%
% Some notes. The functions that read/write charcter strings with the default Terminators liek
% fgets, fgetl do not seem to work. They just hang. The Terminator setting below is basically
% ignored if you use fread and fwrite instead. So, that is what I did.
%
% To chekc that things are basically working (i.e. it is connected to the device. I found that
% you could check the serial objects (s.PinStatus) and plugging in and plugging in a device
% would read as changes on one of the pins (presumably going high to low).

% display all serial devices
serialDev = dir('/dev/cu.*');

nSerialDev = length(serialDev);
for i = 1:nSerialDev
  disp(sprintf('%i: %s', i,serialDev(i).name));
end
serialDevNum = getnum('Choose a serial device (0 to quit)',0:length(serialDev));
if serialDevNum == 0,return,end

% try to open the device
try
  s = serial(fullfile('/dev',serialDev(serialDevNum).name));

  set(s,'BaudRate',baudRate);
  set(s,'Parity',parity);
  set(s,'StopBits',stopBits);
  set(s,'DataBits',dataLen);
  set(s,'Terminator','CR/LF');
  set(s,'InputBufferSize',2048);
  fopen(s);
  portNum = s;
catch
  disp(sprintf('(moncalib:initSeriaPortUsingSerial) Failed to open serial port. Sometimes restarting matlab helps. Or plugging in and unplugging in serial device. Or making sure that you have the serial device driver installed.'));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% close the serial port
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function closeSerialPortUsingSerial(portNum)

if ~isempty(portNum)
  fclose(portNum);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% write to the serial port
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function writeSerialPortUsingSerial(portNum, str)

fwrite(portNum,str);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% read from the serial port
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function str = readSerialPortUsingSerial(portNum, numbytes)

% This function may not be working properly yet. It now just
% reads however many bytes are available, rather than the numbytes (but not sure
% this might be what was expected).
if portNum.BytesAvailable == 0
  %disp(sprintf('(moncalib:readSerialPortUsingComm) 0 bytes available'));
  str = '';
else
%  disp(sprintf('(moncalib:readSerialPortUsingComm) Reading %i bytes',portNum.BytesAvailable));
  str = char(fread(portNum,portNum.BytesAvailable,'uint8'));
  str = str(:)';
%  disp(sprintf('(moncalib:readSerialPortUsingComm) Received %s',str));
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% read one line (ending in 0xA) from the serial port
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function str = readLineSerialPortUsingSerial(portNum)

% check for input
str = '';
if portNum.BytesAvailable == 0
  return
end

iRead = 0;
% if there is input, read until you get a LF 0x0A 10 character
while (iRead == 0) || (str(end) ~= 10)
  bytesAvailable = portNum.BytesAvailable;
  if bytesAvailable ~= 0
    iRead = iRead + 1;
    str(iRead) = char(fread(portNum,1,'uint8'))';
  end
end
str = strtrim(str);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% init the serial port
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function portNum = initSerialPortUsingComm(baudRate,parity,dataLen,stopBits,portNum)

clc
if isempty(portNum),portNum = 0;end

% get the comm function, this is so that the comm function
% can be called like comm:SerialComm on systems in which this
% comm function has been renamed to SerialCom (e.g. PsychToolbox)
global gSerialPortFun;
global gCommFun;
[dummy gCommFun] = strread(gSerialPortFun,'%s%s','delimiter',':');
if isempty(gCommFun),gCommFun = 'comm';end
if iscell(gCommFun),gCommFun = gCommFun{1};end

% check to see if we have comm functions
if exist(gCommFun)~=3
  disp(sprintf('(moncalib) comm not found\n'));
  disp(sprintf('These functions need the comm.mexmac function to be'));
  disp(sprintf('able to talk to the serial port. You can get the comm'));
  disp(sprintf('function from the mathworks site:\n'));
  disp(sprintf('http://www.mathworks.com/matlabcentral/fileexchange/loadFile.do?objectId=4952&objectType=file'));
  return
end

disp(sprintf('===================================================='));
disp(sprintf('(moncalib) Using serial port function: %s',gCommFun));
disp(sprintf('===================================================='));

% since we do have it, turn the gCommFun into a function handle so we can
% run it
gCommFun = str2func(gCommFun);

% now start up serial function
cudir = dir('/dev/cu.*');
disp(sprintf('You will first have to choose which serial port to use.\n'));
disp('To use the Keyspan USB/serial converter USA-28, you');
disp('will need to download and install the drivers if you');
disp(sprintf('have not done that already:\n'));
disp(sprintf('http://www.keyspan.com/products/usb/usa28x/homepage.2.downloads.spml\n'));
disp(sprintf('If you already have the drivers then the serial'));
disp(sprintf('ports should be listed below as cu.USA28b2P1.1 and P2.2'));
disp(sprintf('for the first and second port respectively.\n'));
disp(sprintf('The following is a list of named serial ports on your system:\n'));
for i = 1:length(cudir)
  disp(sprintf('%s',cudir(i).name));
end
disp(sprintf('\nIt is a bit of a guessing game which port number 1-%i',length(cudir)));
disp(sprintf('goes with which port name listed above, you just have to try'));
disp(sprintf('numbers until you get it right.\n'));

while (portNum == 0)

  portNum = getnum(sprintf('Enter port number to use (0=quit or 1-%i) ',length(cudir)),0:length(cudir));

  if portNum == 0
    disp(sprintf('Quit'));
    return;
  else
    gCommFun('open',portNum,sprintf('%i,%s,%i,%i',baudRate,parity(1),dataLen,stopBits));
    response = askuser;
    
    % ADDED BY FRANCO
    gCommFun('hshake', portNum, 'n');

    if response
      return
    end
    gCommFun('close',portNum);
    portNum = 0;
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% close the serial port
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function closeSerialPortUsingComm(portNum)

global gCommFun;
if portNum
  gCommFun('close',portNum);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% write to the serial port
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function writeSerialPortUsingComm(portNum, str)
global gCommFun

gCommFun('write',portNum,str);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% read from the serial port
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function str = readSerialPortUsingComm(portNum, numbytes)

global gCommFun;
str = char(gCommFun('read',portNum,numbytes));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% read one line (ending in 0xA) from the serial port
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function str = readLineSerialPortUsingComm(portNum)

global gCommFun;
str = gCommFun('readl',portNum);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% gets the user to input a number
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function r = getnum(str,range)

% check arguments
if nargin~=2
  range = [];
end

r = [];
% while we don't have a valid answer, keep asking
while(isempty(r))
  % get user input
  r = input(str,'s');
  % make sure it is a string
  if isstr(r)
    % convert to number
    r = str2num(r);
  else
    r = [];
  end
  % check if it is in range
  if isempty(r) || (~isempty(range) && ~any(r==range))
    r = [];
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ask the user y/n or question
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function r = askuser(question)

% check arguments
if ~any(nargin == [0 1])
  return
end

if ~exist('question','var'),question='Is this ok';end

r = [];
while isempty(r)
  % ask the question
  r = input(sprintf('%s (y/n)? ',question),'s');
		     % make sure we got a valid answer
		     if (lower(r) == 'n')
		       r = 0;
		     elseif (lower(r) == 'y')
		       r = 1;
		     else
		       r =[];
		     end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get monitor's settings for calibration
% from user
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function monitorParameters = setMonitorParameters(screenNumber)

p = [];
while isempty(p)
  % ask the question
  if isempty(screenNumber)
    disp(sprintf('\nPlease insert display settings for monitor []'));
  else
    disp(sprintf('\nPlease insert display settings for monitor %i',screenNumber));
  end	
  disp(sprintf('as a vector of the form: \n'));
  p = input('[screenWidth,screenHeight,frameRate,bitDepth]: ');

  % make sure we got a valid answer
  if ~(length(p) == 4)
    p = [];
  end
end

ID = input('Enter a name for the monitor (this is optional and only really necessary for a system with multiple displays): ','s');

monitorParameters.ID = ID;
monitorParameters.screenWidth = p(1);
monitorParameters.screenHeight = p(2);
monitorParameters.frameRate = p(3);
monitorParameters.bitDepth = p(4);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function to fit with an exponent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function bestparams = fitExponent(x,y,dispfit)

global verbose;

if (nargin == 2)
  dispfit = 0;
elseif (nargin ~= 3)
  help fitExponent
  return
end

% make into row vectors
if (size(x,1) ~= 1),x = x';end
if (size(y,1) ~= 1),y = y';end

% set some of the parameters for the fitting
maxiter = inf;
minfit = [];
maxfit = [];
displsqnonlin = 'off';
initparams = [max(y)-min(y) -median(x) min(y) min(y) max(y)];

% get the fit
bestparams.resnorm = inf;
if verbose == 1,disppercent(-inf,'Fitting data'),end

% minxrange and maxx are used to fit with a flat portion of
% the curve for the beginning and end of the values. In
% practice this didn't work that well, so we just fit
% a single gamme exponent. uncomment the minxrange line
% below, the for maxx line and also the line in experr
% that calculates the model fit assuming linear pieces
%minxrange = 0:0.05:0.5;
minxrange = 0;
for minx = minxrange
  if verbose==1,disppercent((find(minx==minxrange)-1)/length(minxrange));end
  %  for maxx = 0.8:0.05:1
  for maxx = 1
    warning off
    [fitparams resnorm residual exitflag output lambda jacobian] = lsqnonlin(@experr,initparams,minfit,maxfit,optimset('Algorithm','levenberg-marquardt','MaxIter',maxiter,'Display',displsqnonlin),x,y,minx,maxx);
    warning on
    if (resnorm < bestparams.resnorm)
      bestparams.resnorm = resnorm;
      bestparams.minx = minx;
      bestparams.maxx = maxx;
      bestparams.fitparams = fitparams;
      bestparams.residual = residual;
      bestparams.jacobian = jacobian;
      bestparams.x = x;
      bestparams.y = y;
    end
  end
end
if verbose==1,disppercent(inf);end

bestparams.fit = -(experr(bestparams.fitparams,bestparams.x,bestparams.y,bestparams.minx,bestparams.maxx)-y);
bestparams.r2 = 1-var(bestparams.residual)/var(bestparams.y);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function for fitting exponent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [err] = experr(params,x,y,minx,maxx)

% calculate function
%model = params(4)*(x<=minx)+(x>=maxx)*params(5)+(params(1)*((x<maxx)&(x>minx)).*(1-exp(-(x)/params(2)))+params(4));
model = params(1)*(1-exp(-(x)/params(2)));

err = y-model;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function to do my legend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function retval = mylegend(varargin)

% input arguments
if nargin == 1 || ((nargin==2) && (length(varargin{2}) == 1) && (length(varargin{1}) ~= 1))
  % we were just passed names, so parse them
  % and send to regular legend command
  if iscell(varargin{1})
    legstr = sprintf('legend(''%s''',varargin{1}{1});
    for i = 2:length(varargin{1})
      legstr = sprintf('%s,''%s''',legstr,varargin{1}{i});
    end
    if nargin == 2
      legstr = sprintf('%s,%i);',legstr,varargin{2});
    else
      legstr = sprintf('%s);',legstr);
    end
    eval(legstr);
    return
  end
elseif nargin == 2
  legloc = 1;
elseif nargin == 3
  legloc = varargin{3};
else
  help mylegend
  return
end

% remember axis
a = axis;
hold on

% parse input arguments
names = varargin{1};
symbols = varargin{2};

% see if the symbols are just colors
dosymbols = 0;
for i = 1:length(symbols)
  if length(symbols{i}) > 1
    dosymbols = 1;
  end
end

% get some sizes
plottop = a(4);
plotbottom = a(3);
plotleft = a(1);
plotright = a(2);
width = plotright-plotleft;
height = plottop-plotbottom;
marginwidth = width/30;
marginheight = height/30;
symbolwidth = width/20;
spacing = 1;

if ~dosymbols
  symbolwidth = 0;
end

% figure out longest text string
longestname = '';
for i = 1:length(names)
  if (length(names{i})>length(longestname))
    longestname = names{i};
  end
end
% draw it and get its extents
htext = text(plotleft+width/2,plotbottom+height/2,longestname);
set(htext,'Visible','off');
textextent = get(htext,'Extent');
textheight = textextent(4);
textwidth = textextent(3);

marginwidth = textwidth/30;

% figure out size of box
boxwidth = textwidth+symbolwidth+marginwidth*2;
boxheight = textheight*spacing*(length(names)-1)+marginheight*2;


if (legloc == 1) % top right
  boxleft = plotright-marginwidth-boxwidth;
  boxbottom = plottop-marginheight-boxheight;
elseif (legloc == 2) %top left
  boxleft = plotleft+marginwidth;
  boxbottom = plottop-marginheight-boxheight;
elseif (legloc == 3) % bottom left
  boxleft = plotleft+marginwidth;
  boxbottom = plotbottom+marginheight;
elseif (legloc == 4) % bottom right
  boxleft = plotright-marginwidth-boxwidth;
  boxbottom = plotbottom+marginheight;
elseif (legloc == 5) % off to right
  boxleft = plotright;
  boxbottom = plottop-marginheight-boxheight;
  axis([a(1) [boxleft+boxwidth+marginwidth] a(3) a(4)]);
end


% plot the box
hpatch = patch([boxleft boxleft boxleft+boxwidth boxleft+boxwidth],...
	       [boxbottom boxbottom+boxheight boxbottom+boxheight boxbottom],'w');
% set the button down function
set(hpatch,'ButtonDownFcn','mylegendmove(1)');

% plot the names
for i = 1:length(names)
  if dosymbols
    htext(i) = text(boxleft+symbolwidth+marginwidth,boxbottom+boxheight-marginheight-textheight*(i-1)*spacing,names{i},'Interpreter','none');
    set(htext(i),'HorizontalAlignment','left');
  else
    htext(i) = text(boxleft+symbolwidth+marginwidth+textwidth/2,boxbottom+boxheight-marginheight-textheight*(i-1)*spacing,names{i},'Interpreter','none');
    set(htext(i),'HorizontalAlignment','center');
  end
  set(htext(i),'Color',symbols{i}(1));
  if (dosymbols)
    % and the symbols
    hsymbol(i) = plot(boxleft+symbolwidth/2+marginwidth,boxbottom+boxheight-marginheight-textheight*(i-1)*spacing,symbols{i});
  end
end

% store the text and symbol handles in the patch
setappdata(hpatch,'htext',htext);
if dosymbols
  setappdata(hpatch,'hsymbol',hsymbol);
end

%%%%%%%%%%%%%%%%%%%%%%%%
% disppercent function
%%%%%%%%%%%%%%%%%%%%%%%%
function retval = disppercent(percentdone,mesg)

if ~isunix
  if percentdone == -inf
    disp(mesg);
  end
  return
end

% check command line arguments
if ((nargin ~= 1) && (nargin ~= 2))
  help disppercent;
  return
end

% global to turn off printing
global gVerbose;
if ~gVerbose
  return
end

global gDisppercent;

% systems without mydisp (print w/out return that flushes buffers)
if exist('mydisp') ~= 3
  if (percentdone == -inf) && (nargin == 2)
    disp(mesg);
  end
  return
end

% if this is an init then remember time
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (percentdone == -inf)
  % set starting time
  gDisppercent.t0 = clock;
  % default to no message
  if (nargin < 2)
    mydisp(sprintf('00%% (00:00:00)'));
  else
    mydisp(sprintf('%s 00%% (00:00:00)',mesg));
  end
  % display total time at end
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif (percentdone == inf)
  % get elapsed time
  numsecs = etime(clock,gDisppercent.t0);
  % separate seconds and milliseconds
  numms = round(1000*(numsecs-floor(numsecs)));
  numsecs = floor(numsecs);
  % if over a minute then display minutes separately
  if numsecs>60
    nummin = floor(numsecs/60);
    numsecs = numsecs-nummin*60;
    % check if over an hour
    if nummin > 60
      numhours = floor(nummin/60);
      nummin = nummin-numhours*60;
      timestr = sprintf('%i hours %i min %i secs %i ms',numhours,nummin,numsecs,numms);
    else
      timestr = sprintf('%i min %i secs %i ms',nummin,numsecs,numms);
    end
  else
    timestr = sprintf('%i secs %i ms',numsecs,numms);
  end
  % display time string
  mydisp(sprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b\btook %s\n',timestr));
						   % otherwise show update
						   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else
  % avoid things that will end up dividing by 0
  if (percentdone >= 1)
    percentdone = .99;
  elseif (percentdone <= 0)
    percentdone = 0.01;
  end
  % display percent done and estimated time to end
  if (gDisppercent.percentdone ~= floor(100*percentdone))
    mydisp(sprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b\b%02i%% (%s)',floor(100*percentdone),disptime(etime(clock,gDisppercent.t0)*(1/percentdone - 1))));
  end
end
% remember current percent done
gDisppercent.percentdone = floor(100*percentdone);

% display time
function retval = disptime(t)


hours = floor(t/(60*60));
minutes = floor((t-hours*60*60)/60);
seconds = floor(t-hours*60*60-minutes*60);

retval = sprintf('%02i:%02i:%02i',hours,minutes,seconds);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% support function that gets host name using system command
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function hostname = getHostName()

[retval hostname] = system('hostname');
% sometimes there is more than one line (errors from csh startup)
% so need to strip those off
hostname = strread(hostname,'%s','delimiter','\n');
hostname = hostname{end};
if (retval == 0)
  % get it again
  [retval hostname2] = system('hostname');
  hostname2 = strread(hostname2,'%s','delimiter','\n');
  hostname2 = hostname2{end};
  if (retval == 0)
    % find the matching last characers
    % this is necessary, because matlab's system command
    % picks up stray key strokes being written into
    % the terminal but puts those at the beginning of
    % what is returned by stysem. so we run the
    % command twice and find the matching end part of
    % the string to get the hostrname
    minlen = min(length(hostname),length(hostname2));
    for k = 0:minlen
      if (k < minlen)
	if hostname(length(hostname)-k) ~= hostname2(length(hostname2)-k)
	  break
	end
      end
    end
    if (k > 0)
      hostname = hostname(length(hostname)-k+1:length(hostname));
      hostname = lower(hostname);
      hostname = hostname(find(((hostname <= 'z') & (hostname >= 'a')) | '.'));
    else
      hostname = 'unknown';
    end
  else
    hostname = 'unknown';
  end
else
  hostname = 'unknown';
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% gets the name to save as
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function filename = getSaveFilename(hostname)

% get the ouptut filename
hostname = strread(hostname,'%s','delimiter','.');
hostname = hostname{1};
displayDir = mglGetParam('displayDir');
if isempty(displayDir)
  displayDir = fullfile(fileparts(fileparts(which('moncalib'))),'task','displays');
end
defaultdir = fullfile(displayDir,sprintf('*%s*',hostname));
filenames = dir(defaultdir);
maxnum = 0;
for i = 1:length(filenames)
  filenum = strread(filenames(i).name,'%s','delimiter','_');
  filenum = str2num(filenum{1});
  if (filenum > maxnum)
    maxnum = filenum;
  end
end
filename = fullfile(displayDir,sprintf('%04i_%s_%s',maxnum+1,hostname,datestr(now,'yymmdd')));

disp(sprintf('Default calibration name: %s',filename));
response = input('Calibration save name (hit enter to accept default): ','s');
if ~isempty(response)
  % if it is not a fully qualified path then, make it into a monitor
  if isempty(fileparts(response))
    filename = getSaveFilename(response);
  else
    filename = response;
  end
  return
end
disp(sprintf('Saving with name: %s',filename));

%%%%%%%%%%%%%%%%%%%%%%%%%%
%%   getPhotometerNum   %%
%%%%%%%%%%%%%%%%%%%%%%%%%%
function photometerNum = getPhotometerNum

photometerNum = getnum(sprintf('Which photometer are you using?\n  0=quit\n  1-Photo Research [PR650]\n  2-Minolta [LS-100]\n  3-Minolta [CS-100a]\n  4-Topcon [SR-3A])\n==================\n',0:4));

%%%%%%%%%%%%%%%%%%%%%%%%
%    photometerTest    %
%%%%%%%%%%%%%%%%%%%%%%%%
function photometerTest
global gSerialPortFun

disp(sprintf('(moncalib) PhotometerTest using serial port. Make sure your device is connected and ready to go'));
% ask user what photometer they want to use
photometerNum = getPhotometerNum;
if photometerNum == 0,return,end

% open the serial port
portNum = initSerialPort(photometerNum);
if (portNum == 0),return,end

% init the device
if (photometerInit(portNum,photometerNum) == -1)
  closeSerialPort(portNum);
  return
end

disp(sprintf('(moncalib:photometerTest) Trying to make a measurement from your photometer.\nIf the code hangs here, there is probably a communication problem. A few things to try:\n1) Unplug your serial adaptor from the computer and plug it back in again.\n2) Restart Matlab\n3) Reboot the computer (sometimes the serial adaptor needs a good kick in the pants)\n4) Check to make sure you have the correct cable (For example, the Topcon needs a null-modem cable that crosses read/write lines, while other photometers may need a simple pass through cable).\n5) Make sure that your communication mode on the device is setup correctly. Minolta can only use 4800/even/7 bits/2 stop bits. Other photometers have different settings, but should be set to 9600/none/8/1\n6) Power cycle your photometer and try again.'));

% make a measurement
for i = 1
  [l x y] = photometerMeasure(portNum,photometerNum);
  disp(sprintf('============================ Photometer measurement has been made ==============================='));
  disp(sprintf('(moncalib:photometerTest) Measured luminace=%f x=%f y=%f',l,x,y));
  disp(sprintf('================================================================================================='));
end

% and close
closeSerialPort(portNum);

%%%%%%%%%%%%%%%%%%%%%%%%%
%    measureSpectrum    %
%%%%%%%%%%%%%%%%%%%%%%%%%
function calib = measureSpectrum(calib,portNum,photometerNum,testColors)

global verbose;
dispMessage('Measuring spectrum');

mglSetGammaTable(0:1/255:1);
calib.spectrum.testColors = testColors;
if verbose == 1,disppercent(-inf,'Measuring spectrum');end
for i = 1:length(calib.spectrum.testColors)
  mglClearScreen(calib.spectrum.testColors{i});mglFlush;
  % measure spectrum
  [calib.spectrum.wavelength{i} calib.spectrum.radiance{i}] = photometerSpectrumMeasure(portNum,photometerNum);
  % measure luminance x/y
  [calib.spectrum.luminance(i) calib.spectrum.x(i) calib.spectrum.y(i)] = photometerMeasure(portNum,photometerNum);
  if verbose == 1,disppercent(i/length(calib.spectrum.testColors));end
end
if verbose==1,disppercent(inf);end

%%%%%%%%%%%%%%%%%%%%%%%%%
%    displaySpectrum    %
%%%%%%%%%%%%%%%%%%%%%%%%%
function displaySpectrum(calib)

if ~isfield(calib,'spectrum'),return,end

if (exist('smartfig') == 2) && (exist('fixBadChars')==2)
  smartfig('moncalib_displaySpectrum','reuse');
else
  figure;
end

% get wavelength
w = calib.spectrum.wavelength{1};

% get RGB spectrums
R = calib.spectrum.radiance{1};
G = calib.spectrum.radiance{2};
B = calib.spectrum.radiance{3};

for i = 1:3
  subplot(5,1,1);
  plot(w,calib.spectrum.radiance{i},'k-','Color',calib.spectrum.testColors{i});
  hold on;
end
legend(sprintf('Red: lum=%0.4f x=%0.4f y=%0.4f',calib.spectrum.luminance(1),calib.spectrum.x(1),calib.spectrum.y(1)),sprintf('Green: lum=%0.4f x=%0.4f y=%0.4f',calib.spectrum.luminance(2),calib.spectrum.x(2),calib.spectrum.y(2)),sprintf('Blue: lum=%0.4f x=%0.4f y=%0.4f',calib.spectrum.luminance(3),calib.spectrum.x(3),calib.spectrum.y(3)));
title(calib.date);

subplot(5,1,2);
plot(w,calib.spectrum.radiance{4},'k--');
hold on;
plot(w,calib.spectrum.radiance{5},'k-');
plot(w,R+G+B,'k:');

legend(sprintf('Black: lum=%0.4f x=%0.4f y=%0.4f',calib.spectrum.luminance(4),calib.spectrum.x(4),calib.spectrum.y(4)),sprintf('White: lum=%0.4f x=%0.4f y=%0.4f',calib.spectrum.luminance(5),calib.spectrum.x(5),calib.spectrum.y(5)),'linear fit from RGB');

for i = 6:8
  subplot(5,1,i-3);
  c = calib.spectrum.testColors{i};
  plot(w,calib.spectrum.radiance{i},'k-','Color',c);
  hold on;
  % plot linear fit
  plot(w,c(1)*R+c(2)*G+c(3)*B,'k:','Color',c);
  hold on;
  legend(sprintf('lum=%0.4f x=%0.4f y=%0.4f',calib.spectrum.luminance(i),calib.spectrum.x(i),calib.spectrum.y(i)));
end

subplot(5,1,5);
xlabel('Wavelength (nm)');
subplot(5,1,3);
ylabel('Spectral radiance (W m^-2 x nm^-1 x sr^-1)');
drawnow

% display on cieXY 1931 plot (if fucntion exists - lives in justin's matlab directory
if exist('ciexyplot') == 2
  ciexyplot;
  % plot the RGB triangle
  plot(calib.spectrum.x([1:3 1]),calib.spectrum.y([1:3 1]),'k-');
  % plot each point set to have its face color as the color tested
  for i = 1:8
    plot(calib.spectrum.x(i),calib.spectrum.y(i),'ko','MarkerFaceColor',calib.spectrum.testColors{i},'MarkerEdgeColor','k');
  end
end

%%%%%%%%%%%%%%%%%%%%%
%    setupCalib
%%%%%%%%%%%%%%%%%%%%%
function [calib portNum photometerNum todo] = setupCalib(calib,todo)

global verbose;
global lastSettings;
lastSettings = [];

% open the serial port
if isequal(todo.useSerialPort,1) || askuser('Do you want to do an auto calibration using the serial port')
  % ask user what photometer they want to use
  if isempty(todo.photometerNum)
    photometerNum = getPhotometerNum;
  else
    photometerNum = todo.photometerNum;
  end
  if photometerNum == 0,return,end
  portNum = initSerialPort(photometerNum,todo.portNum);
  if (portNum == 0),return,end
  % init the device
  if (photometerInit(portNum,photometerNum) == -1)
    closeSerialPort(portNum);
    disp(sprintf('(moncalib:setupCalibParams) Could not init photometer'));
    photometerNum = -1;
    return
  end
else
  % manual calibration
  portNum = [];
  photometerNum = [];
  verbose = 0;
  % ask the user if they want to do these things, since they
  % take a long time
  if todo.testTable
    todo.testTable = askuser('After calibration you can test the calibration, but this will force you to measure the luminances twice, do you want to test the calibration');
  end
  if todo.bitTest
    todo.bitTest = askuser('Do you want to test whether you have a 10 bit gamma table (this also will require a lot of measurements)');
  end
  if (calib.numRepeats>1) && askuser(sprintf('Number of repeats is set to %i. Would you rather collect only 1 repeat of each measurement',calib.numRepeats))
    calib.numRepeats = 1;
  end
end

% ask to see if we want to save
if askuser('Do you want to save the calibration')
  calib.filename = getSaveFilename(getHostName);
end

% ask user to chose screen parameters for calibration:
% these parameters will be then saved in the calibration structure
% for future reference:
if (~isequal(todo.useCurrentMonitorSettings,1) && ~askuser('Do you want to use current monitor settings? '))
  response = 0;
  while response==0
    monitorParameters = setMonitorParameters(calib.screenNumber);
    response = askuser(sprintf('Monitor "%s" will be set to: [%ix%i] frameRate: %i bitDepth: %i', monitorParameters.ID,monitorParameters.screenWidth, monitorParameters.screenHeight, monitorParameters.frameRate, monitorParameters.bitDepth));
  end
  calib.monitor = monitorParameters;

  % close screen, just in case it is open so we can open at new resolution
  mglClose;
  % now open the screen
  mglOpen(calib.screenNumber,monitorParameters.screenWidth, monitorParameters.screenHeight, monitorParameters.frameRate, monitorParameters.bitDepth);
else
  lastSettings.useCurrentMonitorSettings = 1;
  if todo.getMonitorName
    lastSettings.getMonitorName = 1;
    calib.monitor.ID = input('Enter a name for the monitor (this is optional and only really necessary for a system with multiple displays): ','s');
  else
    lastSettings.getMonitorName = 0;
    calib.monitor.ID = todo.monitorName;
  end
  mglOpen(calib.screenNumber);
end

% save monitor settings that mgl actually opened the monitor to
calib.screenNumber = mglGetParam('displayNumber');
calib.monitor.screenWidth = mglGetParam('screenWidth');
calib.monitor.screenHeight = mglGetParam('screenHeight');
calib.monitor.frameRate = mglGetParam('frameRate');
calib.monitor.bitDepth = mglGetParam('bitDepth');

% set the date of the calibration
if ~isfield(calib,'date'),calib.date = datestr(now);end

if ~isempty(portNum)
  lastSettings.portNum = portNum;
  lastSettings.photometerNum = photometerNum;
  lastSettings.useSerialPort = 1;
else
  lastSettings.useSerialPort = 0;
end
lastSettings.monitorName = todo.monitorName;

  

%%%%%%%%%%%%%%%%%%%%%%
%    measureGamma    %
%%%%%%%%%%%%%%%%%%%%%%
function calib = measureGamma(calib,portNum,photometerNum);

dispMessage('Measuring gamma');

% choose the range of values over which to do the gamma testing
testRange = 0:calib.stepsize:1;

% display what we are doing
disp(sprintf('(moncalib:measureGamma) Measuring %i output luminance values from %0.1f to %0.2f in steps of: %0.4f with %i repeats',length(testRange),min(testRange),max(testRange),calib.stepsize,calib.numRepeats));


% do the gamma measurements
if ~isfield(calib,'uncorrected')
  calib.uncorrected = measureOutput(portNum,photometerNum,testRange,calib.numRepeats);
  saveCalib(calib);
else
  disp(sprintf('(moncalib:measureGamma) Uncorrected luminance measurement already done'));
end

% now build a reverse lookup table
% use linear interpolation
desiredOutput = min(calib.uncorrected.luminance):(max(calib.uncorrected.luminance)-min(calib.uncorrected.luminance))/255:max(calib.uncorrected.luminance);
% check to make sure that we have unique values,
% otherwise interp1 will fail
while length(calib.uncorrected.luminance) ~= length(unique(calib.uncorrected.luminance))
  disp(sprintf('(moncalib:measureGamma) Adjusting luminance values to make them unique'));
  % slight hack here, adding a bit of noise to keep the values
  % unique, shouldn't really distort anything though since the
  % noise is very small.
  calib.uncorrected.luminance = calib.uncorrected.luminance + rand(size(calib.uncorrected.luminance))/1000000;
end
% interpolate table
calib.table = interp1(calib.uncorrected.luminance,calib.uncorrected.outputValues,desiredOutput,'linear')';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    measureGammaEachChannel    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function calib = measureGammaEachChannel(calib,portNum,photometerNum);

% choose the range of values over which to do the gamma testing
testRange = 0:calib.stepsize:1;

% display what we are doing
disp(sprintf('(moncalib:measureGammaEachChannel) Measuring %i output luminance values from %0.1f to %0.2f in steps of: %0.4f with %i repeats',length(testRange),min(testRange),max(testRange),calib.stepsize,calib.numRepeats));

% do the gamma measurements
if ~isfield(calib,'uncorrectedEachChannel')
  calib.uncorrectedEachChannel = [];
end

% test red
if ~isfield(calib.uncorrectedEachChannel,'R')
  dispMessage('Measuring red gamma');
  for i = 1:length(testRange)
    testColors{i} = [testRange(i) 0 0];
  end
  calib.uncorrectedEachChannel.R = measureOutputColor(portNum,photometerNum,testColors,calib.numRepeats);
  saveCalib(calib);
else
  disp(sprintf('(moncalib:measureGammaForEachChannel) Uncorrected luminance measurement for red ready done'));
end
  
if ~isfield(calib.uncorrectedEachChannel,'G')
  dispMessage('Measuring green gamma');
  % test green
  for i = 1:length(testRange)
    testColors{i} = [0 testRange(i) 0];
  end
  calib.uncorrectedEachChannel.G = measureOutputColor(portNum,photometerNum,testColors,calib.numRepeats);
  saveCalib(calib);
else
  disp(sprintf('(moncalib:measureGammaForEachChannel) Uncorrected luminance measurement for green ready done'));
end
  
if ~isfield(calib.uncorrectedEachChannel,'B')
  dispMessage('Measuring blue gamma');
  % test blue
  for i = 1:length(testRange)
    testColors{i} = [0 0 testRange(i)];
  end
  calib.uncorrectedEachChannel.B = measureOutputColor(portNum,photometerNum,testColors,calib.numRepeats);
  saveCalib(calib);
else
  disp(sprintf('(moncalib:measureGammaForEachChannel) Uncorrected luminance measurement for blue ready done'));
end

% now build a reverse lookup table
% use linear interpolation
%desiredOutput = min(calib.uncorrected.luminance):(max(calib.uncorrected.luminance)-min(calib.uncorrected.luminance))/255:max(calib.uncorrected.luminance);
% check to make sure that we have unique values,
% otherwise interp1 will fail
%while length(calib.uncorrected.luminance) ~= length(unique(calib.uncorrected.luminance))
%  disp(sprintf('Adjusting luminance values to make them unique'));
  % slight hack here, adding a bit of noise to keep the values
  % unique, shouldn't really distort anything though since the
  % noise is very small.
%  calib.uncorrected.luminance = calib.uncorrected.luminance + rand(size(calib.uncorrected.luminance))/1000000;
%end
% interpolate table
%calib.table = interp1(calib.uncorrected.luminance,calib.uncorrected.outputValues,desiredOutput,'linear')';


%%%%%%%%%%%%%%%%%%%%%%
%    displayGamma    %
%%%%%%%%%%%%%%%%%%%%%%
function displayGamma(calib,todo)

if isfield(calib,'uncorrected')
  if (exist('smartfig') == 2) && (exist('fixBadChars')==2)
    smartfig('moncalib_displayGamma','reuse');
  else
    figure;
  end
  if (isfield(calib,'bittest') && isfield(calib.bittest,'data')) || todo.bitTest
    subplot(1,2,1);
  end
  dispLuminanceFigure(calib.uncorrected);
  title(calib.date);
  hold on
end

%%%%%%%%%%%%%%%%%%%%%%
%    displayGamma    %
%%%%%%%%%%%%%%%%%%%%%%
function displayGammaEachChannel(calib)

if isfield(calib,'uncorrectedEachChannel');
  if (exist('smartfig') == 2) && (exist('fixBadChars')==2)
    smartfig('moncalib_displayGammaEachChannel','reuse');
  else
    figure;
  end
  subplot(1,5,1);
  dispLuminanceFigure(calib.uncorrectedEachChannel.R,'r');
  title(sprintf('%s\nRed',calib.date));
  hold on
  subplot(1,5,2);
  dispLuminanceFigure(calib.uncorrectedEachChannel.G,'g');
  title(sprintf('%s\nGreen',calib.date));
  hold on
  subplot(1,5,3);
  dispLuminanceFigure(calib.uncorrectedEachChannel.B,'b');
  title(sprintf('%s\nBlue',calib.date));
  hold on
  subplot(1,5,4);
  dispLuminanceFigure(calib.uncorrectedEachChannel.R,'r');
  hold on
  dispLuminanceFigure(calib.uncorrectedEachChannel.G,'g');
  dispLuminanceFigure(calib.uncorrectedEachChannel.B,'b');
  title(sprintf('%s\nRGB',calib.date));
  subplot(1,5,5);
  dispLuminanceFigure(calib.uncorrectedEachChannel.R,'r',1);
  hold on
  dispLuminanceFigure(calib.uncorrectedEachChannel.G,'g',1);
  dispLuminanceFigure(calib.uncorrectedEachChannel.B,'b',1);
  title('Normalized luminance');
end

%%%%%%%%%%%%%%%%%%%%%%
%    testExponent    %
%%%%%%%%%%%%%%%%%%%%%%
function calib = testExponent(calib,portNum,photometerNum);

% now reset the gamma table with the exponent
disp(sprintf('Using function values to linearize gamma'));
mglSetGammaTable(calib.minval,calib.maxval,1/calib.gamma,calib.minval,calib.maxval,1/calib.gamma,calib.minval,calib.maxval,1/calib.gamma);

%and see how well we have done
if ~isfield(calib,'corrected')
  calib.corrected = measureOutput(portNum,photometerNum,calib.uncorrected.outputValues,calib.numRepeats,0);
  saveCalib(calib);
else
  disp(sprintf('Function corrected luminance measurement already done'));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    displayTestExponent    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function displayTestExponent(calib)

dispLuminanceFigure(calib.corrected,'r');

% plot the ideal
plot(calib.uncorrected.outputValues,calib.uncorrected.outputValues*(max(calib.uncorrected.luminance)-min(calib.uncorrected.luminance))+min(calib.uncorrected.luminance),'g-');
if isfield(calib,'gamma')
  mylegend({'uncorrected','corrected (gamma)','corrected (table)','ideal'},{'ko','ro','co','go'},2);
else
  mylegend({'uncorrected','corrected (table)','ideal'},{'ko','co','go'},2);
end

%%%%%%%%%%%%%%%%%%%
%    testTable    %
%%%%%%%%%%%%%%%%%%%
function calib = testTable(calib,portNum,photometerNum);

dispMessage('Testing table corrected gamma');

if ~isfield(calib,'table')
  disp(sprintf('(moncalib:testTable) No table to test'));
  return
end

% now reset the gamma table with the calculated table
disp(sprintf('Using table values to linearize gamma'));
mglSetGammaTable(calib.table);

%and see how well we have done
if ~isfield(calib,'tableCorrected')
  calib.tableCorrected = measureOutput(portNum,photometerNum,calib.uncorrected.outputValues,calib.numRepeats,0);
  saveCalib(calib);
else
  disp(sprintf('Table corrected luminance measurement already done'));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%
%    displayTestTable    %
%%%%%%%%%%%%%%%%%%%%%%%%%%
function displayTestTable(calib)

if isfield(calib,'tableCorrected')
  dispLuminanceFigure(calib.tableCorrected,'c');

  % plot the ideal
  plot(calib.uncorrected.outputValues,calib.uncorrected.outputValues*(max(calib.uncorrected.luminance)-min(calib.uncorrected.luminance))+min(calib.uncorrected.luminance),'g-');
  if isfield(calib,'gamma')
    mylegend({'uncorrected','corrected (gamma)','corrected (table)','ideal'},{'ko','ro','co','go'},2);
  else
    mylegend({'uncorrected','corrected (table)','ideal'},{'ko','co','go'},2);
  end
end

%%%%%%%%%%%%%%%%%
%    bitTest    %
%%%%%%%%%%%%%%%%%
function calib = bitTest(calib,portNum,photometerNum)

dispMessage(sprintf('Testing for %i bit gamma table',calib.bittest.bits));

% test to see how many bits we have in the gamma table
if ~isfield(calib.bittest,'data')
  % The range will start at bittest.base and then go through bittest.n
  % steps of size 1/(2^bittest.bits). A 10 bit monitor should step up
  % luninance for every output increment of 1/1024
  bitTestRange = calib.bittest.base:(1/(2^calib.bittest.bits)):calib.bittest.base+(calib.bittest.n-1)*(1/(2^calib.bittest.bits));
  calib.bittest.data = measureOutput(portNum,photometerNum,bitTestRange,calib.bittest.numRepeats);
end

%%%%%%%%%%%%%%%%%%%%%%%%
%    displayBitTest    %
%%%%%%%%%%%%%%%%%%%%%%%%
function displayBitTest(calib)

if isfield(calib,'bittest') && isfield(calib.bittest,'data')
  if (exist('smartfig') == 2) && (exist('fixBadChars')==2)
    smartfig('moncalib_displayGamma','reuse');
  end
  if isfield(calib,'uncorrected')
    subplot(1,2,2);
  end
  dispLuminanceFigure(calib.bittest.data);
  title(sprintf('%i bit gamma test: Values should increase linearly\nOutput starting at %0.2f in steps of 1/%i (n=%i)',calib.bittest.bits,calib.bittest.base,2^calib.bittest.bits,calib.bittest.numRepeats));
end

%%%%%%%%%%%%%%%%%%%
%    saveCalib    %
%%%%%%%%%%%%%%%%%%%
function saveCalib(calib)

if isfield(calib,'filename')
  eval(sprintf('save %s calib',calib.filename));
end

%%%%%%%%%%%%%%%%%%%
%    parseArgs    %
%%%%%%%%%%%%%%%%%%%
function [calib todo] = parseArgs(nargs,vars)

global verbose;
numRepeats = [];
stepsize = [];
initWaitTime = [];
screenNumber = [];
spectrum = 0;
gamma = 1;
gammaEachChannel = 0;
exponent = 0;
tableTest = 1;
bitTest = 0;
reset = 0;
justDisplay = 0;

bitTestBits = 10;
bitTestN = 12;
bitTestNumRepeats = 16;
bitTestBase = 0.8;

calib = [];
% see if we were actually passed in a calib structure
if (nargs == 1) && isfield(vars{1},'screenNumber')
  % grab calib off the input arguments
  calib = vars{1};
  vars = {vars{2:end}};
  nargs = nargs-1;
  justDisplay = 1;
  % check for old parameterization of bittest
  if isfield(calib,'bittest') && isfield(calib.bittest,'data') && ~isfield(calib.bittest,'bits')
    if isfield(calib.bittest,'stepsize')
      calib.bittest.bits = log2(calib.bittest.stepsize);
    else
      disp(sprintf('(moncalib) Bittest does not have number of bits tested. Setting to 10'));
      calib.bittest.bits = 10;
    end
  end    
end

%(screenNumber,stepsize,numRepeats,testTable,bitTest,initWaitTime)
%check if all arguments are numeric
oldStyleArgs = 1;
for i = 1:nargs
  if ~isnumeric(vars{i})
    oldStyleArgs = 0;
  end
end

% default serial port function
serialPortFun = 'serial';
commTest = 0;
% gSerialPortFun = 'serial'; 
% Note that the serial port function still seems busted. It crashes on fclose on my system and while
% it can write RM to the Topcon and get it into remote mode, it only ever receives a one
% character 0 in return, instead of OK. fprintf seems to send both RM and the CR/LF that
% Topcon is expecting, so that seems ok. Seems to default to synchronous buffered full
% duplex, so not sure what the problem is.

% parse old style arguments
if oldStyleArgs    
  if nargs < 1,screenNumber = [];else screenNumber = vars{1};end
  if nargs < 2,stepsize = 1/256;else stepsize = vars{2};end
  if nargs < 3,numRepeats = 4;else numRepeats = vars{3};end
  if nargs < 4,testTable = 1;else testTable = vars{4};end
  if nargs < 5,bitTest = 0; else bitTest = vars{5};end
  if nargs < 6,initWaitTime = 0; else initWaitTime = vars{6};end
else
  if exist('getArgs') == 2
    getArgs(vars,{'numRepeats=4','stepsize=1/256','initWaitTime=0','screenNumber=[]','spectrum=0','gamma=1','exponent=0','tableTest=1','bitTest=0','reset=0','gammaEachChannel=0','verbose=1','bitTestBits=10','bitTestNumRepeats=4','bitTestN=12','bitTestBase=0.5','serialPortFun',serialPortFun,'commTest=0'});
  else
    disp(sprintf('(moncalib) To parse string arguments you need getArgs from the mrTools distribution. \nSee here: http://gru.brain.riken.jp/doku.php/mgl/gettingStarted#initial_setup'));
    todo = [];
    calib = [];
    return
  end
end

% set serial port function
global gSerialPortFun;
gSerialPortFun = serialPortFun;

% screenNumber -1 means to test comm
if commTest,screenNumber = -1;end

% setup things that we need to do
todo.setupCalib = 1;

todo.dispSettings = 1;
todo.photometerTest = 0;
todo.initWaitTime = initWaitTime;
todo.measureSpectrum = spectrum;
todo.displaySpectrum = spectrum;
todo.measureGamma = gamma;
todo.displayGamma = gamma;
todo.measureGammaEachChannel = gammaEachChannel;
todo.displayGammaEachChannel = gammaEachChannel;
todo.fitExponent = exponent;
todo.displayExponent = exponent;
todo.testExponent = exponent;
todo.displayTestExponent = exponent;
todo.testTable = tableTest;
todo.displayTestTable = tableTest;
todo.bitTest = bitTest;
todo.displayBitTest = bitTest;

% settings used to setup photometer and serial port
todo.useCurrentMonitorSettings = [];
todo.getMonitorName = [];
todo.portNum = [];
todo.photometerNum = [];
todo.useSerialPort = [];
todo.monitorName = '';

% see if we have settings from last run for the above settings
global lastSettings;
if reset,lastSettings = [];end
if isstruct(lastSettings) && ~isempty(lastSettings)
  lastSettingsFields = fields(lastSettings);
else
  lastSettingsFields = [];
end
for i = 1:length(lastSettingsFields)
  todo.(lastSettingsFields{i}) = lastSettings.(lastSettingsFields{i});
  if isnumeric(todo.(lastSettingsFields{i}))
    disp(sprintf('(moncalib:parseArgs) Using previous setting for %s: %s',lastSettingsFields{i},num2str(todo.(lastSettingsFields{i}))));
  else
    disp(sprintf('(moncalib:parseArgs) Using previous setting for %s',lastSettingsFields{i}));
  end
end

% set parameters of calib structure
if ~isfield(calib,'screenNumber'),calib.screenNumber = screenNumber;end
if ~isfield(calib,'stepsize'),calib.stepsize = stepsize;end
if ~isfield(calib,'numRepeats'),calib.numRepeats = numRepeats;end

% decide whether we need to run anything or not
if isfield(calib,'corrected')
  disp(sprintf('(moncalib) Found exponent corrected gamma table'));
  todo.testExponent = 0;
end

if isfield(calib,'table')
  disp(sprintf('(moncalib) Found table corrected gamma table'));
  todo.testTable = 0;
end

if isfield(calib,'bittest') && isfield(calib.bittest,'data')
  disp(sprintf('(moncalib) Found bit test'));
  todo.bitTest = 0;
  todo.displayBitTest = 1;
end

if isfield(calib,'uncorrected')
  disp(sprintf('(moncalib) Found uncorrected gamma measurement table'));
  todo.measureGamma = 0;
end

% if there are no test to run, then we just display
if ~todo.photometerTest && ~todo.measureSpectrum && ~todo.testExponent && ~todo.testTable && ~todo.bitTest && ~todo.measureGamma && ~todo.measureGammaEachChannel
  todo.setupCalib = 0;
end

if calib.numRepeats < 1
  disp(sprintf('(moncalib:parseArgs) numRepeats must be 1 or more'));
  calib.numRepeats = 1;
end

% this is just a photometer test, set everybode to 0
if screenNumber == -1
  todolist = fields(todo);
  for i = 1:length(todolist)
    todo.(todolist{i}) = 0;
  end
  todo.photometerTest = 1;
  lastSettings = 0;
end

% this will be set if passed in a calib structure, set todo list to do display
if justDisplay
  todo.setupCalib = 0;
  todo.dispSettings;

  todo.photometerTest = 0;
  todo.initWaitTime = 0;
  todo.measureSpectrum = 0;
  todo.displaySpectrum = 1;
  todo.measureGamma = 0;
  todo.displayGamma = 1;
  todo.measureGammaEachChannel = 0;
  todo.displayGammaEachChannel = 1;
  todo.fitExponent = 0;
  todo.displayExponent = 0;
  todo.testExponent = 0;
  todo.displayTestExponent = 0;
  todo.testTable = 0;
  todo.displayTestTable = 1;
  todo.bitTest = 0;
  todo.displayBitTest = 1;
end

% choose the range of values over which to test for the number
% of bits the gamma table can be set to
if ~isfield(calib,'bittest'),
  calib.bittest.bits = bitTestBits;
  calib.bittest.base = bitTestBase;
  calib.bittest.n = bitTestN;
  calib.bittest.numRepeats = bitTestNumRepeats;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%
%    fitGammaExponent    %
%%%%%%%%%%%%%%%%%%%%%%%%%%
function calib = fitGammaExponent(calib)

% get the exponent
if isfield(calib,'uncorrected')
  calib.fit = fitExponent(calib.uncorrected.outputValues,calib.uncorrected.luminance,1);
  calib.gamma = -1/calib.fit.fitparams(2);
  calib.minval = calib.fit.minx;
  calib.maxval = calib.fit.maxx;
else
  disp(sprintf('(moncalib:fitGammaExponent) No uncorrected gamma data to fit'));
end

%%%%%%%%%%%%%%%%%%%%%%%%%
%    displayExponent   %%
%%%%%%%%%%%%%%%%%%%%%%%%%
function displayExponent(calib)

if isfield(calib,'fit')
  plot(calib.fit.x,calib.fit.y,'ko');
  hold on
  plot(calib.fit.x,calib.fit.fit,'k-');
  xlabel('x');

  if isfield(calib,'filename')
    gammaStr = sprintf('%s\nMonitor gamma = %f minval=%0.1f maxval = %0.1f',calib.filename,calib.gamma,calib.minval,calib.maxval);
  else
    gammaStr = sprintf('Monitor gamma = %f minval=%0.1f maxval = %0.1f',calib.gamma,calib.minval,calib.maxval);
  end
  title(gammaStr,'interpreter','none');disp(gammaStr);drawnow
else
  disp(sprintf('(moncalib:dispGammaFit) No fit gamma to display'));
end



%%%%%%%%%%%%%%%%%%%%%
%    dispMessage    %
%%%%%%%%%%%%%%%%%%%%%
function dispMessage(s)
global verbose

if verbose > 0
  disp(sprintf(repmat('=',1,80)));
  if ~isempty(s)
    disp(sprintf(s));
    disp(sprintf(repmat('=',1,80)));
  end
end

%%%%%%%%%%%%%%%%%%%%%%
%    dispSettings    %
%%%%%%%%%%%%%%%%%%%%%%
function dispSettings(calib,todo)

clc;
dispMessage('(moncalib) Settings');

if ~todo.photometerTest && ~todo.measureSpectrum && ~todo.testExponent && ~todo.testTable && ~todo.bitTest && ~todo.measureGamma && ~todo.measureGammaEachChannel
  if isfield(calib,'filename')
    disp(sprintf('(moncalib) Displaying data for calibration file %s',calib.filename));
    % get how long it took to do the calibration
    [filepath filename] = fileparts(calib.filename);
    filename = fullfile(filepath,sprintf('%s.mat',filename));
    if isfile(filename)
      d = dir(filename);
      if isfield(d,'datenum') && ~isempty(d.datenum)
	disp(sprintf('(moncalib) Calibration took %s',datestr(d.datenum-datenum(calib.date),13)));
      end
    end
  else
    disp(sprintf('(moncalib) Displaying data for calibration'));
  end    
  disp(sprintf('(moncalib) Calibration measured on %s',calib.date));
  if isfield(calib,'spectrum')
    disp(sprintf('(moncalib) Measured spectrum'));
  end
  if isfield(calib,'uncorrectedEachChannel')
    disp(sprintf('(moncalib) Measured gamma for each channel with stepsize: %f (1/%i), numRepeats: %i',calib.stepsize,round(1/calib.stepsize),calib.numRepeats));
  end
  if isfield(calib,'uncorrected')
    disp(sprintf('(moncalib) Measured gamma with stepsize: %f (1/%i), numRepeats: %i',calib.stepsize,round(1/calib.stepsize),calib.numRepeats));
  end
  if isfield(calib,'bittest') && isfield(calib.bittest,'data')
    disp(sprintf('(moncalib) Measured bittest for %i bits, numRepeats: %i, n: %i, base: %0.2f',calib.bittest.bits,calib.bittest.numRepeats,calib.bittest.n,calib.bittest.base));
  end
  if isfield(calib,'tableCorrected')
    disp(sprintf('(moncalib) Measured table correction with stepsize: %f (1/%i), numRepeats: %i',calib.stepsize,round(1/calib.stepsize),calib.numRepeats));
  end
else
  if isfield(calib,'filename')
    disp(sprintf('Saving to: %s',calib.filename));
  else
    disp(sprintf('Not saving output'));
  end  
end

i = 1;
if todo.measureSpectrum
  disp(sprintf('%i: Measure spectrum',i));
  i = i+1;
end

if  todo.measureGammaEachChannel
  disp(sprintf('%i: Measure gamma for each channel with stepsize: %f (1/%i), numRepeats: %i',i,calib.stepsize,round(1/calib.stepsize),calib.numRepeats));
  i = i+1;
end

if  todo.measureGamma
  disp(sprintf('%i: Measure gamma with stepsize: %f (1/%i), numRepeats: %i',i,calib.stepsize,round(1/calib.stepsize),calib.numRepeats));
  i = i+1;
end

if todo.testTable
  disp(sprintf('%i: Test table',i));
  i = i+1;
end

if todo.bitTest
  disp(sprintf('%i: Test for %i bit gamma card with numRepeats: %i n: %i baseValue: %0.3f',i,calib.bittest.bits,calib.bittest.numRepeats,calib.bittest.n,calib.bittest.base));
  i = i+1;
end

