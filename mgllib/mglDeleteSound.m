% mglDeleteSound.m
%
%        $Id:$ 
%      usage: mglDeleteSound(soundID)
%         by: justin gardner
%       date: 08/15/15
%    purpose: Free up space on allocated sound
%
%             After installing a sound with mglInstallSound you
%             can remove it with this function if you do not want
%             to play it anymore and you need to free up memory
%
% 
%             t = 0:2*pi/8191:2*pi;
%             amplitude = 0.2;
%             waveform = amplitude * sin(440*t);
%             s = mglInstallSound(waveform);
%             mglPlaySound(s);
%             mglDeleteSound(s);
%
function mglDeleteSound(soundID)

% check arguments
if ~any(nargin == [1])
  help mglDeleteSound
  return
end

% convert to ID
global MGL
if isfield(MGL,'sounds')
  if (soundID <= length(MGL.sounds))
    if MGL.sounds(soundID) ~= 0
      % free the pointer
      mglPrivateDeleteSound(MGL.sounds(soundID));
      % set the reference to NULL
      MGL.sounds(soundID) = 0;
      MGL.soundNames{soundID} = '';
    else
      disp(sprintf('(mglDeleteSound) Sound already deleted'));
    end
  end
end

    