% testDigPort.m
%
%        $Id:$ 
%      usage: testDigPort()
%         by: justin gardner
%       date: 06/26/09
%    purpose: Tests digital read/write functions. This will make all of the digital lines on port 1
%             of the NI device turn on and off at 10 Hz. And will read digital port 2 and
%             display that in a graph. (try testing this with an LED in one of the lines of port 1 
%             (put shorter lead of LED into ground)
%
function retval = testDigPort()

% check arguments
if ~any(nargin == [0])
  help testDigPort
  return
end

% port numbers to use
readPortNum = 2;
writePortNum = 1;

% read/write once to open ports if necessary
readDigPort(readPortNum);
writeDigPort(0,writePortNum);

% length of time to test for 
runlen = 5;

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

c = 'bgrcmykw';
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
