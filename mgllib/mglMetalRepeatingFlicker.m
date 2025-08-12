% mglMetalRepeatingFlicker.m
%
%        $Id$
%      usage: [ackTime, drawTimes, frameTimes] = mglMetalRepeatingFlicker(nFrames, randomSeed)
%         by: Benjamin heasly
%       date: 06/14/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Send one command that causes multiple frames of random flicker.
%      usage: [ackTime, drawTimes, frameTimes] = mglMetalRepeatingFlicker(nFrames, randomSeed)
%     inputs: nFrames -- how long in frames the flicker should last
%             randomSeed -- integer seed for Metal to use when initializing
%                           the sequence of flickering frames.
%
%             This will return a single ackTime for when the command was
%             received to begin the sequence of frames.
%
%             It will also return an array of nFrames drawTimes,
%             indicating when drawing was completed during each frame, and
%             an array of nFrames frameTimes indicating when each frame was
%             completed.
%
% % Flicker for 100 frames pseudo-random sequence with seed 42:
% mglOpen();
% [ackTime, drawTimes, frameTimes] = mglMetalRepeatingFlicker(100, 42);
%
% % Plot how long each frame took.
% frameStarts = frameTimes(1:end-1);
% frameDurations = frameTimes(2:end) - frameStarts;
% drawDurations = drawTimes(2:end) - frameStarts;
% plot(2:100, 1000 * drawDurations, 'b.', 2:100, 1000 * frameDurations, 'r.');
% legend('draw time', 'frame time');
%
function [ackTime, drawTimes, frameTimes] = mglMetalRepeatingFlicker(nFrames, randomSeed, socketInfo)

if nargin < 2
    randomSeed = 0;
end

if nargin < 3 || isempty(socketInfo)
    global mgl;
    socketInfo = mgl.activeSockets;
end

mglSocketWrite(socketInfo, socketInfo(1).command.mglRepeatFlicker);
ackTime = mglSocketRead(socketInfo, 'double');
mglSocketWrite(socketInfo, uint32(nFrames));
mglSocketWrite(socketInfo, uint32(randomSeed));

drawTimes = zeros(1, nFrames);
frameTimes = zeros(1, nFrames);
for ii = 1:nFrames
    drawTimes(ii) = mglSocketRead(socketInfo, 'double');
    results = mglReadCommandResults(socketInfo);
    frameTimes(ii) = results.processedTime;
end
