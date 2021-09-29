% mglQuad.m
%
%      $Id$
%    usage: mglQuad( vX, vY, rgbColor, [antiAliasFlag] );
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
function mglQuad(vX, vY, rgbColor)

global mgl;

% convert x and y into vertices
v = [];
for iQuad = 1:size(vX,1)

  % one triangle of the quad
  v(end+1:end+3) = [vX(iQuad,1) vY(iQuad,1) 0];
  v(end+1:end+3) = rgbColor(iQuad,:);
  v(end+1:end+3) = [vX(iQuad,2) vY(iQuad,2) 0];
  v(end+1:end+3) = rgbColor(iQuad,:);
  v(end+1:end+3) = [vX(iQuad,3) vY(iQuad,3) 0];
  v(end+1:end+3) = rgbColor(iQuad,:);

  % the other triangle of the quad
  v(end+1:end+3) = [vX(iQuad,3) vY(iQuad,3) 0];
  v(end+1:end+3) = rgbColor(iQuad,:);
  v(end+1:end+3) = [vX(iQuad,4) vY(iQuad,4) 0];
  v(end+1:end+3) = rgbColor(iQuad,:);
  v(end+1:end+3) = [vX(iQuad,1) vY(iQuad,1) 0];
  v(end+1:end+3) = rgbColor(iQuad,:);

end

% send quad command
mglProfile('start');
mgl.s = mglSocketWrite(mgl.s,uint16(mgl.command.quad));

% number of vertices
nVertices = length(v)/6;

% send them
mgl.s = mglSocketWrite(mgl.s,uint32(nVertices));
mgl.s = mglSocketWrite(mgl.s,single(v));

% end profiling
mglProfile('end','mglQuad');
