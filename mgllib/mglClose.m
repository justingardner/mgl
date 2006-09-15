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

% if we have an initial gamma table set, then go back to that.
if isfield(MGL,'initialGammaTable') && ~isempty(MGL.initialGammaTable)
  mglSetGammaTable(MGL.initialGammaTable);
end

% call the mex file to close the screen, don't close the screen
% if we are running on the desktop with a windowed context, since
% that seems to cause instability
if ~(isempty(javachk('desktop'))  & (MGL.displayNumber == 0))
  mglPrivateClose;
elseif (MGL.desktopWarning < 2)
  disp(sprintf('(mglClose) Using a windowed openGl context with the matlab desktop'));
  disp(sprintf('           can be unstable due to some interactions with multiple'));
  disp(sprintf('           threads. If you encounter crashing consider either using'));
  disp(sprintf('           a full window context, (ie not mglOpen(0)) or run matlab'));
  disp(sprintf('           using -nojvm or -nodesktop. Note that to improve stability'));
  disp(sprintf('           mglClose will not close the window. If you are done using'));
  disp(sprintf('           mgl and want to force the window closed, use mglPrivateClose'));
  MGL.desktopWarning = 2;
end




