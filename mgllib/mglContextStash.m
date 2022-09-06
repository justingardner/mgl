% Store the context of the current global mgl state and config, the mgl
% "context", in a separate location other than "global mgl".  This will
% make the current context be inactive, and make room for a separate
% context to be created in global mgl, for example with mglOpen.
function contextName = mglContextStash(newName)

% Choose a name for the current mgl state and config -- the mgl "context".
% Prefer the given newName (if any) then fall back to the current name or
% the "default" name.
if nargin >= 1 && ~isempty(newName) && ischar(newName)
    contextName = newName;
else
    contextName = mglGetParam('contextName');
    if isempty(contextName)
        contextName = 'default';
    end
end

% Check if this context name conflicts with an already stashed context.
global mglStashedContexts
if isempty(mglStashedContexts)
    mglStashedContexts = struct();
end

stashedNames = fieldnames(mglStashedContexts);
if any(strcmp(contextName, stashedNames))
    contextCount = numel(stashedNames) + 1;
    contextName2 = sprintf('%s_%d', contextName, contextCount);
    fprintf('(mglContextStash) A context has already been stashed with name "%s", using name "%s" instead.\n', contextName, contextName2);
    contextName = contextName2;
end

% OK, stash the current context under the chosen name.
fprintf('(mglContextStash) Stashing the active mgl context under the name "%s".\n', contextName);

mglSetParam('contextName', contextName);

global mgl
global MGL
mglStashedContexts.(contextName).mgl = mgl;
mglStashedContexts.(contextName).MGL = MGL;

% And clear the active context, so that we only have one copy at a time of
% a given context.
mgl = [];
MGL = [];
