% mglContextActivate: Activate mgl state and config previously stashed by mglContextStash.
%
%        $Id$
%      usage: swappedOutName = mglContextActivate(toActivateName, swappedOutName)
%         by: ben heasly
%       date: 09/07/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Activate mgl state and config previously stashed by mglContextStash.
%      usage: swappedOutName = mglContextActivate(toActivateName, swappedOutName)
%             toActivateName - the name of an mgl context prviously
%                              stashed by mglContextStash
%             swappedOutName - (optional) a unique name to use when
%                              stashing the active mgl context to make way
%                              for the context being activated.  If
%                              omitted, a default name will be chosen such
%                              as "default_0". The name must be a valid
%                              Matlab struct fieldname.
%
%             This will activate an mgl context with name toActivateName,
%             that was previously stashed with mglContextStash.  If another
%             context is already active, it will be stashed automatically
%             beforehand, using the name swappedOutName.
%
%             Returns the name used to stash the already active context,
%             which would by swappedOutName if given, or an automatically
%             chosen default name.
%
%             % Open two separate mgl contexts, on separate displays.
%             mglOpen(0);
%             mglContextStash('windowed');
%             mglOpen(1);
%             mglContextStash('fullscreen');
%
%             % Activate one context at a time for drawing etc.
%             mglContextActivate('windowed');
%             mglGetParam('contextName')
%             % ... draw and flush to the window ...
%             mglContextActivate('fullscreen');
%             mglGetParam('contextName')
%             % ... draw and flush to the full screen ...
%
%             % Clean up all contexts, whether active or stashed.
%             mglContextCloseAll();
function swappedOutName = mglContextActivate(toActivateName, swappedOutName)

if nargin < 2
    swappedOutName = [];
end

% Do we have a previously stashed context with the given name?
[stashedNames, activeName] = mglContextList();
if ~any(strcmp(toActivateName, stashedNames))
    fprintf('(mglContextActivate) No stashed context found with name "%s", please choose one of the stashed names returned from mglContextList.\n', toActivateName);
    return;
end

% Do we need to stash an active context first?
if ~isempty(activeName)
    swappedOutName = mglContextStash(swappedOutName);
end

fprintf('(mglContextActivate) Activating stashed context with name "%s".\n', toActivateName);

% Swap in the named context and remove it from the stash so that we only
% have one copy at a time of a given context.
global mglStashedContexts
global mgl
global MGL
mgl = mglStashedContexts.(toActivateName).mgl;
MGL = mglStashedContexts.(toActivateName).MGL;
mglStashedContexts = rmfield(mglStashedContexts, toActivateName);
