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
%             a specific one as follows
%mglOpen;
%mglPlaySound('Submarine');
%

% check mglPlaySound
if nargin ~= 1
  % display help
  help mglPlaySound;
  % list available sounds
  global MGL;
  if isfield(MGL,'soundNames')
    disp(sprintf('Available sounds are:'));
    for i = 1:length(MGL.soundNames)
      if ~isempty(MGL.soundNames{i})
	fprintf(1,'%s ',MGL.soundNames{i});
      end
    end
    fprintf(1,'\n');
  end
  
  return
end

% scalar, then play
if isscalar(soundNum)
  mglPrivatePlaySound(soundNum);
% string then find the correct string name
elseif isstr(soundNum)
  global MGL;
  soundNum = find(strcmp(soundNum,MGL.soundNames));
  if ~isempty(soundNum)
    mglPrivatePlaySound(soundNum(1));
  end
end
  