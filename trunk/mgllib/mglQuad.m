% mglQuad.m
%
%      $Id$
%    usage: mglQuad( vX, vY, rgbColor, [antiAliasFlag] );
%       by: eli merriam, based on mglPoints.c by justin gardner & Jonas Larsson
%     date: 04/20/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%  purpose: mex function to draw a quad in an OpenGL screen opened with mglOpen
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


