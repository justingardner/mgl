% mglMirrorActivate: Selects which primary and/or mirrored windows are active.
%
%        $Id$
%      usage: mglMirrorActivate(indices)
%         by: ben heasly
%       date: 08/29/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Selects which primary and/or mirrored windows are active.
%      usage: The first argument is an array of indices, selecting which
%             primary and/or mirrored windows should be active and receive
%             drawing commands.  The indices are:
%               - 0: the primary window, as opened by mglOpen()
%               - 1+: mirrored windows as opened by mglMirrorOpen()
%
%             By default this will be the primary window, as opened by
%             mglOpen(), followed by any mirrored windows, as opened by
%             mglMirrorOpen(), in the order they were opened.
%
%             % activate the primary and all mirrored windows
%             mglMirrorActivate();
%
%             % activate only the primary window
%             mglMirrorActivate(0);
%
%             % activate only one the first mirrored window
%             mglMirrorActivate(1);
%
function mglMirrorActivate(indices)

global mgl

if nargin < 1 || isempty(indices)
    mgl.activeSockets = [mgl.s, mgl.mirrorSockets];
    return;
end

% Assign the primary socket.
activeSockets = cell(1, numel(indices));
isPrimary = indices == 0;
if any(isPrimary)
    activeSockets{isPrimary} = mgl.s;
end

% Assign mirrored sockets.
isMirror = indices > 0;
if any(isMirror)
    activeSockets{isMirror} = mgl.mirrorSockets(indices(isMirror));
end

mgl.activeSockets = [activeSockets{:}];
