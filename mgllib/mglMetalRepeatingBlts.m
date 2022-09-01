% mglMetalRepeatingBlts.m
%
%        $Id$
%      usage: [ackTime, drawTimes, frameTimes] = mglMetalRepeatingBlts(nFrames)
%         by: Benjamin heasly
%       date: 06/15/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Send one command that causes multiple texture blts.
%      usage: [ackTime, drawTimes, frameTimes] = mglMetalRepeatingBlts(nFrames)
%     inputs: nFrames -- how long in frames the repeated blts should last
%
%             All of the textures that were previously created with
%             mglCreateTexture will be blt-ed in turn.  The repetitions
%             will continue to loop through all these textures in
%             descending order, until reaching nFrames blts.
%
%             Currently the blts are less flexible than with mglBltTexture.
%             The configuration is limited to:
%               - an unrotated square of length 2, centered at (0,0)
%               - "nearest" texture sampling (no interpolation)
%               - "repeat" texture addressing (wrapping)
%               - no phase shift in the texture coordinates
%
%             This will return a single ackTime for when the command was
%             received to begin the sequence of frames.
%
%             It will also return an array of nFrames drawTimes,
%             indicating when drawing was completed during each frame, and
%             an array of nFrames frameTimes indicating when each frame was
%             completed.
%
% % Cycle through several random, full-screen textures.
% mglOpen();
% for ii = 1:30
%     textures(ii) = mglCreateTexture(rand(mglGetParam('screenHeight'), mglGetParam('screenWidth'), 4));
% end
% [ackTime, drawTimes, frameTimes] = mglMetalRepeatingBlts(300);
%
% % Plot how long each frame took.
% frameStarts = frameTimes(1:end-1);
% frameDurations = frameTimes(2:end) - frameStarts;
% drawDurations = drawTimes(2:end) - frameStarts;
% plot(2:300, 1000 * drawDurations, 'b.', 2:300, 1000 * frameDurations, 'r.');
% legend('draw time', 'frame time');
function [ackTime, drawTimes, frameTimes] = mglMetalRepeatingBlts(nFrames, socketInfo)

if nargin < 2 || isempty(socketInfo)
    global mgl;
    socketInfo = mgl.activeSockets;
end

mglSocketWrite(socketInfo, socketInfo(1).command.mglRepeatBlts);
ackTime = mglSocketRead(socketInfo, 'double');
mglSocketWrite(socketInfo, uint32(nFrames));
drawAndFrameTimes = mglSocketRead(socketInfo, 'double', 2 * nFrames);
drawTimes = drawAndFrameTimes(1:2:end);
frameTimes = drawAndFrameTimes(2:2:end);
