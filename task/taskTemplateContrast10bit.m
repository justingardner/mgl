% cpoolrule
%
%      usage: taskTemplateContrast10bit
%         by: justin gardner
%       date: 03/25/2010
%    purpose: Template for using the gamma lookup table to get better luminance resolution.
%             You still have 8 bits of color values that you can display at any given time,
%             but you can set the gamma table so that if the maximum contrast stimulus you
%             want to show is 0.5 for instance, that you will get as fine as possible
%             steps of luminance values. This is useful if you want to do contrast discrimination
%             experiments in which you wish to show very small differences in contrast (especially
%             at low pedestal contrast).
%
%             This is done by pre-computing a set of gratings of all possible contrasts given
%             8 bits of color (minus any reserved colors). 
%
%             Then you set the gamma table to the maximum contrast you want to display on the contrast
%             at a given time (say 0.5) 
%
%             setGammaTableForMaxContrast(0.5);
% 
%             Then you extract the correct grating by getting what grating index correspondes to your deisred
%             contrast (say you wanted to show a grating of 0.35);
%
%             gratingIndex = getContrastIndex(0.35);
%
%             want to display)
%
%             mglBltTexture(stimulus.tex(contrastIndex),[0 0 5]);
%
%
function myscreen = taskTemplateContrast10bit(varargin)

% check arguments
if ~any(nargin == [0 1])
  help taskTemplateContrast10bit
  return
end

myscreen = initScreen;

% init the stimulus
clear global stimulus
global stimulus;
myscreen = initStimulus('stimulus',myscreen);

% these are the reserved colors, if you need them later
% you can display them by setting your color to the appropriate
% index in stimulus.colors.reservedColor e.g. to get the
% second color, in this case white, you would do
% mglClearScreen(stimulus.colors.reservedColor(2));
stimulus.colors.reservedColors = [0 0 0; 1 1 1; 0 .65 0; 1 0 0];

% grating parameters
stimulus.grating.radius = 4.5;
stimulus.grating.n = 4;
stimulus.grating.sf = 2;
stimulus.grating.tf = 2;
stimulus.grating.width = 12;
stimulus.grating.height = 12;
stimulus.grating.windowType = 'gabor'; % should be gabor or thresh
stimulus.grating.sdx = stimulus.grating.width/7;
stimulus.grating.sdy = stimulus.grating.width/7;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set up task
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
task{1}{1}.seglen = 1.5;
task{1}{1}.parameter.contrast = [0:0.1:1];
task{1}{1}.random = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% initialze tasks and stimulus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
stimulus = initGratings(stimulus,myscreen,task);

% initialze tasks
for phaseNum = 1:length(task{1})
  [task{1}{phaseNum} myscreen] = initTask(task{1}{phaseNum},myscreen,@startSegmentCallback,@updateScreenCallback,@trialResponseCallback);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% run the eye calibration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
myscreen = eyeCalibDisp(myscreen);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% run the tasks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set which phase is active
tnum = 1;

phaseNum = 1;
while (phaseNum <= length(task{1})) && ~myscreen.userHitEsc
  % update the task
  [task{1} myscreen phaseNum] = updateTask(task{1},myscreen,phaseNum);
  % flip screen
  myscreen = tickScreen(myscreen,task);
end

% if we got here, we are at the end of the experiment
myscreen = endTask(myscreen,task);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     STIMULUS Gratings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function stimulus = initGratings(stimulus,myscreen,task)

% set maximum color index (for 24 bit color we have 8 bits per channel, so 255)
maxIndex = 255;

% get gamma table
if ~isfield(myscreen,'gammaTable')
  stimulus.linearizedGammaTable = mglGetGammaTable;
  disp(sprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'));
  disp(sprintf('(taskTemplateContrast10bit:initGratings) No gamma table found in myscreen. Contrast'));
  disp(sprintf('         displays like this should be run with a valid calibration made by moncalib'));
  disp(sprintf('         for this monitor.'));
  disp(sprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'));
end
stimulus.linearizedGammaTable = myscreen.initScreenGammaTable;

disppercent(-inf,'Creating grating textures');

% calculate some colors information
%  number of reserved colors
stimulus.colors.nReservedColors = size(stimulus.colors.reservedColors,1);

% number of colors possible for gratings, make sure that we 
% have an odd number
stimulus.colors.nGratingColors = maxIndex+1-stimulus.colors.nReservedColors;
if iseven(stimulus.colors.nGratingColors)
  stimulus.colors.nGratingColors = stimulus.colors.nGratingColors-1;
end
% min, mid and max index of gratings colors (index values are 0 based)
stimulus.colors.minGratingIndex = maxIndex+1-stimulus.colors.nGratingColors;
stimulus.colors.midGratingIndex = stimulus.colors.minGratingIndex+floor(stimulus.colors.nGratingColors/2);
stimulus.colors.maxGratingIndex = maxIndex;
% number of contrasts we can display (not including 0 contrast)
stimulus.colors.nDisplayContrasts = floor(stimulus.colors.nGratingColors/2);

% get the color value for gray (i.e. the number between 0 and 1 that corresponds to the midGratingIndex)
stimulus.colors.grayColor = stimulus.colors.midGratingIndex/maxIndex;

% set the reserved colors - this gives a convenient value between 0 and 1 to use the reserved colors with
for i = 1:stimulus.colors.nReservedColors
  stimulus.colors.reservedColor(i) = (i-1)/maxIndex;
end

% make the window through with the gratings will be displayed
gaussianWin = mglMakeGaussian(stimulus.grating.width,stimulus.grating.height,stimulus.grating.sdx,stimulus.grating.sdy);
if strcmp(stimulus.grating.windowType,'gabor')
  % a gaussian window
  win = maxIndex-maxIndex*gaussianWin;
else
  % a simple window
  win = maxIndex-maxIndex*(gaussianWin>exp(-1/2));
end
mask = ones(size(win,1),size(win,2),4)*stimulus.colors.midGratingIndex;
mask(:,:,4) = win;
stimulus.mask = mglCreateTexture(mask);

% make all the 1D gratings. We compute all possible contrast values given the
% range of indexes available to us. The 1st texture is gray the nth texture is full
% contrast for the current gamma setting
for iContrast = 0:stimulus.colors.nDisplayContrasts
  disppercent(iContrast/stimulus.colors.nDisplayContrasts);
  if myscreen.userHitEsc,mglClose;keyboard,end
  % make the grating
  thisGrating = round(iContrast*mglMakeGrating(stimulus.grating.width,nan,stimulus.grating.sf,0,0)+stimulus.colors.midGratingIndex);
  % create the texture
  stimulus.tex(iContrast+1) = mglCreateTexture(thisGrating);
end
disppercent(inf);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     Callbacks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function to set stimulus parameters at
% the beginning of each segment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task myscreen] = startSegmentCallback(task,myscreen)

global stimulus;

% set the maximum contrast we can display
disp(sprintf('(taskTemplateContrast10bit:startSegmentCallback) Displaying contrast of %f',task.thistrial.contrast));
setGammaTableForMaxContrast(task.thistrial.contrast);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function to display stimulus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task myscreen] = updateScreenCallback(task,myscreen)

global stimulus;

% clear screen to gray
mglClearScreen(stimulus.colors.grayColor);

% get the contrast index
contrastIndex = getContrastIndex(task.thistrial.contrast);

% blt texture
mglBltTexture(stimulus.tex(contrastIndex),[0 0 stimulus.grating.height]);

% and mask with the gaussian
mglBltTexture(stimulus.mask,[0 0]);

% put up the fixation cross with reserved color 5
mglFixationCross(0.5,1,stimulus.colors.reservedColor(4));


%%%%%%%%%%%%%%%%%%%%%%%%%%
%    getContrastIndex    %
%%%%%%%%%%%%%%%%%%%%%%%%%%
function contrastIndex = getContrastIndex(desiredContrast,verbose)

if nargin < 2,verbose = 0;end

global stimulus;
if desiredContrast < 0, desiredContrast = 0;end

% now find closest matching contrast we can display with this gamma table
contrastIndex = min(round(stimulus.colors.nDisplayContrasts*desiredContrast/stimulus.currentMaxContrast),stimulus.colors.nDisplayContrasts);

% display the desired and actual contrast values if verbose is set
if verbose
  actualContrast = stimulus.currentMaxContrast*(contrastIndex/stimulus.colors.nDisplayContrasts);
  disp(sprintf('(getContrastIndex) Desired contrast: %0.4f Actual contrast: %0.4f Difference: %0.4f',desiredContrast,actualContrast,desiredContrast-actualContrast));
end

% out of range check
if round(stimulus.colors.nDisplayContrasts*desiredContrast/stimulus.currentMaxContrast)>stimulus.colors.nDisplayContrasts
 disp(sprintf('(getContrastIndex) Desired contrast (%0.9f) out of range max contrast : %0.9f',desiredContrast,stimulus.currentMaxContrast));
 keyboard
end

% 1 based indexes (0th index is gray, nDisplayContrasts+1 is full contrast)
contrastIndex = contrastIndex+1;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sets the gamma table so that we can have
% finest possible control over the stimulus contrast.
%
% stimulus.reservedColors should be set to the reserved colors (for cue colors, etc).
% maxContrast is the maximum contrast you want to be able to display.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function setGammaTableForMaxContrast(maxContrast)

global stimulus;
% if you just want to show gray, that's ok, but to make the
% code work properly we act as if you want to display a range of contrasts
if maxContrast <= 0,maxContrast = 0.01;end

% set the reserved colors
gammaTable(1:size(stimulus.colors.reservedColors,1),1:size(stimulus.colors.reservedColors,2))=stimulus.colors.reservedColors;

% set the gamma table
if maxContrast > 0
  % create the rest of the gamma table
  cmax = 0.5+maxContrast/2;cmin = 0.5-maxContrast/2;
  luminanceVals = cmin:((cmax-cmin)/(stimulus.colors.nGratingColors-1)):cmax;

  % now get the linearized range
  redLinearized = interp1(0:1/255:1,stimulus.linearizedGammaTable.redTable,luminanceVals,'linear');
  greenLinearized = interp1(0:1/255:1,stimulus.linearizedGammaTable.greenTable,luminanceVals,'linear');
  blueLinearized = interp1(0:1/255:1,stimulus.linearizedGammaTable.blueTable,luminanceVals,'linear');
  
  % add these values to the table
  gammaTable((stimulus.colors.minGratingIndex:stimulus.colors.maxGratingIndex)+1,:)=[redLinearized;greenLinearized;blueLinearized]';
else
  % if we are asked for 0 contrast then simply set all the values to gray
  gammaTable((stimulus.colors.minGratingIndex:stimulus.colors.maxGratingIndex)+1,1)=interp1(0:1/255:1,stimulus.linearizedGammaTable.redTable,0.5,'linear');
  gammaTable((stimulus.colors.minGratingIndex:stimulus.colors.maxGratingIndex)+1,2)=interp1(0:1/255:1,stimulus.linearizedGammaTable.greenTable,0.5,'linear');
  gammaTable((stimulus.colors.minGratingIndex:stimulus.colors.maxGratingIndex)+1,3)=interp1(0:1/255:1,stimulus.linearizedGammaTable.blueTable,0.5,'linear');
end

% set the gamma table
mglSetGammaTable(gammaTable);

% remember what the current maximum contrast is that we can display
stimulus.currentMaxContrast = maxContrast;

