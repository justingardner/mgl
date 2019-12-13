% mglInstallSound: Install an .aiff file for playing with mglPlaySound
%
%        $Id$
%      usage: soundNum = mglInstallSound(soundName,<samplesPerSecond=8192>)
%         by: justin gardner
%       date: 02/08/07
%  copyright: (c) 2007 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Installs an aiff file or data arrayfor playing with mglPlaySOund
%             Call with no arguments to deinstall all sounds
% 
%             Can also be used to install a sound that you create from
%             a matrix
%
%      usage: Installing a sound
%
%soundNum = mglInstallSound('/System/Library/Sounds/Submarine.aiff');
%mglPlaySound(soundNum);
%
%              or to install a whole directory of sounds
%
%              mglInstallSound(soundDirName);
%              mglInstallSound('/System/Library/Sounds');
%
%              To create a data array to play. Note that samplesPerSecond
%              defaults to 8192 (if you don't specify):
%
%              samplesPerSecond = 22000;
%              t = 0:2*pi/(samplesPerSecond-1):2*pi;
%              amplitude = 0.2;
%              waveform = amplitude * sin(440*t);
%              s = mglInstallSound(waveform,samplesPerSecond);
%              mglPlaySound(s);
%
%              To make a waveform in stereo (add more rows for more speaker outputs)
% 
%              samplesPerSecond = 22000;
%              t = 0:2*pi/(samplesPerSecond-1):2*pi;
%              amplitude = 0.2;
%              waveform(1,:) = amplitude * sin(440*t);
%              waveform(2,:) = amplitude * sin(t*5*440/4);
%              s = mglInstallSound(waveform,samplesPerSecond);
%              mglPlaySound(s);
%
%
function soundNum = mglInstallSound(soundName,samplesPerSecond)

% check arguments
if nargin > 2
  help mglInstallSound
  return
end
soundNum = [];

% clear sounds
if nargin == 0
  mglPrivateInstallSound;
  mglSetParam('sounds',[]);
  mglSetParam('soundNames',{});
  return
end

% install sound array
if isnumeric(soundName)
  % scale from -1:1 to intmax (clipping for values out of range
  soundName(soundName > 1)  = 1;
  soundName(soundName < -1)  = -1;
  soundName = soundName*double(intmax);
  % check for samplesPerSecond
  if nargin < 2,samplesPerSecond = 8192;end
  % install the sound (convert to int32 with swapbytes)
  soundNum = mglPrivateInstallSound(swapbytes(int32(soundName)),samplesPerSecond);
  % JG: some race condition seems to be happening in which sometimes this fails
  % to install a sound, so check here and if it does continue to try again until it succeeds
  if isempty(soundNum)
    % get current time
    startTime = mglGetSecs;
    % keep trying for 1 second
    while isempty(soundNum) && (mglGetSecs(startTime) < 1)
      soundNum = mglPrivateInstallSound(swapbytes(int32(soundName)),samplesPerSecond);
    end
    % if still failed then give an error message
    if isempty(soundNum)
      disp(sprintf('(mglInstallSound) Failure to install sound waveform - giving up'));
      keyboard
    end
  end
  % set a name for the sound
  soundNames = mglGetParam('soundNames');
  soundNames{soundNum} = '_userdefined_';
  mglSetParam('soundNames',soundNames);
% install a whole directory of sounds
elseif isdir(soundName)
  % make sure the directory name is fully qualified (to do this cd to the directory and get its path). This
  % prevents sending in things like ~ to the c function
  currentPath = pwd;
  cd(soundName);
  soundPath = pwd;
  cd(currentPath);
  % now get all the sounds in that path
  soundDir = dir(fullfile(soundPath,'*.aif*'));
  for i = 1:length(soundDir)
    mglInstallSound(fullfile(soundPath,soundDir(i).name));
  end
elseif mglIsFile(soundName)
  % install a sound
  soundNum = mglPrivateInstallSound(soundName);
  if ~isempty(soundNum)
    soundNames = mglGetParam('soundNames');
    [soundPath soundNames{soundNum}] = fileparts(soundName);
    mglSetParam('soundNames',soundNames);
  else
    disp(sprintf('(mglInstallSound) Could not install sound %s',soundName));
  end
else
  disp(sprintf('(mglInstallSound) Could not find file %s',soundName));
end


