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
function [ackTime, drawTimes, frameTimes] = mglMetalRepeatingFlicker(nFrames, randomSeed)

if nargin < 2
    randomSeed = 0;
end

global mgl
mglSocketWrite(mgl.s, mgl.command.mglRepeatFlicker);
ackTime = mglSocketRead(mgl.s, 'double');
mglSocketWrite(mgl.s, uint32(nFrames));
mglSocketWrite(mgl.s, uint32(randomSeed));
drawAndFrameTimes = mglSocketRead(mgl.s, 'double', 2 * nFrames);
drawTimes = drawAndFrameTimes(1:2:end);
frameTimes = drawAndFrameTimes(2:2:end);
