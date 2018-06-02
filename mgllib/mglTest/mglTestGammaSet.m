% mglTestGammaSet.m
%
%        $Id:$ 
%      usage: mglTestGammaSet()
%         by: justin gardner
%       date: 03/06/15
%    purpose: Test gamma table setting 
% 
% 6/1/2018 Seems to be broken again on 10.13 High Sierra. The gamma table that
% gets sets first off seems to be missing the first few values - maybe about 8
% and then also seems to skip some values. This does not seem to have to do with
% interpolation anymore as the table reads that it needs 10 bit and writes that
% Might be worth trying to go into 10 bit mode - started writing code in mglPrivateOPen for doing that. Essentially you need to set the following attributes: 
%   NSOpenGLPixelFormatAttribute attrs[] = {
%     NSOpenGLPFADoubleBuffer,
%     NSOpenGLPFAColorSize, 64,
%     NSOpenGLPFAColorFloat,
%     NSOpenGLPFAMultisample,
%     NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion4_1Core,  
%     0
%   };
% Note that tho use this you have to make sure that useCGL is set to 0. But, this
% is not giving good results yet - the main issue seems to be that if you ask for
%     Version4_1 core in the last line then nothing works. If you omit that it
%     doesn't really seem to change anything except add some weird color
%     dithering. There is now a function called mglDeepColorTest which is
%     stripped down texture code for trying to generate a deep color texture
%     no love there either - code works, but have not been able to input from
%     a 16 bit array
%
function retval = mglTestGammaSet(dispNum)

% check arguments
if ~any(nargin == [0 1])
  help mglTestSetGamma
  return
end

% which tests to do
doTextureDraw = 1;
doClearScreen = 1;
doRectDraw = 1;
doRectDrawFast = 1;
doBitDepthTest = 1;

% set verbose = 2 for full gamma table listing
mglSetParam('useCGL',0);
mglSetParam('verbose',1);

if nargin < 1
  dispNum = [];
end
disp(sprintf('(mglTestGammaSet) This first screen should appear as horizontal bars with grays on top and RGBCMYK values on bottom'));

% make a funky table
% some basic colors
table(1,:)  = [0 0 0];
table(2,:) = [1 1 1];
table(3,:) =   [1 0 0];
table(4,:) = [0 1 0];
table(5,:) = [0 0 1];
table(6,:) =  [0 1 1];
table(7,:) = [1 0 1];
table(8,:) = [1 1 0];

% some grays
table(9,:) =  [1 1 1]/8;
table(10,:) =  [2 2 2]/8;
table(11,:) = [3 3 3 ]/8;
table(12,:) =  [4 4 4]/8;
table(13,:) = [5 5 5]/8;
table(14,:) = [6 6 6]/8;
table(15,:) = [7 7 7]/8;
table(16,:) = [8 8 8]/8;

table = repmat(table,16,1);
%table = [table;flipud(table)];
%table = repmat(table,8,1);
%redTable = repmat([1 0 0],240,1);
%table = [table;redTable];


rgbTable = zeros(256,3);
rgbTable1024 = zeros(256,3);
for i = 1:3
  for j = 1:64
    % rgbTable, r/g or b value
    rgbTable(j+(i-1)*64,i) = j/64;
    % rgbTable white value
    rgbTable(j+192,i) = j/64;
    % rgbTable1024
    rgbTable1024((j-1)*4+(i-1)*256+1,i) = j/64;
    rgbTable1024((j-1)*4+(i-1)*256+2,i) = j/64;
    rgbTable1024((j-1)*4+(i-1)*256+3,i) = j/64;
    rgbTable1024((j-1)*4+(i-1)*256+4,i) = j/64;
    rgbTable1024((j-1)*4+768+1,i) = j/64;
    rgbTable1024((j-1)*4+768+2,i) = j/64;
    rgbTable1024((j-1)*4+768+3,i) = j/64;
    rgbTable1024((j-1)*4+768+4,i) = j/64;
  end
end
table = rgbTable1024;

table1024 = repmat(table,4,1);

% open window, set table
mglOpen(dispNum);
mglClearScreen(0);mglFlush;

mglSetGammaTable(table);
setTable = mglGetGammaTable;
setTable = [setTable.redTable ;setTable.greenTable ;setTable.blueTable]';
if isequal(table,setTable)
  disp(sprintf('(mglTestGammaSet) mglGetGammaTable returns what was set correctly'));
else
  disp(sprintf('(mglTestGammaSet) !!! mglGetGammaTable retuns a **difference** from what was actually set !!!!'));
end  
mglSetParam('verbose',0);

% get size of screen (so that we can draw little boxes of different colors)
minX = -1;maxX = 1;
minY = -1;maxY = 1;
sizeX = (maxX-minX)/15;
sizeY = (maxX-minX)/15;

% flush keys
mglGetKeyEvent;

if doTextureDraw
  % try to draw using a texture
  nColors = 1024;blockSize = 12;
  c = 0;colorTexture = [];alpha = 255;
  rowLength = sqrt(nColors);
  colLength = sqrt(nColors);

  for iX = 1:colLength
    thisRow = [];
    for iY = 1:rowLength
      thisRow = [thisRow repmat(c,blockSize,blockSize)];
      c = c+1;
    end
    colorTexture = [colorTexture;thisRow];
  end
  colorTexture = repmat(colorTexture,1,1,3);
  colorTexture(:,:,4) = alpha;
  mglDeepColorTest(colorTexture);
  mglFlush;
  mglGetKeyEvent(inf);
end

if doRectDrawFast
  % draw again, this time with a text string specifying which
  % color entry was being used (this may take some time to render).
  c = 0;
  for centerX = minY:sizeX:maxX
    for centerY = minY:sizeY:maxY
      thisColor = repmat(c/1023,3,1);
      %    thisColor = repmat(c/1023,3,1);
      % draw color square
      mglFillRect(centerX,centerY,[sizeX sizeY],thisColor);
    end
  end
  mglFlush;

  disp(sprintf('(mglTestGammaSet) The second screen shows numeric values for table entries associated with each color value (this labels may look a little funny because of anti-aliasing artifacts, but this is to be expected)'));

  mglGetKeyEvent(inf);
end

if doClearScreen
  for c = 0:255
    thisColor = c/255;
    mglClearScreen(thisColor);
    mglTextDraw(sprintf('%i: %f',c,thisColor),[0 0])
    mglFlush;
    keyEvent = mglGetKeyEvent(5);
    if ~isempty(keyEvent) && keyEvent.keyCode == 54
      break
    end
  end
  mglClearScreen(0);mglFlush;mglClearScreen(0);mglFlush;
end

if doRectDraw
  % draw again, this time with a text string specifying which
  % color entry was being used (this may take some time to render).
  c = 0;
  for centerX = minY:sizeX:maxX
    for centerY = minY:sizeY:maxY
      thisColor = repmat(c/255,3,1);
      %    thisColor = repmat(c/1023,3,1);
      % draw color square
      mglFillRect(centerX,centerY,[sizeX sizeY],thisColor);
      % draw text
      mglTextSet('Helvetica',16,12);
      % get table val and print it
      tableVal = table(c+1,:);
      mglTextDraw(sprintf('%i',c),[centerX centerY],0,-1);
      mglTextDraw(sprintf('%0.2f %0.2f %0.2f',tableVal(1),tableVal(2),tableVal(3)),[centerX centerY],0,1);
      mglFlush
      % draw other buffer
      mglFillRect(centerX,centerY,[sizeX sizeY],thisColor);
      mglTextDraw(sprintf('%i',c),[centerX centerY],0,-1);
      mglTextDraw(sprintf('%0.2f %0.2f %0.2f',tableVal(1),tableVal(2),tableVal(3)),[centerX centerY],0,1);
      mglFlush
      % update counter
      c = c+1;
      % check for esc
      x = mglGetKeyEvent;
      if ~isempty(x) & x.keyCode==54
	mglClose;
	return
      end
    end
  end

  disp(sprintf('(mglTestGammaSet) The second screen shows numeric values for table entries associated with each color value (this labels may look a little funny because of anti-aliasing artifacts, but this is to be expected)'));

  mglGetKeyEvent(inf);
end


if doBitDepthTest
  % now make a table that should show a red screen if 8 bit (actually
  % do to the slightly strange way in which mac is doing interpolation
  % for the tables, shows 4 vertical stripes of red, green, blue and white
  % and should show horizontal stripes of red, green, blue and white for 10 bit
  table = [];
  for i = 1:4:1024
    % some basic colors
    table(i,:)  = [1 0 0];
    table(i+1,:) = [0 1 0];
    table(i+2,:) =   [0 0 1];
    table(i+3,:) = [1 1 1];
  end

  % set the gamma table
  mglSetGammaTable(table);
  setTable = mglGetGammaTable(true);
  setTable = [setTable.redTable ;setTable.greenTable ;setTable.blueTable]';
  if size(setTable,1) == 256
    disp(sprintf('(mglTestGammaSet) Hardware gamma table is only 8 bit'));
  else
    disp(sprintf('(mglTestGammaSet) Hardware gamma table is %i bit',log2(size(setTable,1))));
    % check table
    if isequal(table,setTable)
      disp(sprintf('(mglTestGammaSet) mglGetGammaTable returns what was set correctly'));
    else
      badValues = [];
      for i = 1:size(table,1)
	if ~isequal(table(i,:),setTable(i,:))
	  badValues(end+1) = i;
	end
      end
      disp(sprintf('(mglTestGammaSet) !!! mglGetGammaTable retuns a **difference** from what was actually set. Values are different at table locations [%i:%i] !!!!',min(badValues),max(badValues)));
      if isequal(setTable(min(badValues):end,:),table((min(badValues):end)-1,:))
	disp(sprintf('(mglTestGammaSet) !!! The table returned by the os seems to be offset by 1 color at value %i from what we tried to set !!!',badValues(1)));
      end
    end
  end  

  % now draw the boxes
  mglClearScreen(0);
  c = 0;
  sizeX = (maxX-minX)/31;
  sizeY = (maxX-minX)/31;
  for centerX = minY:sizeX:maxX
    for centerY = minY:sizeY:maxY
      mglFillRect(centerX,centerY,[sizeX sizeY],c/1024);
      c = c+1;
    end
  end
  mglFlush
  disp(sprintf('(mglTestGammaSet) If the last screen shows a red screen you have an 8 bit table. If this last screen shows 4 vertical color stripes, then you have an 8 bit display. If it shows multiple horizontal stripes of red, green, blue and white then you have 10 bit (not yet supported in mac os as of mavericks 10.10.3)'));
  mglGetKeyEvent(inf);
end

mglClose;

