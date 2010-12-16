% testDigPort.m
%
%        $Id:$ 
%      usage: testDigPort(<runlen>,<readPortNum>,<writePortNum>)
%         by: justin gardner
%       date: 06/26/09
%    purpose: Tests digital read/write functions. This will make all of the digital lines on writePortNum (defaults to 1
%             of the NI device turn on and off at 10 Hz. And will readPortNum (defaults to 0) and
%             display that in a graph. (try testing this with an LED in one of the lines of port 1 
%             (put shorter lead of LED into ground)
%
function retval = testDigPort(runlen,readPortNum,writePortNum)

% check arguments
if ~any(nargin == [0 1 2 3])
  help testDigPort
  return
end

% port numbers to use
if nargin < 1,runlen = 5;end
if nargin < 2,readPortNum = 0;end
if nargin < 3,writePortNum = 1;end

% old way of running
%runWithoutMglDigIO(runlen,readPortNum,writePortNum);return

% start mglDigIO
mglDigIO('init',readPortNum,writePortNum);

% read all current events
digin = mglDigIO('digin');

% write out a sequence to turn on and off the signal
blinkFreq = 10;
disp(sprintf('(testDigPort) Writing digout events'));
for outputTime = 0:1/blinkFreq:runlen
  mglDigIO('digout',-outputTime,255);
  mglDigIO('digout',-(outputTime+0.5/blinkFreq),0);
end

% start time
startTime = mglGetSecs;

% wait for however long is called for
disp(sprintf('(testDigPort) Reading for %f seconds',runlen));
mglWaitSecs(runlen);

% read all digital in events
digin = mglDigIO('digin');
if isempty(digin)
  disp(sprintf('(testDigPort) No changes in digin ports found'));
  return
end

% create a time series of what happend
disp(sprintf('(testDigPort) Creating time series',runlen));
timeSpacing = min(diff(fliplr(digin.when)))/5;
time = 0:timeSpacing:runlen;
val = zeros(8,length(time));
for lineNum = 0:7
  events = fliplr(find(digin.line == lineNum));
  numEvents(lineNum+1) = length(events);
  for i = 1:length(events)
    val(lineNum+1,find(time>=digin.when(events(i))-startTime)) = digin.type(events(i));
  end
  % get frequency
  e = getEdges(val(lineNum+1,:),0.5);
  freq(lineNum+1) =e.n/runlen;
end

% and plot
c = 'bgrcmykw';clf;
% display input
for i = 1:8
  plot(time,val(i,:)+(i-1)*2,c(i));
  disp(sprintf('(testDigPort) %i events found on line %i. Estimated freq=%0.2fHz',numEvents(i),i,freq(i)));
  hold on
end
set(gca,'Color',[0.8 0.8 0.8]);
xlabel('Time (sec)');ylabel('Line value (0 or 1)');
legend('0','1','2','3','4','5','6','7','Location','WestOutside');
axis([0 time(end) -0.1 15.1]);
set(gca,'YTick',0:15);
set(gca,'YTickLabel',{'0' '1' '0' '1' '0' '1' '0' '1' '0' '1' '0' '1' '0' '1' '0' '1'});
title(sprintf('readDigPort from Dev1/port%i',readPortNum));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    runWithoutMglDigIO    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is the old code that does not use mglDigIO
function runWithoutMglDigIO(runlen,readPortNum,writePortNum)

% read/write once to open ports if necessary
readDigPort(readPortNum);
writeDigPort(0,writePortNum);

% get the start time
startTime = mglGetSecs;
blinkTime = startTime;
readTime = startTime;

% blink frequency
blinkFreq = 10;

% starting state of LED
blinkState = 1;

% frequency of read
readFreq = 100;

% read buffer
readBuffer = zeros(1,readFreq*runlen);
readBufferTime = zeros(1,readFreq*runlen);
iReadBuffer = 1;

% buffers for saving how long it takes to run read/writeDigPort
writeDigPortTime = zeros(1,blinkFreq*runlen);
iWriteDigPortTime = 1;
readDigPortTime = zeros(1,readFreq*runlen);
iReadDigPortTime = 1;

% display starting message
disp(sprintf('(testDigPort) Testing for %0.2f seconds',runlen));

while (mglGetSecs(startTime) < runlen)
  % set port 1
  if mglGetSecs(blinkTime) > (1/blinkFreq)
    if blinkState == 1
      tic
      % turn off LED
      writeDigPort(0);
      % keep track of how long each call takes
      writeDigPortTime(iWriteDigPortTime) = toc;
      iWriteDigPortTime = iWriteDigPortTime+1;
      blinkState = 0;
    else
      % turn off LED
      tic
      writeDigPort(255);
      % keep track of how long each call takes
      writeDigPortTime(iWriteDigPortTime) = toc;
      iWriteDigPortTime = iWriteDigPortTime+1;
      blinkState = 1;
    end
    % update time
    blinkTime = mglGetSecs;
  end
  % read from port 2
  if mglGetSecs(readTime) > (1/readFreq)
    tic;
    % read the digital port
    readBuffer(iReadBuffer) = readDigPort;
    % keep track of how long each call takes
    readDigPortTime(iReadDigPortTime) = toc;
    iReadDigPortTime = iReadDigPortTime+1;
    % keep the time each read was done
    readBufferTime(iReadBuffer) = mglGetSecs(startTime);
    iReadBuffer = iReadBuffer+1;
    % update time
    readTime = mglGetSecs;
  end
  
end

c = 'bgrcmykw';clf;
% display input
for i = 1:8
  thisline = bitshift(bitand(readBuffer,(2^(i-1))),-(i-1));
  plot(readBufferTime(1:iReadBuffer-1),thisline(1:iReadBuffer-1)+2*(i-1),c(i));
  hold on
end
set(gca,'Color',[0.8 0.8 0.8]);
xlabel('Time (sec)');ylabel('Line value (0 or 1)');
legend('0','1','2','3','4','5','6','7','Location','WestOutside');
axis([0 readBufferTime(iReadBuffer-1) -0.1 15.1]);
set(gca,'YTick',0:15);
set(gca,'YTickLabel',{'0' '1' '0' '1' '0' '1' '0' '1' '0' '1' '0' '1' '0' '1' '0' '1'});
title(sprintf('readDigPort from Dev1/port%i',readPortNum));

% display times that it takes for read and write
readDigPortTime = readDigPortTime(1:iReadDigPortTime-1);
disp(sprintf('(testDigPort) readDirPort (port=%i) run times (min: %f median: %f mean: %f max: %f ms)',readPortNum,1000*min(readDigPortTime),1000*median(readDigPortTime),1000*mean(readDigPortTime),1000*max(readDigPortTime)));
writeDigPortTime = writeDigPortTime(1:iWriteDigPortTime-1);
disp(sprintf('(testDigPort) writeDirPort (port=%i) run times (min: %f median: %f mean: %f max: %f ms)',writePortNum,1000*min(writeDigPortTime),1000*median(writeDigPortTime),1000*mean(writeDigPortTime),1000*max(writeDigPortTime)));
