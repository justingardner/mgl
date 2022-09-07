% mglContextStash: Set aside the mgl state and config, to reactivate later.
%
%        $Id$
%      usage: contextName = mglContextStash(newName)
%         by: ben heasly
%       date: 09/07/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Set aside the mgl state and config, to reactivate later.
%      usage: contextName = mglContextStash(newName)
%
%             The optional first parameter, newName, should be a unique
%             name to give the active mgl context.  If omitted, a default
%             name will be chosen such as "default_0".  The name must be a
%             valid Matlab struct fieldname.
%
%             This will store the active mgl state and config, the mgl
%             "context", in a separate location other than "global mgl".
%             As a result the context will be inactive, but its socket and
%             drawing resources will remain open.  From there a separate
%             context can be created with mglOpen, or reactivated with
%             mglContextActivate.
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
if mglGetParam('verbose')
    fprintf('(mglContextStash) Stashing the active mgl context under the name "%s".\n', contextName);
end

mglSetParam('contextName', contextName);

global mgl
global MGL
mglStashedContexts.(contextName).mgl = mgl;
mglStashedContexts.(contextName).MGL = MGL;

% And clear the active context, so that we only have one copy at a time of
% a given context.
mgl = [];
MGL = [];
