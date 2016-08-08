% mglVolume: Get/set system volume
%
%      usage: vol = mglVolume(<volume>)
%         by: justin gardner
%       date: 08/08/2016
%  copyright: (c) 2016 Justin Gardner (GPL see mgl/COPYING)
%    purpose: Gets / sets system volume. 
%
%             Volume can be a scalar (which sets volume to that level
%             i.e. a number between 0 and 1) or an array of length number
%             of channels (typically 2 for left/right) which sets
%             independently the volume on different channels
%             
%            
% % get volume
% vol = mglVolume;
%
% % set volume to full blast
% vol = mglVolme(1.0);
%
% % set left off, right on
% vol = mglVolme([0.0 1.0]);
%
%
function vol = mglVolume(vol)

% run private c function checking arguments
if nargin == 0
  vol = mglPrivateVolume;
elseif nargin == 1
  vol = mglPrivateVolume(vol);
else
  help mglVolme;
end

