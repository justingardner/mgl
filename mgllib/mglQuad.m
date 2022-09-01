% mglQuad.m
%
%      $Id$
%    usage: [ackTime, processedTime, setupTime] = mglQuad( vX, vY, rgbColor, [antiAliasFlag] );
%       by: justin gardner
%     date: 09/28/2021
%  copyright: (c) 2021 Justin Gardner (GPL see mgl/COPYING)
%  purpose: Function to draw a quad in an mglMetal screen opened with mglOpen
%           vX: 4 row by N column matrix of 'X' coordinates
%           vY: 4 row by N column matrix of 'Y' coordinates
%           rgbColors: 3 row by N column of r-g-b specifing the
%                      color of each quad
%           antiAliasFlag: turns on antialiasing to smooth the edges
%     e.g.:
%
%
%mglOpen();
%mglScreenCoordinates
%mglQuad([100; 600; 600; 100], [100; 200; 600; 100], [1; 1; 1], 1);
%mglFlush();
function [ackTime, processedTime, setupTime] = mglQuad(vX, vY, rgbColor, antiAliasFlag, socketInfo)

% Not currently used, but let's maintain compatibility with v2.
if nargin < 4
    antiAliasFlag = false;
end

if nargin < 5 || isempty(socketInfo)
    global mgl;
    socketInfo = mgl.activeSockets;
end

% Construct XYZRGB vertex array with 3 triangels / 6 vertices per quad.
nQuads = size(vX, 2);
nVertices = nQuads * 6;
v = zeros(6, nVertices);
for iQuad = 1:nQuads

    % one triangle of the quad
    v(1:2, iQuad * 6 - 5) = [vX(1, iQuad), vY(1, iQuad)];
    v(4:6, iQuad * 6 - 5) = rgbColor(:, iQuad);
    v(1:2, iQuad * 6 - 4) = [vX(2, iQuad), vY(2, iQuad)];
    v(4:6, iQuad * 6 - 4) = rgbColor(:, iQuad);
    v(1:2, iQuad * 6 - 3) = [vX(3, iQuad), vY(3, iQuad)];
    v(4:6, iQuad * 6 - 3) = rgbColor(:, iQuad);

    % the other triangle of the quad
    v(1:2, iQuad * 6 - 2) = [vX(3, iQuad), vY(3, iQuad)];
    v(4:6, iQuad * 6 - 2) = rgbColor(:, iQuad);
    v(1:2, iQuad * 6 - 1) = [vX(4, iQuad), vY(4, iQuad)];
    v(4:6, iQuad * 6 - 1) = rgbColor(:, iQuad);
    v(1:2, iQuad * 6) = [vX(1, iQuad), vY(1, iQuad)];
    v(4:6, iQuad * 6) = rgbColor(:, iQuad);

end

% Setup timestamp can be used for measuring MGL frame timing,
% for example with mglTestRenderingPipeline.
setupTime = mglGetSecs();

% send quad command
mglSocketWrite(socketInfo, socketInfo(1).command.mglQuad);
ackTime = mglSocketRead(socketInfo, 'double');
mglSocketWrite(socketInfo, uint32(nVertices));
mglSocketWrite(socketInfo, single(v));
processedTime = mglSocketRead(socketInfo, 'double');
