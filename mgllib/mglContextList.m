% List names of any mgl contexts that have been stashed with
% mglContextStash, and also report the name of the active mgl context, if
% it has a name.
function [stashedNames, activeName] = mglContextList()

global mglStashedContexts
if isempty(mglStashedContexts)
    stashedNames = {};
else
    stashedNames = fieldnames(mglStashedContexts);
end

activeName = mglGetParam('contextName');
