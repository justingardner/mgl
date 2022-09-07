% mglMirrorFlushAll: Flush the primary and any mirrored windows.
%
%        $Id$
%      usage: [ackTime, processedTime] = mglMirrorFlushAll()
%         by: ben heasly
%       date: 09/07/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Flush the primary and any mirrored windows.
%      usage: [ackTime, processedTime] = mglMirrorFlushAll()
%
%             This will flush the primary mgl window, plus any mirrored
%             windows, without causing a state change as to which windows
%             are considered active.
%
%             % Open a primary and a mirror window.
%             mglOpen(0);
%             mglMirrorOpen(0,
%
%             % Flush all windows, whether primary or mirror.
%             mglMirrorFlushAll();
%
%             % Clean up.
%             mglClose();
function [ackTime, processedTime] = mglMirrorFlushAll()

global mgl
if isempty(mgl)
    ackTime = [];
    processedTime = [];
    return;
end
socketInfo = cat(2, mgl.s, mgl.mirrorSockets);
[ackTime, processedTime] = mglFlush(socketInfo);
