% Activate an mgl context that was previously stashed with mglContextStash.
% If another context is already active, it will be automatically stashed
% beforehand.
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
