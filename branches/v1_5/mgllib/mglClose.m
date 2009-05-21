% mglClose.m
%
%        $Id$
%     program: mglClose.m
%          by: justin gardner
%        date: 04/03/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%     purpose: close OpenGL screen
%
function retval = mglClose()

% check arguments
if ~any(nargin == [0])
  help mglClose
  return
end

% we need to access the MGL global
global MGL;

% if no display open, then nothing to do
if MGL.displayNumber == -1
  return
end

% clear screen to avoid flickering 
mglClearScreen(0);mglFlush;mglClearScreen(0);mglFlush;

% restore gamma table, if any
if isfield(MGL,'initialGammaTable') && ~isempty(MGL.initialGammaTable)
  mglSetGammaTable(MGL.initialGammaTable);
end

if isfield(MGL,'sounds')
  % uninstall sounds
  mglInstallSound;
  MGL.soundNames = {};
end

mglPrivateClose;

