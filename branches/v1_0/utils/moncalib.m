% moncalib.m
%
%      usage: moncalib(screenNumber,stepsize,numRepeats)
%         by: justin gardner & jonas larsson
%       date: 10/02/06
%    purpose: routine to do monitor calibration
%             uses PhotoResearch PR650 photometer/colorimeter
% 
%             stepsize is how finely you want to measure
%             luminance changes (value < 1.0) (default is 1/32)
%
%             numRepeats is the number of repeats you want
%             to make of the measurements (default is 2)
%
%             This works by using the serial port interface
%             to the PR650 and the comm library from the
%             mathworks site:
%
%http://www.mathworks.com/matlabcentral/fileexchange/loadFile.do?objectId=4952&objectType=file
%
%             If you want to rewrite this function to use a different
%             serial port interface function, then you just need
%             to change the functions initSerialPort, closeSerialPort
%             readSerialPort and writeSerialPort
%
%             If you want to change this function to use a different
%             photometer then you need to change the functions
%             photometerInit and photometerMeasure 
%
%             If you pass it in a calib matlab structure that it has
%             saved then it will display the calibration. It will
%             also continue with a calibration that has only partially
%             been finished (like if you forced a quit in the middle)
%             The function saves the calibration file after each step
function calib = moncalib(screenNumber,stepsize,numRepeats)

% check arguments
if ~any(nargin == [0 1 2 3])
  help moncalib
  return
end

global verbose;
verbose = 1;
doGamma = 1;
doExponent = 1;
testExponent = 1;
testTable = 1;
doBittest = 1;

% see if we were actually passed in a calib structure
if (nargin > 0) & isfield(screenNumber,'screenNumber')
  calib = screenNumber;
else
  if ~exist('screenNumber','var')
    calib.screenNumber = [];
  else
    calib.screenNumber = screenNumber;
  end
  if ~exist('stepsize','var')
    calib.stepsize = 1/32;
  else
    calib.stepsize = stepsize;
  end
  if ~exist('numRepeats','var')
    calib.numRepeats = 2;
  else
    calib.numRepeats = numRepeats;
  end
end

justdisplay = 1;
if ~isfield(calib,'bittest') | ~isfield(calib,'uncorrected') | ...
      (~isfield(calib,'corrected') & testExponent) | ...
      (~isfield(calib,'tableCorrected') & testTable)
  justdisplay = 0;
  % open the serial port
  portnum = initSerialPort;
  if (portnum == 0),return,end

  % init the device
  if (photometerInit(portnum) == -1)
    closeSerialPort(portnum);
    return
  end

  % ask to see if we want to save
  if askuser('Do you want to save the calibration')
    moncalib.filename = getSaveFilename(getHostName);
  end
  
  % now open the screen
  mglOpen(calib.screenNumber);
end

% choose the range of values over which to do the gamma testing
testRange = 0:calib.stepsize:1;
% choose the range of values over which to test for the number
% of bits the gamma table can be set to
if ~isfield(calib,'bittest'),
  calib.bittest.stepsize = 2048;
  calib.bittest.base = 0.5;
  calib.bittest.n = 8;
end
% The range will start at bittest.base and then go through bittest.n
% steps of size bittest.stepsize. A 10 bit monitor should step up
% luninance for every output increment of 1/1024
bitTestRange = calib.bittest.base:(1/calib.bittest.stepsize):calib.bittest.base+calib.bittest.n*(1/calib.bittest.stepsize);

% set the date of the calibration
if ~isfield(calib,'date'),calib.date = datestr(now);end

if doGamma
 % do the gamma measurements
 if ~isfield(calib,'uncorrected')
   calib.uncorrected = measureOutput(portnum,testRange,calib.numRepeats);
   if isfield(calib,'filename')
     eval(sprintf('save %s calib',calib.filename));
   end
 else
   disp(sprintf('Uncorrected luminance measurement already done'));
 end
 figure;subplot(1,2,1);
 dispLuminanceFigure(calib.uncorrected);

 if doExponent
   % get the exponent
   calib.fit = fitExponent(calib.uncorrected.outputValues,calib.uncorrected.luminance,1);
   calib.gamma = -1/calib.fit.fitparams(2);
   calib.minval = calib.fit.minx;
   calib.maxval = calib.fit.maxx;
   gammaStr = sprintf('%s\nMonitor gamma = %f minval=%0.1f maxval = %0.1f',calib.filename,calib.gamma,calib.minval,calib.maxval);
   title(gammaStr,'interpreter','none');disp(gammaStr);drawnow
 end
 
 % now build a reverse lookup table
 % use linear interpolation
 desiredOutput = min(calib.uncorrected.luminance):(max(calib.uncorrected.luminance)-min(calib.uncorrected.luminance))/255:max(calib.uncorrected.luminance);
 % check to make sure that we have unique values,
 % otherwise interp1 will fail
 while length(calib.uncorrected.luminance) ~= length(unique(calib.uncorrected.luminance))
   disp(sprintf('Adjusting luminance values to make them unique'));
   % slight hack here, adding a bit of noise to keep the values
   % unique, shouldn't really distort anything though since the
   % noise is very small.
   calib.uncorrected.luminance = calib.uncorrected.luminance + rand(size(calib.uncorrected.luminance))/1000000;
 end
 % interpolate table
 calib.table = interp1(calib.uncorrected.luminance,calib.uncorrected.outputValues,desiredOutput,'linear')';
 if ~justdisplay
   if isfield(calib,'filename')
     eval(sprintf('save %s calib',calib.filename));
   end
 end

 if testExponent
   % now reset the gamma table with the exponent
   disp(sprintf('Using function values to linearize gamma'));
   mglSetGammaTable(calib.minval,calib.maxval,1/calib.gamma,calib.minval,calib.maxval,1/calib.gamma,calib.minval,calib.maxval,1/calib.gamma);
   
   %and see how well we have done
   if ~isfield(calib,'corrected')
     calib.corrected = measureOutput(portnum,calib.uncorrected.outputValues,calib.numRepeats,0);
     if isfield(calib,'filename')
       eval(sprintf('save %s calib',calib.filename));
     end
   else
     disp(sprintf('Function corrected luminance measurement already done'));
   end
   dispLuminanceFigure(calib.corrected,'r');
 end
 
 if testTable
   % now reset the gamma table with the calculated table
   disp(sprintf('Using table values to linearize gamma'));
   mglSetGammaTable(calib.table);

   %and see how well we have done
   if ~isfield(calib,'tableCorrected')
     calib.tableCorrected = measureOutput(portnum,calib.uncorrected.outputValues,calib.numRepeats,0);
     if isfield(calib,'filename')
       eval(sprintf('save %s calib',calib.filename));
     end
   else
     disp(sprintf('Table corrected luminance measurement already done'));
   end
   dispLuminanceFigure(calib.tableCorrected,'c');
 end
 if testTable || testExponent
   % plot the ideal
   plot(calib.uncorrected.outputValues,calib.uncorrected.outputValues*(max(calib.uncorrected.luminance)-min(calib.uncorrected.luminance))+min(calib.uncorrected.luminance),'g-');
   mylegend({'uncorrected','corrected (gamma)','corrected (table)','ideal'},{'ko','ro','co','go'},2);
 end
end

if doBittest
  % test to see how many bits we have in the gamma table
  disp(sprintf('Testing how many bits the gamma table is'));
  if ~isfield(calib.bittest,'luminance')
    calib.bittest = measureOutput(portnum,bitTestRange,calib.numRepeats);
  end
  subplot(1,2,2);
  dispLuminanceFigure(calib.bittest);
  title(sprintf('Output starting at %0.2f\nin steps of 1/%i',calib.bittest.base,calib.bittest.stepsize));
end

if ~justdisplay
  % close the serial port, it may be better to just leave it
  % open, so that it you don't have to restart the photometer each time
  %closeSerialPort(portnum);

  % close the screen
  mglClose;

  % save file
  if isfield(calib,'filename')
    eval(sprintf('save %s calib',calib.filename));
  end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function that sets the gamma table to all the values in val
% and checks the luminance
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function retval = measureOutput(portnum,outputValues,numRepeats,setGamma)

global verbose;

% default to setting gamma values, not clor values
if ~exist('setGamma','var'),setGamma=1;,end

% clear and flush screen
mglClearScreen(0);mglFlush;

measuredLuminanceSte = [];measuredLuminance = [];
if verbose == 1,disppercent(-inf,'Measuring luminance');end
for val = outputValues
  if verbose == 1,disppercent((find(val==outputValues)-1)/length(outputValues));end
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
      thisMeasuredLuminance(repeatNum) = photometerMeasure(portnum);
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
  % now take average over all repeats of measurement
  measuredLuminance(end+1) = mean(thisMeasuredLuminance(1:numRepeats));
  measuredLuminanceSte(end+1) = std(thisMeasuredLuminance(1:numRepeats))/sqrt(numRepeats);
  if (verbose>1),disp(sprintf('Luminance = %0.4f',measuredLuminance(end)));end
end
if (verbose == 1),disppercent(inf);end

% pack it up
retval.outputValues = outputValues;
retval.luminance = measuredLuminance;
retval.luminanceSte = measuredLuminanceSte;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% display a figure that shows measurements
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function dispLuminanceFigure(table,color)

if ~exist('color','var'),color = 'k';,end

errorbar(table.outputValues,table.luminance,table.luminanceSte,sprintf('%so-',color));
xlabel('output value');
ylabel('luminance (cd/m^-2)');

drawnow;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% init the photometer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function retval = photometerInit(portnum)

clc
retval = -1;
response = 0;
while(response == 0)
  
  input(sprintf('Please turn on the PR650 and within 5 seconds press enter: '));
  % send a command, any command will do. We set the backlight on
  writeSerialPort(portnum,sprintf('B3\n'));
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
writeSerialPort(portnum,sprintf('B0\n'));

% set up measurement parameters
% integrate over how many ms. 0 is adaptive, otherwise 10-6000 is 
% number of ms 
integrationTime = 0;
% number of measurement averages to use from 01-99
averageCount = 1;
% the last 1 here specifies measuring in unis of cd*m-2 or lux
% set to 0 for footLamberts/footcandles
writeSerialPort(portnum,sprintf('S,,,,,%i,%i,1\n',integrationTime,averageCount));

retval = 1;
clc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% measure luminance with the photometer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [luminance x y] = photometerMeasure(portnum)

% retrieve any info that is pending from the photometer
readSerialPort(portnum,1024);
% now take a measurement and read
writeSerialPort(portnum,sprintf('M1\n'));
writeSerialPort(portnum,sprintf('D1\n'));

% read the masurement
len = length('QQ,U,Y.YYYYEsee,.xxxx,.yyyy');
str = '';readstr = 'start';
while ~isempty(readstr) | (length(str)<len)
  readstr = readSerialPort(portnum,256);
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
  thisMessage = '';
else
  thisMessage = errorMsg{thisMessageNum(1)};
end
global verbose
if ((verbose>1) || thisMessageNum),disp(sprintf('%s Luminance=%f cd/m^-2 (1931 CIE x)=%f (1931 CIE y)=%f',thisMessage,Y(i),x(i),y(i)));end

if quality(i) ~= 0
  luminance = nan;
else
  luminance = Y(i);
  x = x(i);
  y = y(i);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% init the serial port
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function portnum = initSerialPort

clc
portnum = 0;

% check to see if we have comm functions
if exist('comm')~=3
  disp(sprintf('UHOH: comm not found\n'));
  disp(sprintf('These functions need the comm.mexmac function to be'));
  disp(sprintf('able to talk to the serial port. You can get the comm'));
  disp(sprintf('function from the mathworks site:\n'));
  disp(sprintf('http://www.mathworks.com/matlabcentral/fileexchange/loadFile.do?objectId=4952&objectType=file'));
  return
end
  
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

while (portnum == 0)
  
  portnum = getnum(sprintf('Enter port number to use (0=quit or 1-%i) ',length(cudir)),0:length(cudir));

  if portnum == 0
    disp(sprintf('Quit'));
    return;
  else
    comm('open',portnum,'9600,n,8,1');
    response = askuser;
    if response
      return
    end
    comm('close',portnum);
    portnum = 0;
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% close the serial port
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function closeSerialPort(portnum)

if portnum
  comm('close',portnum);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% write to the serial port
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function writeSerialPort(portnum, str);

comm('write',portnum,str);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% read from the serial port
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function str = readSerialPort(portnum, numbytes);

str = char(comm('read',portnum,numbytes))';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% gets the user to input a number
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function r = getnum(str,range)

% check arguments
if nargin~=2
  help getnum
  return
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
  if isempty(r) || ~any(r==range)
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
    [fitparams resnorm residual exitflag output lambda jacobian] = lsqnonlin(@experr,initparams,minfit,maxfit,optimset('LevenbergMarquardt','on','MaxIter',maxiter,'Display',displsqnonlin),x,y,minx,maxx);
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

% display the fit
if (dispfit)
  plot(bestparams.x,bestparams.y,'ko');
  hold on
  plot(x,bestparams.fit,'k-');
  xlabel('x');
  title(sprintf('amp=%0.2f tau=%0.2f offset=%0.2f linear till %0.2f (%0.2f) linear after %0.2f (%0.2f)',bestparams.fitparams(1),bestparams.fitparams(2),bestparams.fitparams(3),bestparams.minx,bestparams.fitparams(4),bestparams.maxx,bestparams.fitparams(5)));
end

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
defaultdir = sprintf('%s/task/displays/*%s*',fileparts(fileparts(which('moncalib'))),hostname);
filenames = dir(defaultdir);
maxnum = 0;
for i = 1:length(filenames)
  filenum = strread(filenames(i).name,'%s','delimiter','_');
  filenum = str2num(filenum{1});
  if (filenum > maxnum)
    maxnum = filenum;
  end
end
filename = sprintf('%s/task/displays/%04i_%s_%s',fileparts(fileparts(which('moncalib'))),maxnum+1,hostname,datestr(now,'yymmdd'));

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

