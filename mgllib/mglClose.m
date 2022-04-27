% mglClose.m
%
%        $Id$
%     program: mglClose.m
%          by: justin gardner
%        date: 04/03/06
%   copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%     purpose: Shut down the mglMetal app
%       usage: mglClose()
%
function retval = mglClose()

% check arguments
if ~any(nargin == [0])
  help mglClose
  return
end

% if no display open, then nothing to do
if mglGetParam('displayNumber') == -1
  disp(sprintf('(mglClose) No display is open'));
  return
end

% clear screen to avoid flickering 
mglClearScreen(0);
mglFlush;
mglClearScreen(0);
mglFlush;

% restore gamma table, if any
if ~isempty(mglGetParam('initialGammaTable'))
  mglSetGammaTable(mglGetParam('initialGammaTable'));
end

if ~isempty(mglGetParam('sounds'))
  % uninstall sounds
  mglInstallSound;
end
  
% free any existing movies
movieStructs = mglGetParam('movieStructs');
if ~isempty(movieStructs)
  for i = 1:length(movieStructs)
    if ~isempty(movieStructs{i})
      m = movieStructs{i};
      m.id = i;
      mglMovie(m,'close');
    end
  end
  mglSetParam('movieStructs',{}); 
end
% close movie window
if mglGetParam('movieMode'), mglMovie('closeWindow');end

% Close the mglMetal app, and socket connection to it.
global mgl
if isfield(mgl, 's')
    mgl.s = mglSocketClose(mgl.s);
end
mglMetalShutdown();
mglSetParam('displayNumber', -1);

% reset resolution if necessary
originalResolution = mglGetParam('originalResolution');
if ~isempty(originalResolution)
  if mglGetParam('verbose')
    disp(sprintf('(mglClose) Restoring resolution'));
  end
  mglResolution(originalResolution);
end

% turn of clearing with the mask if it was on. This is an unusual
% global that is used to tell mglClearScreen to use a mask when
% clearing the screen (usually set with mglEditScreenParams - useScreenMask
% its a separate global for speed because mglClearScreen is usually
% within frame updates. Here we set it back to empty, it gets turned
% on in initScreen.
clear global mglGlobalClearWithMask;