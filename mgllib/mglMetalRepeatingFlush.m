% mglMetalRepeatingFlush.m
%
%        $Id$
%      usage: [ackTime, drawTimes, frameTimes] = mglMetalRepeatingFlush(nFrames)
%         by: Benjamin heasly
%       date: 06/17/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Send one command that causes multiple flushes in a row.
%      usage: [ackTime, drawTimes, frameTimes] = mglMetalRepeatingFlush(nFrames)
%     inputs: nFrames -- how long in frames the repeated flushes should last
%
%             This one command will cause a sequence of nFrames to be
%             flushed in a row, with nothing drawn on any frame.  This
%             might be useful in establishing a baseline for timing tests.
%
%             This will return a single ackTime for when the command was
%             received to begin the sequence of frames.
%
%             It will also return an array of nFrames drawTimes,
%             indicating when drawing was completed during each frame, and
%             an array of nFrames frameTimes indicating when each frame was
%             completed.
%
% % Cycle through several blank frames.
% mglOpen();
% [ackTime, drawTimes, frameTimes] = mglMetalRepeatingFlush(300);
%
% % Plot how long each frame took.
% frameStarts = frameTimes(1:end-1);
% frameDurations = frameTimes(2:end) - frameStarts;
% drawDurations = drawTimes(2:end) - frameStarts;
% plot(2:300, 1000 * drawDurations, 'b.', 2:300, 1000 * frameDurations, 'r.');
% legend('draw time', 'frame time');
function [ackTime, drawTimes, frameTimes] = mglMetalRepeatingFlush(nFrames, socketInfo)

if nargin < 2 || isempty(socketInfo)
    global mgl;
    socketInfo = mgl.activeSockets;
end

mglSocketWrite(socketInfo, socketInfo(1).command.mglRepeatFlush);
ackTime = mglSocketRead(socketInfo, 'double');
mglSocketWrite(socketInfo, uint32(nFrames));

drawTimes = zeros(1, nFrames);
frameTimes = zeros(1, nFrames);
for ii = 1:nFrames
    drawTimes(ii) = mglSocketRead(socketInfo, 'double');
    results = mglReadCommandResults(socketInfo);
    frameTimes(ii) = results.processedTime;
end
