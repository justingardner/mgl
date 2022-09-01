% mglMetalRepeatingQuads.m
%
%        $Id$
%      usage: [ackTime, drawTimes, frameTimes] = mglMetalRepeatingQuads(nFrames, nQuads, randomSeed)
%         by: Benjamin heasly
%       date: 06/17/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Send one command that causes multiple frames of random quads.
%      usage: [ackTime, drawTimes, frameTimes] = mglMetalRepeatingQuads(nFrames, nQuads, randomSeed)
%     inputs: nFrames -- how long in frames the repeated quads should last
%             nQuads -- how many quads to draw per frame.
%             randomSeed -- integer seed for Metal to use when initializing
%                           the sequence of flickering frames.
%
%             This one command will cause a sequence of nFrames to be
%             drawn, each frame will have nQuads quads drawn in it.
%
%             Currently the quads are random and not able to be controlled
%             as they are with mglQuad.  The quads will have:
%               - vertex x- and y-coordinates chosen uniformly from -1 to 1
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
% % Cycle through several frames of random quads.
% mglOpen();
% [ackTime, drawTimes, frameTimes] = mglMetalRepeatingQuads(300, 250);
%
% % Plot how long each frame took.
% frameStarts = frameTimes(1:end-1);
% frameDurations = frameTimes(2:end) - frameStarts;
% drawDurations = drawTimes(2:end) - frameStarts;
% plot(2:300, 1000 * drawDurations, 'b.', 2:300, 1000 * frameDurations, 'r.');
% legend('draw time', 'frame time');
function [ackTime, drawTimes, frameTimes] = mglMetalRepeatingQuads(nFrames, nQuads, randomSeed, socketInfo)

if nargin < 2
    nQuads = 1;
end

if nargin < 3
    randomSeed = 0;
end

if nargin < 4 || isempty(socketInfo)
    global mgl;
    socketInfo = mgl.activeSockets;
end

mglSocketWrite(socketInfo, socketInfo(1).command.mglRepeatQuads);
ackTime = mglSocketRead(socketInfo, 'double');
mglSocketWrite(socketInfo, uint32(nFrames));
mglSocketWrite(socketInfo, uint32(nQuads));
mglSocketWrite(socketInfo, uint32(randomSeed));
drawAndFrameTimes = mglSocketRead(socketInfo, 'double', 2 * nFrames);
drawTimes = drawAndFrameTimes(1:2:end);
frameTimes = drawAndFrameTimes(2:2:end);
