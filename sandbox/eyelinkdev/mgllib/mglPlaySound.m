function mglPlaySound(soundNum)
% mglPlaySound: Play a system sound
%
%        $Id$
%      usage: mglPlaySound(soundNum)
%         by: justin gardner
%       date: 02/08/07
%  copyright: (c) 2007 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Plays a system sound. After calling mglOpen, all of
%             the system sounds will be installed and you can play
%             a specific one as follows.
%mglOpen;
%mglPlaySound('Submarine');
%
%             If you want to play your own sound, see mglInstallSound
%

% check mglPlaySound
if nargin ~= 1
  % display help
  help mglPlaySound;
  listAvailableSounds;
  return
end

% scalar, then play
if isscalar(soundNum)
  mglPrivatePlaySound(soundNum);
% string then find the correct string name
elseif isstr(soundNum)
  soundName = soundNum;
  soundNames = mglGetParam('soundNames');
  soundNum = find(strcmp(lower(soundName),lower(soundNames)));
  if ~isempty(soundNum)
    mglPrivatePlaySound(soundNum(1));
  else
    disp(sprintf('(mglPlaySound) Could not find sound %s',soundName));
    listAvailableSounds;
  end
end
  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%   listAvailableSounds   %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function listAvailableSounds

% list available sounds
soundNames = mglGetParam('soundNames');
if ~isempty(soundNames)
  disp(sprintf('(mglPlaySound) Available sounds are:'));
  fprintf(1,'(mglPlaySound) ');
  for i = 1:length(soundNames)
    if ~isempty(soundNames{i})
      fprintf(1,'%s ',soundNames{i});
    end
  end
  fprintf(1,'\n');
else
  disp(sprintf('(mglPlaySound) No sounds have been installed'));
end
  
