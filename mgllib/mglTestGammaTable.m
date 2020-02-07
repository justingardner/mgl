% mglTestGammaTable.m
%
%      usage: mglTestGammaTable()
%         by: justin gardner
%       date: 02/07/20
%    purpose: Should display 5 solid colors on top (white, gray, greeen, red and cyan)
%             And on the bottom should have a black to white gradient going from left to right
%
function retval = mglTestGammaTable()

% check arguments
if ~any(nargin == [0])
  help mglTestGammaTable
  return
end

% close open screen
if ~isequal(mglGetParam('displayNumber'),-1)
  mglClose;
end

% init screen
myscreen = initScreen;

% init the stimulus
global stimulus
stimulus.tenbit = true;
stimulus = initGaussian(stimulus,myscreen);

% clear screen to black
mglClearScreen(stimulus.colors.nReservedColors/255);

% setup text
mglTextSet('Helvetica',32,0.8,0,0,0);

% setup rect dimensions
rectHeight = myscreen.imageHeight/2;
rectY = rectHeight/2;
rectWidth = myscreen.imageWidth/stimulus.colors.nReservedColors;

% make nReservedColors rectangles with the reserved colors
for iColor = 1:stimulus.colors.nReservedColors
  % get color index
  colorIndex = stimulus.colors.reservedColor(iColor);
  % make color square
  rectX = -(myscreen.imageWidth/2) + rectWidth * (iColor-1)+rectWidth/2;
  mglFillRect(rectX,rectY,[rectWidth rectHeight],colorIndex);
  % draw text
  mglTextDraw(sprintf('Color: %i',iColor),[rectX,rectY]);
end

disp(sprintf('(mglTestGammaTable:testGammaTable) Top row should be reserved colors'));

% setup rect dimensions
rectHeight = myscreen.imageHeight/2;
rectY = -rectHeight/2;
rectWidth = myscreen.imageWidth/(256-stimulus.colors.nReservedColors);

% make nReservedColors rectangles with the reserved colors
for iColor = stimulus.colors.nReservedColors:255
  % get color index
  colorIndex = iColor/255;
  % make color square
  rectX = -(myscreen.imageWidth/2) + rectWidth * (iColor-1)+rectWidth/2;
  mglFillRect(rectX,rectY,[rectWidth rectHeight],colorIndex);
end

disp(sprintf('(mglTestGammaTable:testGammaTable) Bottom row should be stimulus colors'));
mglFlush;

% wait and close
if isequal(mglGetParam('displayNumber'),1) && (length(mglDescribeDisplays) == 1)
  mglWaitSecs(3);
  mglClose;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function to init the stimulus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function stimulus = initGaussian(stimulus,myscreen)

global stimulus;

% fixation cross
stimulus.fixWidth = 1;
stimulus.fixColor = [1 1 1];
stimulus.colors.reservedColors = [1 1 1; 0.3 0.3 0.3; 0 1 0;1 0 0; 0 1 1];

%stimulus contrast
stimulus.contrast = 1;

% set gaussian width in degrees
stimulus.width = 6;

if stimulus.tenbit
  % set maximum color index (for 24 bit color we have 8 bits per channel, so 255)
  maxIndex = 255;

  % get gamma table
  if ~isfield(myscreen,'gammaTable')
    stimulus.linearizedGammaTable = mglGetGammaTable;
    disp(sprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'));
    disp(sprintf('(mglTestGammaTable:initGratings) No gamma table found in myscreen. Contrast'));
    disp(sprintf('         displays like this should be run with a valid calibration made by moncalib'));
    disp(sprintf('         for this monitor.'));
    disp(sprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'));
  end
  stimulus.linearizedGammaTable = myscreen.initScreenGammaTable;

  % disppercent(-inf,'Creating gaussian textures');

  % calculate some colors information
  %  number of reserved colors
  stimulus.colors.nReservedColors = size(stimulus.colors.reservedColors,1);
  % number of colors possible for gratings, make sure that we 
  % have an odd number
  stimulus.colors.nGaussianColors = maxIndex+1-stimulus.colors.nReservedColors;
  % if iseven(stimulus.colors.nGaussianColors)
  %   stimulus.colors.nGaussianColors = stimulus.colors.nGaussianColors-1;
  % end

  % min,mid,max index of gaussian colors
  stimulus.colors.minGaussianIndex = maxIndex+1 - stimulus.colors.nGaussianColors;
  stimulus.colors.midGaussianIndex = stimulus.colors.minGaussianIndex + floor(stimulus.colors.nGaussianColors/2);
  stimulus.colors.maxGaussianIndex = maxIndex;
  % number of contrasts we can display (not including 0 contrast)
  stimulus.colors.nDisplayContrasts = floor(stimulus.colors.nGaussianColors-1);

  % set the reserved colors - this gives a convenient value between 0 and 1 to use the reserved colors with
  for i = 1:stimulus.colors.nReservedColors
    stimulus.colors.reservedColor(i) = (i-1)/maxIndex;
  end

  setGammaTableForMaxContrast(stimulus.contrast);
  contrastIndex = getContrastIndex(stimulus.contrast,1);
  
  % get range of colors that the gaussian will have
  stimulus.colors.gaussRange = contrastIndex-1;

  % cycle over widths
  for iWidth = 1:length(stimulus.width)
    % make each gaussian
    stimulus.gaussian{iWidth} = mglMakeGaussian(myscreen.imageWidth, myscreen.imageHeight, stimulus.width(iWidth),stimulus.width(iWidth));
    % make the gaussian have the correct range of colors (i.e. avoid the reserved colors)
    thisGaussian = round(stimulus.colors.gaussRange*stimulus.gaussian{iWidth} + stimulus.colors.minGaussianIndex);
    
    % create the texture
    stimulus.tex(iWidth) = mglCreateTexture(thisGaussian);
  end

  % get the color value for black (i.e. the number between 0 and 1 that corresponds to the minGaussianIndex)
  stimulus.colors.black = stimulus.colors.minGaussianIndex/maxIndex;

  % get the color values (i.e. reserved color)
  stimulus.colors.white = stimulus.colors.reservedColor(1);
  stimulus.colors.red = stimulus.colors.reservedColor(4);
  stimulus.colors.green = stimulus.colors.reservedColor(3);
  stimulus.colors.grey = stimulus.colors.reservedColor(2);
  stimulus.colors.cyan = stimulus.colors.reservedColor(5);
  
else

  dispHeader('THIS CODE HAS NOT BEEN TESTED');
  % note that there is really no need to run this as a 10-bit anymore given the way the noisy
  % background works - should be easy to make this old version work again, but haven't tested
  % to get it back going - jg: 11/20/2019
  keyboard
  
  % cycle over widths
  for iWidth = 1:length(stimulus.width)

    % make full screen gaussian
    stimulus.gaussian{iWidth} = mglMakeGaussian(myscreen.imageWidth, myscreen.imageHeight, stimulus.width(iWidth), stimulus.width(iWidth));
    
    % fill out the three color channels
    stimulus.gaussianRGBA{iWidth} = repmat(stimulus.gaussian{iWidth},1,1,1,3);

    % set alpha channel
    stimulus.gaussianRGBA{iWidth}(:,:,:,4) = 255*stimulus.contrast;
    
    % create the texture
    stimulus.tex{iWidth} = mglCreateTexture(stimulus.gaussian{iWidth});
  end
  
  % get the color value for black (i.e. the number between 0 and 1 that corresponds to the minGaussianIndex)
  stimulus.colors.black = 0;
  
  % get the color values (i.e. reserved color)
  stimulus.colors.white = 1;
  stimulus.colors.grey = 0.3;
  stimulus.colors.green = [0 1 0];
  stimulus.colors.red = [1 0 0];
  stimulus.colors.cyan = [0 1 1];
end

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
%   cmax = 0.5+maxContrast/2;cmin = 0.5-maxContrast/2;
  cmin = 0;
  cmax = maxContrast;
  luminanceVals = cmin:((cmax-cmin)/(stimulus.colors.nGaussianColors-1)):cmax;

  % replace NaN in gamma tables with zero
  stimulus.linearizedGammaTable.redTable(isnan(stimulus.linearizedGammaTable.redTable)) = 0;
  stimulus.linearizedGammaTable.greenTable(isnan(stimulus.linearizedGammaTable.greenTable)) = 0;
  stimulus.linearizedGammaTable.blueTable(isnan(stimulus.linearizedGammaTable.blueTable)) = 0;

  % now get the linearized range
  redLinearized = interp1(0:1/255:1,stimulus.linearizedGammaTable.redTable,luminanceVals,'linear');
  greenLinearized = interp1(0:1/255:1,stimulus.linearizedGammaTable.greenTable,luminanceVals,'linear');
  blueLinearized = interp1(0:1/255:1,stimulus.linearizedGammaTable.blueTable,luminanceVals,'linear');
  
  % add these values to the table
  gammaTable((stimulus.colors.minGaussianIndex:stimulus.colors.maxGaussianIndex)+1,:)=[redLinearized;greenLinearized;blueLinearized]';
else
  % if we are asked for 0 contrast then simply set all the values to BLACK
  gammaTable((stimulus.colors.minGaussianIndex:stimulus.colors.maxGaussianIndex)+1,1)=interp1(0:1/255:1,stimulus.linearizedGammaTable.redTable,0,'linear');
  gammaTable((stimulus.colors.minGaussianIndex:stimulus.colors.maxGaussianIndex)+1,2)=interp1(0:1/255:1,stimulus.linearizedGammaTable.greenTable,0,'linear');
  gammaTable((stimulus.colors.minGaussianIndex:stimulus.colors.maxGaussianIndex)+1,3)=interp1(0:1/255:1,stimulus.linearizedGammaTable.blueTable,0,'linear');
end

% set the gamma table
mglSetGammaTable(gammaTable);

% keep the gamma table
stimulus.gammaTable = gammaTable;

% remember what the current maximum contrast is that we can display
stimulus.currentMaxContrast = maxContrast;

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

