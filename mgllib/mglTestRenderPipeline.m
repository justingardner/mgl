% mglTestRenderPipeline.m
%
%      usage: mglTestRenderPipeline()
%         by: justin gardner
%       date: 06/08/2022
%    purpose: Function to test mgl rendering pipeline with progressively
%             more in the pipeline to see when there is a failure.
%      usage: mglTestRenderPipeline
%
%       args: screenNum=0, sets the screen number to run on
%             runTests=[], an int array with numbers for which test to run
%             testLen=5, sets the length in seconds of the tests
%             photoDiodeTest=0, sets whether to add a flickering square to
%             the dislay to test with a photodiode
%             photoDiodeRect=[-1 -1 0.5 0.5] sets the [x y width height] in
%             the default coordinates (-1, -1 in bottom left corner)
%             photoDiodeColor=[1 1 1] sets the color that the square will
%             be shown at every other frame (will show black in the other
%             frames)
%
%             some calls for specific tests
%
%             % just do a flush
%             mglTestRenderPipeline('runTests=1');
%
%             % draw 250 quads each frame
%             mglTestRenderPipeline('runTests=2','n=250');
%
%             % draw 25000 points each frame
%             mglTestRenderPipeline('runTests=3','n=10000');
%
%             % disaply a full size texture map (or set bltSize to [n k]
%             for a corresponding size bitmap)
%             mglTestRenderPipeline('runTests=4','bltSize=[]');
%
%             % Clear screen to a random color
%             mglTestRenderPipeline('runTests=5');
%
function [] = mglTestRenderPipeline(varargin)

% number of test
d.numTests = 5;

% arguments
d = parseArgs(varargin,d);

% save values in structrue

% open the screen
mglOpen(d.screenNum);
mglWaitSecs(d.initWaitTime);

% and get screen parameters
d.frameRate = mglGetParam('frameRate');
d.numFrames = d.testLen * d.frameRate;

% run through each test
for testNum = d.runTests
  % initialize time vector
  d.timeVec = zeros(7,d.numFrames);
  % flush the screen to get everything started
  mglFlush;mglFlush;mglFlush;mglFlush;
  % run test
  if testNum == 1
    d = testFlush(d);
  elseif testNum == 2
    d = testQuads(d);
  elseif testNum == 3
    d = testPoints(d);
  elseif testNum == 4
    d = testBlt(d);
  elseif testNum == 5
    d = testClearScreen(d);
  end
  % display output
  dispTimeTest(d);
end

% close screen
mglClose;

%%%%%%%%%%%%%%
% parseArgs
%%%%%%%%%%%%%%
function d = parseArgs(args,d)

getArgs(args,{'screenNum=1','runTests=[]','testLen=5','dropThreshold=0.1','numQuads=250','numPoints=10000','bltSize=[]','numBlt=30','initWaitTime=1','n=[]','photoDiodeTest=0','photoDiodeRect=[-1 -1 0.5 0.5]','photoDiodeColor=[1 1 1]'});

% set some parameters
d.screenNum = screenNum;
d.runTests = runTests;
d.testLen = testLen;
d.dropThreshold = dropThreshold;
d.numQuads = numQuads;
d.numPoints = numPoints;
d.initWaitTime = initWaitTime;
d.numBlt = numBlt;
d.bltSize = bltSize;
if ~isempty(n)
  numQuads = n;
  numPoints = n;
end

% set number of test
if isempty(runTests),d.runTests = 1:d.numTests;end

d.photoDiodeTest = photoDiodeTest;
d.photoDiodeRect = photoDiodeRect;
d.photoDiodeColor = photoDiodeColor;
d.photoDiodeX = [d.photoDiodeRect(1) d.photoDiodeRect(1) d.photoDiodeRect(1)+d.photoDiodeRect(3) d.photoDiodeRect(1)+d.photoDiodeRect(3)]';
d.photoDiodeY = [d.photoDiodeRect(2) d.photoDiodeRect(2)+d.photoDiodeRect(4) d.photoDiodeRect(2)+d.photoDiodeRect(4) d.photoDiodeRect(2)]';
%%%%%%%%%%%%%%
% testFlush
%%%%%%%%%%%%%%
function d = testFlush(d)

d.testName = 'Flush test';
disppercent(-inf,sprintf('(mglTestRenderPipeline) Testing flush. Please wait %0.1f secs',d.testLen));

% do the appropriate number of flush
for iFrame = 1:d.numFrames
  % get start time of frame
  d.timeVec(1,iFrame) = mglGetSecs;
  % get time before and after draw commands (even though there are none in this test)
  d.timeVec(2,iFrame) = mglGetSecs;
  d.timeVec(3,iFrame) = mglGetSecs;
  d.timeVec(4,iFrame) = mglGetSecs;
  % draw photoDiodeRect if need be
  if d.photoDiodeTest
    if iseven(iFrame), photoDiodeColor = d.photoDiodeColor; else photoDiodeColor = [0 0 0]; end
    mglQuad(d.photoDiodeX,d.photoDiodeY,photoDiodeColor);
  end
  
  % and flush
  results = mglFlush();
  d.timeVec(5,iFrame) = results.ackTime;
  d.timeVec(6,iFrame) = results.processedTime;
  % and record time
  d.timeVec(7,iFrame) = mglGetSecs;
end

disppercent(inf);

%%%%%%%%%%%%%%
% testQuads
%%%%%%%%%%%%%%
function d = testQuads(d)

d.testName = sprintf('%i Quads test',d.numQuads);
disppercent(-inf,sprintf('(mglTestRenderPipeline) Testing quads. Please wait %0.1f secs',d.testLen));

% do the appropriate number of flush
for iFrame = 1:d.numFrames
  % get start time of frame
  d.timeVec(1,iFrame) = mglGetSecs;
  % draw quads
  drawResults = mglQuad(2*rand(4,d.numQuads)-1,2*rand(4,d.numQuads)-1,rand(3,d.numQuads));
  d.timeVec(3,iFrame) = drawResults.ackTime;
  d.timeVec(4,iFrame) = drawResults.processedTime;
  d.timeVec(2,iFrame) = drawResults.setupTime;
  % draw photoDiodeRect if need be
  if d.photoDiodeTest
    if iseven(iFrame), photoDiodeColor = d.photoDiodeColor; else photoDiodeColor = [0 0 0]; end
    mglQuad(d.photoDiodeX,d.photoDiodeY,photoDiodeColor);
  end
  % and flush
  results = mglFlush();
  d.timeVec(5,iFrame) = results.ackTime;
  d.timeVec(6,iFrame) = results.processedTime;
  % and record time
  d.timeVec(7,iFrame) = mglGetSecs;
end

disppercent(inf);

%%%%%%%%%%%%%%
% testDots
%%%%%%%%%%%%%%
function d = testPoints(d)

d.testName = sprintf('%i dots test',d.numPoints);
disppercent(-inf,sprintf('(mglTestRenderPipeline) Testing dots. Please wait %0.1f secs',d.testLen));

% do the appropriate number of flush
for iFrame = 1:d.numFrames
  % get start time of frame
  d.timeVec(1,iFrame) = mglGetSecs;
  % draw dots
  drawResults = mglPoints2c(2*rand(1,d.numPoints)-1,2*rand(1,d.numPoints)-1,0.005*ones(d.numPoints,2),rand(1,d.numPoints),rand(1,d.numPoints),rand(1,d.numPoints));
  d.timeVec(3,iFrame) = drawResults.ackTime;
  d.timeVec(4,iFrame) = drawResults.processedTime;
  d.timeVec(2,iFrame) = drawResults.setupTime;
  % draw photoDiodeRect if need be
  if d.photoDiodeTest
    if iseven(iFrame), photoDiodeColor = d.photoDiodeColor; else photoDiodeColor = [0 0 0]; end
    mglQuad(d.photoDiodeX,d.photoDiodeY,photoDiodeColor);
  end
  % and flush
  results = mglFlush();
  d.timeVec(5,iFrame) = results.ackTime;
  d.timeVec(6,iFrame) = results.processedTime;
  % and record time
  d.timeVec(7,iFrame) = mglGetSecs;
end

disppercent(inf);

%%%%%%%%%%%%%%
% testBlt
%%%%%%%%%%%%%%
function d = testBlt(d)

% set to a full screen size texture if bltSize is empty
if isempty(d.bltSize) || length(d.bltSize) ~= 2
  d.bltSize = [mglGetParam('screenWidth') mglGetParam('screenHeight')];
  disp(sprintf('(mglTestRenderPipeline) Using full size Blt: %i x %i',d.bltSize(1),d.bltSize(2)));
end

% create the texture
disppercent(-inf,sprintf('(mglTestRenderPipeline) Making %i test textures',d.numBlt));
for iBlt = 1:d.numBlt
  tex(iBlt) = mglCreateTexture(rand(d.bltSize(1),d.bltSize(2),4));
end
disppercent(inf);

d.testName = sprintf('%ix%i n=%i Blt test',d.bltSize(1),d.bltSize(2),d.numBlt);
disppercent(-inf,sprintf('(mglTestRenderPipeline) Testing %s. Please wait %0.1f secs',d.testName,d.testLen));

% do the appropriate number of flush
for iFrame = 1:d.numFrames
  % get start time of frame
  d.timeVec(1,iFrame) = mglGetSecs;
  % draw texture
  drawResults = mglBltTexture(tex(mod(iFrame,d.numBlt)+1),[0 0 2 2]);
  d.timeVec(3,iFrame) = drawResults.ackTime;
  d.timeVec(4,iFrame) = drawResults.processedTime;
  d.timeVec(2,iFrame) = drawResults.setupTime;
  % draw photoDiodeRect if need be
  if d.photoDiodeTest
    if iseven(iFrame), photoDiodeColor = d.photoDiodeColor; else photoDiodeColor = [0 0 0]; end
    mglQuad(d.photoDiodeX,d.photoDiodeY,photoDiodeColor);
  end
  % and flush
  results = mglFlush();
  d.timeVec(5,iFrame) = results.ackTime;
  d.timeVec(6,iFrame) = results.processedTime;
  % and record time
  d.timeVec(7,iFrame) = mglGetSecs;
end

disppercent(inf);

%%%%%%%%%%%%%%
% testClearScreen
%%%%%%%%%%%%%%
function d = testClearScreen(d)

d.testName = sprintf('Clear screen test');
disppercent(-inf,sprintf('(mglTestRenderPipeline) Testing clear screen. Please wait %0.1f secs',d.testLen));

% do the appropriate number of flush
for iFrame = 1:d.numFrames
  % get start time of frame
  d.timeVec(1,iFrame) = mglGetSecs;
  % set the clear color
  drawResults = mglClearScreen(rand(1,3));
  d.timeVec(3,iFrame) = drawResults.ackTime;
  d.timeVec(4,iFrame) = drawResults.processedTime;
  d.timeVec(2,iFrame) = drawResults.setupTime;
  % draw photoDiodeRect if need be
  if d.photoDiodeTest
    if iseven(iFrame), photoDiodeColor = d.photoDiodeColor; else photoDiodeColor = [0 0 0]; end
    mglQuad(d.photoDiodeX,d.photoDiodeY,photoDiodeColor);
  end
  % and flush
  results = mglFlush();
  d.timeVec(5,iFrame) = results.ackTime;
  d.timeVec(6,iFrame) = results.processedTime;
  % and record time
  d.timeVec(7,iFrame) = mglGetSecs;
end

disppercent(inf);

%%%%%%%%%%%%%%%%
% dispTimeTest
%%%%%%%%%%%%%%%%
function dispTimeTest(d)

figure;

% plot the data
plot(1000*(d.timeVec(2,:)-d.timeVec(1,:)),'c.'); hold on
plot(1000*(d.timeVec(3,:)-d.timeVec(1,:)),'k.');
plot(1000*(d.timeVec(4,:)-d.timeVec(1,:)),'g.');
plot(1000*(d.timeVec(5,:)-d.timeVec(1,:)),'b.');
plot(1000*(d.timeVec(6,:)-d.timeVec(1,:)),'bo');
plot(1000*(d.timeVec(end,:)-d.timeVec(1,:)),'r.');
hline(1000/d.frameRate,'r');
hline((1+d.dropThreshold)*(1000/d.frameRate),'r:');
xlabel('Frame number');
ylabel('Time elasped (msec)');
YLim = get(gca,'YLim');
YLim(1) = 0;
set(gca,'YLim',YLim);

% count number of frames over the expected amount of time
dropFrames = sum((d.timeVec(end,:)-d.timeVec(1,:)) > ((1+d.dropThreshold)/d.frameRate));
title(sprintf('(%s) %i fames took longer than %0.1f%% than expected at %i Hz',d.testName,dropFrames,100*d.dropThreshold,d.frameRate));

legend('Matlab setup','Draw commands Ack','Draw commands Processed','Flush Ack','Flush processed','End of frame loop');
