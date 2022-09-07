% mglContextFlushAll: Flush all stashed and active mgl contexts.
%
%        $Id$
%      usage: [ackTime, processedTime] = mglContextFlushAll()
%         by: ben heasly
%       date: 09/07/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Flush all stashed and active mgl contexts.
%      usage: [ackTime, processedTime] = mglContextFlushAll()
%
%             This will flush all known mgl contexts, including the active
%             context in "global mgl", plus any contexts that were
%             previously stashed with mglContextStash.
%
%             Flushing in this way will not cause a state change as to
%             which contexts are active vs stashed.
%
%             % Open two separate mgl contexts, on separate displays.
%             mglOpen(0);
%             mglContextStash('windowed');
%             mglOpen(1);
%             mglContextStash('fullscreen');
%
%             % Flush all contexts, whether active or stashed.
%             mglContextFlushAll();
%
%             % Clean up all contexts, whether active or stashed.
%             mglContextCloseAll();
function [ackTime, processedTime] = mglContextFlushAll()

% Collect socketInfo for all known contexts, active and/or stashed.
% My (BSH) hope is to handle looping within the mglSocket* mex-functions
% that are called from mglFlush.  This works, but the implementation here
% is a bit fiddly, gathering up known socketInfo structs.

global mglStashedContexts
global mgl
if isempty(mglStashedContexts)
    if isempty(mgl)
        % No active or stashed contexts found, no-op.
        ackTime = [];
        processedTime = [];
        return;
    else
        % No stashed contexts, just flush the active one.
        [ackTime, processedTime] = mglFlush(mgl.activeSockets);
        return;
    end
else
    % So close -- I wish cellfun would concatenate like-struct arrays as
    % so-called "UniformOutput".  But it only works with scalar structs.
    stashedActiveSockets = cellfun(@(stashed) stashed.mgl.activeSockets, struct2cell(mglStashedContexts), 'UniformOutput', false);
    stashedSocketInfo = cat(2, stashedActiveSockets{:});
    if isempty(mgl)
        % No active context, just flush the stashed ones.
        [ackTime, processedTime] = mglFlush(stashedSocketInfo);
        return;
    else
        % Both active and stashed contexts, flush them all!
        allSocketInfo = cat(2, mgl.activeSockets, stashedSocketInfo);
        [ackTime, processedTime] = mglFlush(allSocketInfo);
        return;
    end
end
