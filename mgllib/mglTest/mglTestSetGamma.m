% mglTestSetGamma.m
%
%        $Id:$ 
%      usage: mglTestSetGamma()
%         by: justin gardner
%       date: 03/06/15
%    purpose: 
%
function retval = mglTestSetGamma(dispNum)

% check arguments
if ~any(nargin == [0 1])
  help mglTestSetGamma
  return
end

if nargin < 1
  dispNum = [];
end


% make a funky table
for i = 1:16:256
  % some basic colors
  table(i,:) =   [1 0 0];
  table(i+1,:) = [0 1 0];
  table(i+2,:) = [0 0 1];
  table(i+3,:) =  [0 1 1];
  table(i+4,:) = [1 0 1];
  table(i+5,:) = [1 1 0];
  table(i+6,:) = [0 0 0];
  table(i+7,:) = [1 1 1];

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


mglOpen(dispNum);
mglSetGammaTable(table);

minX = -1;maxX = 1;
minY = -1;maxY = 1;
sizeX = (maxX-minX)/15;
sizeY = (maxX-minX)/15;

mglClearScreen(0);
c = 0;
for centerX = minY:sizeX:maxX
  for centerY = minY:sizeY:maxY
    mglFillRect(centerX,centerY,[sizeX sizeY],c/255);
    c = c+1;
  end
end
mglFlush

% check gamma table
t = mglGetGammaTable;
for i = 1:256
  setTable(i,1) = t.redTable(i);
  setTable(i,2) = t.greenTable(i);
  setTable(i,3) = t.blueTable(i);
end
disp(sprintf('(mglTestSetGamma) mglGetGammaTable == what we set? %i',isequal(setTable,table)));
mglWaitSecs(5);
mglClose;
