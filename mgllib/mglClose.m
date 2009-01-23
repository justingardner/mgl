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

% if no display open, then nothing to do
if mglGetParam('displayNumber') == -1
  disp(sprintf('(mglClose) No display is open'));
  return
end

% clear screen to avoid flickering 
mglClearScreen(0);mglFlush;mglClearScreen(0);mglFlush;

% restore gamma table, if any
if ~isempty(mglGetParam('initialGammaTable'))
  mglSetGammaTable(mglGetParam('initialGammaTable'));
end

if ~isempty(mglGetParam('sounds'))
  % uninstall sounds
  mglInstallSound;
  mglSetParam('sounds',[]);
  mglSetParam('soundNames',{});
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

% run mex function to actually close display
mglSetParam('verbose',1);
mglPrivateClose;
mglSetParam('verbose',0);

% reset resolution if necessary
originalResolution = mglGetParam('originalResolution');
if ~isempty(originalResolution)
  if mglGetParam('verbose')
    disp(sprintf('(mglClose) Restoring resolution'));
  end
  mglResolution(originalResolution);
end
