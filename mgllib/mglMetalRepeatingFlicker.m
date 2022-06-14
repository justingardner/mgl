% mglMetalRepeatingFlicker.m
%
%        $Id$
%      usage: [ackTime, processedTimes] = mglMetalRepeatingFlicker(nFrames, randomSeed)
%         by: Benjamin heasly
%       date: 06/14/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Send one command that causes multiple frames of random flicker.
%      usage: [ackTime, processedTimes] = mglMetalRepeatingFlicker(nFrames, randomSeed)
%     inputs: nFrames -- how long in frames the flicker should last
%             randomSeed -- integer seed for Metal to use when initializing
%                           the sequence of flickering frames
%
%             This will return an ackTime that represents when the command
%             was received but before the flicker starts.
%             It will also return an array of nFrames processedTimes, each
%             of which represents the time when one frame was completed,
%             and the next frame was about to begin.
%
% % Flicker for 100 frames:
% mglOpen();
% [ackTime, processedTimes] = mglMetalRepeatingFlicker(100, 42);
% disp(1000 * diff(processedTimes))
%
function [ackTime, processedTimes] = mglMetalRepeatingFlicker(nFrames, randomSeed)

if nargin < 2
    randomSeed = 0;
end

global mgl
mglSocketWrite(mgl.s, mgl.command.mglRepeatFlicker);
ackTime = mglSocketRead(mgl.s, 'double');
mglSocketWrite(mgl.s, uint32(nFrames));
mglSocketWrite(mgl.s, uint32(randomSeed));
processedTimes = mglSocketRead(mgl.s, 'double', nFrames);
