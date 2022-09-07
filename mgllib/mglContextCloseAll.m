% mglContextCloseAll: Close all stashed and active mgl contexts.
%
%        $Id$
%      usage: [stashedNames, activeName] = mglContextCloseAll()
%         by: ben heasly
%       date: 09/07/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Close all stashed and active mgl contexts.
%      usage: [stashedNames, activeName] = mglContextCloseAll()
%
%             This will close all known mgl contexts, including the active
%             context in "global mgl", plus any contexts that were
%             previously stashed with mglContextStash.  As with mglClose,
%             this will free system resources and close drawing windows.
%
%             Afterwards, the active context will remain in "global mgl" in
%             a closed state, and any stashed contexts will be closed,
%             cleared, and forgotten completely.
%
%             Returns the names of any stashed contexts that were closed,
%             and the name of the active context.
%
%             % Open two separate mgl contexts, on separate displays.
%             mglOpen(0);
%             mglContextStash('windowed');
%             mglOpen(1);
%             mglContextStash('fullscreen');
%
%             % Close all contexts, see which ones were stashed vs active.
%             [stashedNames, activeName] = mglContextCloseAll()
function [stashedNames, activeName] = mglContextCloseAll()

% Close each stashed context.
[stashedNames, activeName] = mglContextList();
for ii = 1:numel(stashedNames)
    toCloseName = stashedNames{ii};
    fprintf('(mglContextCloseAll) Closing stashed mgl context with name "%s".\n', toCloseName);
    mglContextActivate(toCloseName);
    mglClose();
end

% Restore the context that was active when we started, and close it, too.
fprintf('(mglContextCloseAll) Closing active mgl context with name "%s".\n', toCloseName);
mglContextActivate(activeName);
mglClose();

% Clear out the collection of active contexts.
global mglStashedContexts
mglStashedContexts = struct();
