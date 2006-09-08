% mglClose.m
%
%        $Id$
%     program: mglClose.m
%          by: justin gardner
%        date: 04/03/06
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
mglClearScreen;mglFlush;mglClearScreen;mglFlush;

% if we have an initial gamma table set, then go back to that.
if isfield(MGL,'initialGammaTable') && ~isempty(MGL.initialGammaTable)
  mglSetGammaTable(MGL.initialGammaTable);
end


% call the mex file to close the screen
mglPrivateClose;

