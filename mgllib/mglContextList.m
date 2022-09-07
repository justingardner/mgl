% mglContextList: List the names of stashed and active mgl contexts.
%
%        $Id$
%      usage: [stashedNames, activeName] = mglContextList()
%         by: ben heasly
%       date: 09/07/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: List the names of stashed and active mgl contexts.
%      usage: [stashedNames, activeName] = mglContextList()
%
%             List names of any mgl contexts that have been stashed with
%             mglContextStash, and also report the name of the active mgl
%             context from "global mgl".
%
%             % Open two separate mgl contexts, on separate displays.
%             mglOpen(0);
%             mglContextStash('windowed');
%             mglOpen(1);
%             mglContextStash('fullscreen');
%
%             % Check for stashed vs active contexts.
%             [stashedNames, activeName] = mglContextList()
%
%             % Clean up all contexts, whether active or stashed.
%             mglContextCloseAll();
function [stashedNames, activeName] = mglContextList()

global mglStashedContexts
if isempty(mglStashedContexts)
    stashedNames = {};
else
    stashedNames = fieldnames(mglStashedContexts);
end

activeName = mglGetParam('contextName');
