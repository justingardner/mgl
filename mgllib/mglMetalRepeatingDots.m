% mglMetalRepeatingDots.m
%
%        $Id$
%      usage: [ackTime, drawTimes, frameTimes] = mglMetalRepeatingDots(nFrames, nDots, randomSeed)
%         by: Benjamin heasly
%       date: 06/17/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Send one command that causes multiple frames of random dots.
%      usage: [ackTime, drawTimes, frameTimes] = mglMetalRepeatingDots(nFrames, nDots, randomSeed)
%     inputs: nFrames -- how long in frames the repeated dots should last
%             nDots -- how many dots to draw per frame.
%             randomSeed -- integer seed for Metal to use when initializing
%                           the sequence of flickering frames.
%
%             This one command will cause a sequence of nFrames to be
%             drawn, each frame will have nQuads dots drawn in it.
%
%             Currently the dots are random and not able to be controlled
%             as they are with mglMetalDots or similar commands.  The dots
%             will have:
%               - fixed size of 1 pixel
%               - x- and y-coordinates chosen uniformly from -1 to 1
%               - RGB color values chosen uniformly from 0 to 1
%
%             This will return a single ackTime for when the command was
%             received to begin the sequence of frames.
%
%             It will also return an array of nFrames drawTimes,
%             indicating when drawing was completed during each frame, and
%             an array of nFrames frameTimes indicating when each frame was
%             completed.
%
% % Cycle through several frames of random dots.
% mglOpen();
% [ackTime, drawTimes, frameTimes] = mglMetalRepeatingDots(300, 10000);
%
% % Plot how long each frame took.
% frameStarts = frameTimes(1:end-1);
% frameDurations = frameTimes(2:end) - frameStarts;
% drawDurations = drawTimes(2:end) - frameStarts;
% plot(2:300, 1000 * drawDurations, 'b.', 2:300, 1000 * frameDurations, 'r.');
% legend('draw time', 'frame time');
function [ackTime, drawTimes, frameTimes] = mglMetalRepeatingDots(nFrames, nDots, randomSeed, socketInfo)

if nargin < 2
    nDots = 100;
end

if nargin < 3
    randomSeed = 0;
end

if nargin < 4 || isempty(socketInfo)
    global mgl;
    socketInfo = mgl.activeSockets;
end

mglSocketWrite(socketInfo, socketInfo(1).command.mglRepeatDots);
ackTime = mglSocketRead(socketInfo, 'double');
mglSocketWrite(socketInfo, uint32(nFrames));
mglSocketWrite(socketInfo, uint32(nDots));
mglSocketWrite(socketInfo, uint32(randomSeed));

drawTimes = zeros(1, nFrames);
frameTimes = zeros(1, nFrames);
for ii = 1:nFrames
    drawTimes(ii) = mglSocketRead(socketInfo, 'double');
    results = mglReadCommandResults(socketInfo);
    frameTimes(ii) = results.processedTime;
end
