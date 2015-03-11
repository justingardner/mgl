% mglTestGammaSet.m
%
%        $Id:$ 
%      usage: mglTestGammaSet()
%         by: justin gardner
%       date: 03/06/15
%    purpose: Test gamma table setting 
%
function retval = mglTestGammaSet(dispNum)

% check arguments
if ~any(nargin == [0 1])
  help mglTestSetGamma
  return
end

if nargin < 1
  dispNum = [];
end
disp(sprintf('(mglTestGammaSet) This first screen should appear as horizontal bars with grays on top and RGBCMYK values on bottom'));

% make a funky table
for i = 1:16:256
  % some basic colors
  table(i,:)  = [0 0 0];
  table(i+1,:) = [1 1 1];
  table(i+2,:) =   [1 0 0];
  table(i+3,:) = [0 1 0];
  table(i+4,:) = [0 0 1];
  table(i+5,:) =  [0 1 1];
  table(i+6,:) = [1 0 1];
  table(i+7,:) = [1 1 0];

  % some grays
  table(i+8,:) =  [1 1 1]/8;
  table(i+9,:) =  [2 2 2]/8;
  table(i+10,:) = [3 3 3 ]/8;
  table(i+11,:) =  [4 4 4]/8;
  table(i+12,:) = [5 5 5]/8;
  table(i+13,:) = [6 6 6]/8;
  table(i+14,:) = [7 7 7]/8;
  table(i+15,:) = [8 8 8]/8;
end

% open window, set table
mglOpen(dispNum);
mglSetGammaTable(table);
setTable = mglGetGammaTable;
setTable = [setTable.redTable ;setTable.greenTable ;setTable.blueTable]';
if isequal(table,setTable)
  disp(sprintf('(mglTestGammaSet) mglGetGammaTable returns what was set correctly'));
else
  disp(sprintf('(mglTestGammaSet) !!! mglGetGammaTable retuns a **difference** from what was actually set !!!!'));
end  

% get size of screen (so that we can draw little boxes of different colors)
minX = -1;maxX = 1;
minY = -1;maxY = 1;
sizeX = (maxX-minX)/15;
sizeY = (maxX-minX)/15;

% clear screen and draw boxes of different colors
mglClearScreen(0);
c = 0;
for centerX = minY:sizeX:maxX
  for centerY = minY:sizeY:maxY
    mglFillRect(centerX,centerY,[sizeX sizeY],c/255);
    c = c+1;
  end
end
mglFlush

% draw again, this time with a text string specifying which
% color entry was being used (this may take some time to render).
c = 0;
for centerX = minY:sizeX:maxX
  for centerY = minY:sizeY:maxY
    mglFillRect(centerX,centerY,[sizeX sizeY],c/255);
    mglTextSet('Helvetica',16,12);
    mglTextDraw(sprintf('%i',c),[centerX centerY]);
    c = c+1;
  end
end
mglFlush

disp(sprintf('(mglTestGammaSet) The second screen shows numeric values for table entries associated with each color value (this labels may look a little funny because of anti-aliasing artifacts, but this is to be expected)'));

mglWaitSecs(5);

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
mglWaitSecs(5);

mglClose;

