% mglSetSound.m
%
%        $Id:$ 
%      usage: mglSetSound(s,'propertyName',propertyValue)
%         by: justin gardner
%       date: 08/10/15
%    purpose: Set properties of a soundID that has been created with mglInstallSound
%            
%             t = 0:2*pi/8191:2*pi;
%             waveform = sin(440*t);
%             s = mglInstallSound(waveform);
%
%             % display current sound settings
%             mglSetSound(s);
%
%             % display possible settings for displayID
%             mglSetSound(s,'deviceID');
%
%             % set displayID
%             mglSetSound(s,'deviceID',1);
%
%
% 
function mglSetSound(s,propertyName,propertyValue)

% check arguments
if nargin ~= [1 2 3]
  help mglSetSound
  return
end

% make sure the sound exists
sounds = mglGetParam('sounds');
if isscalar(s) && (s>=1) && (s<=length(sounds))
  if nargin == 1
    % with one arguments, send propertyName as null to indicate printing list of properties
    mglPrivateSetSound(s,[],-1);
  elseif nargin == 2
    % with two arguments, send -1 to indicate we should print out acceptable values
    mglPrivateSetSound(s,lower(propertyName),-1);
  else
    % set the value to propertyValue
    mglPrivateSetSound(s,lower(propertyName),propertyValue);
  end
    
else
  disp(sprintf('(mglSetSound) Sound does not exist'));
end
