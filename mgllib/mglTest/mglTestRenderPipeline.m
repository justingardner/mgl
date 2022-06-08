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
%
function [] = mglTestRenderPipeline(varargin)

% number of test
d.numTests = 2;

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
  d.timeVec = zeros(6,d.numFrames);
  % run test
  if testNum == 1
    d = testFlush(d);
  elseif testNum == 2
    d = testQuads(d);
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

getArgs(args,{'screenNum=1','runTests=[]','testLen=5','dropThreshold=0.1','numQuads=500','initWaitTime=1'});

% set some parameters
d.screenNum = screenNum;
d.runTests = runTests;
d.testLen = testLen;
d.dropThreshold = dropThreshold;
d.numQuads = numQuads;
d.initWaitTime = initWaitTime;

% set number of test
if isempty(runTests),d.runTests = 1:d.numTests;end

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
  % get time after draw commands (even though there are none in this test)
  d.timeVec(2,iFrame) = mglGetSecs;
  d.timeVec(3,iFrame) = mglGetSecs;
  % and flush
  [d.timeVec(4,iFrame) d.timeVec(5,iFrame)] = mglFlush;
  % and record time
  d.timeVec(6,iFrame) = mglGetSecs;
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
  [d.timeVec(2,iFrame) d.timeVec(3,iFrame)] = mglQuad(2*rand(4,d.numQuads)-1,2*rand(4,d.numQuads)-1,rand(3,d.numQuads));
  % and flush
  [d.timeVec(4,iFrame) d.timeVec(5,iFrame)] = mglFlush;
  % and record time
  d.timeVec(6,iFrame) = mglGetSecs;
end

disppercent(inf);

%%%%%%%%%%%%%%%%
% dispTimeTest
%%%%%%%%%%%%%%%%
function dispTimeTest(d)

mlrSmartfig('mglTestRenderPipeline','reuse');clf

% plot the data
plot(1000*(d.timeVec(2,:)-d.timeVec(1,:)),'k.'); hold on
plot(1000*(d.timeVec(3,:)-d.timeVec(1,:)),'g.');
plot(1000*(d.timeVec(4,:)-d.timeVec(1,:)),'b.');
plot(1000*(d.timeVec(5,:)-d.timeVec(1,:)),'bo');
plot(1000*(d.timeVec(end,:)-d.timeVec(1,:)),'r.');
hline(1000/d.frameRate,'r');
hline((1+d.dropThreshold)*(1000/d.frameRate),'r:');
xlabel('Frame number');
ylabel('Time elasped (msec)');

% count number of frames over the expected amount of time
dropFrames = sum((d.timeVec(end,:)-d.timeVec(1,:)) > ((1+d.dropThreshold)/d.frameRate));
title(sprintf('(%s) %i fames took longer than %0.1f%% than expected at %i Hz',d.testName,dropFrames,100*d.dropThreshold,d.frameRate));

legend('Draw commands Ack','Draw commands Processed','Flush Ack','Flush processed','End of frame loop');
