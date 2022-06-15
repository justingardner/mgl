% mglMetalRepeatingBlts.m
%
%        $Id$
%      usage: [ackTime, processedTimes] = mglMetalRepeatingBlts(nFrames)
%         by: Benjamin heasly
%       date: 06/15/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Send one command that causes multiple texture blts.
%      usage: [ackTime, processedTimes] = mglMetalRepeatingBlts(nFrames)
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
%             This will return an ackTime that represents when the command
%             was received but before the blts start.
%             It will also return an array of nFrames processedTimes, each
%             of which represents the time when one frame was completed,
%             and the next frame was about to begin.
%
% % Cycle through several random, full-screen textures.
% mglOpen();
% for ii = 1:30
%     textures(ii) = mglCreateTexture(rand(mglGetParam('screenHeight'), mglGetParam('screenWidth'), 4));
% end
% [ackTime, processedTimes] = mglMetalRepeatingBlts(300);
% disp(1000 * diff(processedTimes))
%
function [ackTime, processedTimes] = mglMetalRepeatingBlts(nFrames)

global mgl
mglSocketWrite(mgl.s, mgl.command.mglRepeatBlts);
ackTime = mglSocketRead(mgl.s, 'double');
mglSocketWrite(mgl.s, uint32(nFrames));
processedTimes = mglSocketRead(mgl.s, 'double', nFrames);
