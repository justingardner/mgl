% mglInstallSound: Install an .aiff file for playing with mglPlaySound
%
%        $Id$
%      usage: soundNum = mglInstallSound(soundName)
%         by: justin gardner
%       date: 02/08/07
%  copyright: (c) 2007 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Installs an aiff file for playing with mglPlaySOund
%             Call with no arguments to deinstall all sounds
%      usage: Installing a sound
%
%soundNum = mglInstallSound('/System/Library/Sounds/Submarine.aiff');
%mglPlaySound(soundNum);
%
%              or to install a whole directory of sounds
%
%              mglInstallSound(soundDirName);
%
function soundNum = mglInstallSound(soundName)

% check arguments
if nargin > 1
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

% install a whole directory of sounds
if isdir(soundName)
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
elseif isfile(soundName)
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


%%%%%%%%%%%%%%%%
%    isfile    %
%%%%%%%%%%%%%%%%
function [isit permission] = isfile(filename)

isit = 0;permission = [];
if (nargin ~= 1)
  help isfile;
  return
end
if isempty(filename),isit = 0;,return,end

% open file
fid = fopen(filename,'r');

% check to see if there was an error
if (fid ~= -1)
  fclose(fid);
  [dummy permission] = fileattrib(filename);
  isit = 1;
else
  isit = 0;
end

