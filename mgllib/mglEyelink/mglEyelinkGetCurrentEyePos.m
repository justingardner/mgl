function [pos, posTime] = mglEyelinkGetCurrentEyePos(devicecord)
% mglEyelinkGetCurrentEyePos - Gets the current eye position and time.
%
% Syntax:
% [pos, posTime] = mglEyelinkGetCurrentEyePos
% [pos, posTime] = mglEyelinkGetCurrentEyePos(devicecord)
%
% Description:
% Returns the current eye position and its time stamp.
%
% Input:
% devicecord (logical) - If true, the eye position is converted into MGL
%   device coordinates.  Defaults to true.
%
% Output:
% pos (1x2) - (x,y) position of the eye in EyeLink tracker coordinates.  Is
%   returned as [NaN,NaN] if no sample is available.
% posTime (scalar) - The timestamp of the position from the EyeLink.
%   Returned as NaN if no timestamp is available.

if nargin < 1
	devicecord = 1;
end

% Get the current eye sample.
sample = mglPrivateEyelinkGetCurrentSample;

if ~isempty(sample)
	if devicecord
		pos(1) = (sample(1)-(mglGetParam('screenWidth')/2))*mglGetParam('xPixelsToDevice');
		pos(2) = ((mglGetParam('screenHeight')/2)-sample(2))*mglGetParam('yPixelsToDevice');
	else
		pos(1) = sample(1);
		pos(2) = sample(2);
	end
	
	posTime = sample(8);
else
	pos = [NaN, NaN];
	posTime = NaN;
end
