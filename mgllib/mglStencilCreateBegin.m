% mglStencilCreateBegin
%
%        $Id$
%      usage: [ackTime, processedTime] = mglStencilCreateBegin(stencilNumber, invert, socketInfo)
%         by: justin gardner and ben heasly
%       date: 05/26/2006
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Begin drawing to stencil. Until mglStencilCreateEnd
%             is called, all drawing operations will also draw
%             to the stencil. Check mglGetParam('stencilBits') to see how
%             many stencil planes there are. If invert is set
%             to one, then the inverse stencil is made
%
%       e.g.:
%mglOpen;
%mglScreenCoordinates;
%
% %Draw an oval stencil
%mglStencilCreateBegin(1);
%mglFillOval(300,400,[100 100]);
%mglStencilCreateEnd;
%mglClearScreen;
%
% % now draw some dots, masked by the oval stencil
%mglStencilSelect(1);
%mglPoints2(rand(1,5000)*500,rand(1,5000)*500);
%mglFlush;
%mglStencilSelect(0);
function [ackTime, processedTime] = mglStencilCreateBegin(stencilNumber, invert, socketInfo)

if nargin < 2
    invert = 0;
end

if nargin < 3 || isempty(socketInfo)
    global mgl
    socketInfo = mgl.activeSockets;
end

% With Metal, we need our own logic to clear each stencil plane.
% We can do this with an extra render pass that fills the whole screen,
% and populates the chosen stencil plane with a clear (or inverse) value.
% Then we can let the user draw in whatever stencil values they need.

% Select the "clear" value for the requested stencil plane.
startStencilCreation(stencilNumber, ~invert, socketInfo);

% Draw a huge quad to cover the whole screen.
deviceRect = mglGetParam('deviceRect');
x = deviceRect([1 3 3 1]) * 2;
y = deviceRect([2 2 4 4]) * 2;
rgb = [1 1 1];
mglQuad(x', y', rgb', [], socketInfo);

% Flush and store the plane of cleared values to the stencil buffer.
mglStencilCreateEnd(socketInfo);

% Now let the caller draw into the requested stencil plane.
[ackTime, processedTime] = startStencilCreation(stencilNumber, invert, socketInfo);


function [ackTime, processedTime] = startStencilCreation(stencilNumber, invert, socketInfo)
mglSocketWrite(socketInfo, socketInfo(1).command.mglStartStencilCreation);
ackTime = mglSocketRead(socketInfo, 'double');
mglSocketWrite(socketInfo, uint32(stencilNumber));
mglSocketWrite(socketInfo, uint32(invert));
processedTime = mglSocketRead(socketInfo, 'double');
