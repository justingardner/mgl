% mglTestArcs.m
%
%      usage: mglTestArcs
%         by: justin gardner
%       date: 08/23/2023
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: To test the arcs in metals
%
function retval = mglTestArcs

% open screen
mglClose;
mglOpen(0,800,800);
mglVisualAngleCoordinates(57,[20 20]);
%mglQuad([-5; -5; 5; 5],[-5; 5; 5; -5],[1; 1; 1], 1)
%mglFlush;
%return
% set center
xyz = [0 2.5 0]';

% set color
rgba = [1 0 0 1.0]';

% set radii
radii = [1.25 2.5]';

% set wedge
wedge = [0 2*pi]';

% set border
border = 0;

% clear the screen
mglClearScreen;

% draw arcs
mglMetalArcs(xyz,rgba,radii,wedge,border);

% draw another one
%radii = [5 10]';
%rgba = [0 1 0 0.5]';
%mglMetalArcs(xyz,rgba,radii,wedge,border);

% draw points for reference
r = [0:1.25:15]';
z = zeros(1,length(r))';
mglPoints2([-r; r;z;r/sqrt(2);-r/sqrt(2)],[z;z;r;r/sqrt(2);r/sqrt(2)],0.1);

% and display
mglFlush