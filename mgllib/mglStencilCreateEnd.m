% mglStencilCreateEnd
%
%        $Id$
%      usage: [ackTime, processedTime] = mglStencilCreateEnd(socketInfo)
%         by: justin gardner
%       date: 05/26/2006
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Ends drawing to stencil
%
%       e.g.:
%mglOpen;
%mglScreenCoordinates;
%
%%Draw an oval stencil
%mglStencilCreateBegin(1);
%mglFillOval(300,400,[100 100]);
%mglStencilCreateEnd;
%mglClearScreen;
%
%% now draw some dots, masked by the oval stencil
%mglStencilSelect(1);
%mglPoints2(rand(1,5000)*500,rand(1,5000)*500);
%mglFlush;
%mglStencilSelect(0);
function [ackTime, processedTime] = mglStencilCreateEnd(socketInfo)

if nargin < 1
    global mgl
    socketInfo = mgl.activeSockets;
end

% Flush to complete the render pass where we wrote to the texture.
% This causes Metal to store the updated stencil buffer for later use.
mglFlush(socketInfo);

% Get ready for regular drawign with no stencil selected.
mglSocketWrite(socketInfo, socketInfo(1).command.mglFinishStencilCreation);
ackTime = mglSocketRead(socketInfo, 'double');
processedTime = mglSocketRead(socketInfo, 'double');
