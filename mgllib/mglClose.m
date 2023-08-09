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

% remove mglFrameGrabTex if it exists (this is a texture that is used for making frame grabs)
mglFrameGrabTex = mglGetParam('mglFrameGrabTex');
if ~isempty(mglFrameGrabTex)
  mglDeleteTexture(mglFrameGrabTex);
  mglSetParam('mglFrameGrabTex',[]);
end

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

% Close known mglMetal processes and sockets.
% This should be redundant with onCleanup callbacks set in mglMetalStartup.
% But the callback might be delayed if the caller is holding a reference to
% one of these sockets.  Explicitly shutting down here makes it immediate.
global mgl
if isfield(mgl, 's')
    mglMetalShutdown(mgl.s);
end
mgl.s = [];
if isfield(mgl, 'mirrorSockets')
    for ii = 1:numel(mgl.mirrorSockets)
        mglMetalShutdown(mgl.mirrorSockets(ii));
    end
end
mgl.mirrorSockets = [];
mgl.activeSockets = [];

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
