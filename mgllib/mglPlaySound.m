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
%      usage: Play alert sound
%
%mglPlaySound;
%
%      usage: Playing a specific sound
%mglOpen;
%global MGL;
%mglPlaySound(find(strcmp(MGL.soundNames,'Submarine')));
%
