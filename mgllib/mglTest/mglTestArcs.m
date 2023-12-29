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

% set center
xyz = [0 0 0]';

% set color
rgba = [1 0 0 1.0]';

% set radii
radii = [1.25 2.5 2.5 3.75]';

% set wedge
wedge = [0 pi]';

% set border
border = 0;

% clear the screen
mglClearScreen;

% draw arcs
mglMetalArcs(xyz,rgba,radii,wedge,border);

% now draw multiple at once
% set center
xyz = [7.5 0 0;sqrt(7.5^2/2) sqrt(7.5^2/2) 0;0 7.5 0;-sqrt(7.5^2/2) sqrt(7.5^2/2) 0;-7.5 0 0]';

% set color
rgba = [0.54 0.17 1 1;0.54 0.17 1 1;0.54 0.17 1 1;0.54 0.17 1 1;0.54 0.17 1 1;]';

% set radii
radii = [1.25 2.5;1.25 2.5;1.25 2.5;1.25 2.5;1.25 2.5]';

% set wedge
wedge = [0 2*pi;0 2*pi;0 2*pi;0 2*pi;0 2*pi]';

% set border
border = [2;0.5;0.5;0.5;0.5]';

% draw arcs
mglMetalArcs(xyz,rgba,radii,wedge,border);

% draw multiples with wedges set
xyz = [0 0 0;0 0 0;0 0 0;0 0 0]';
rgba = [0 0 1 1;0 0 1 1;0 0 1 1;0 0 1 1]';
radii = [2.5 3.75;2.5 3.75;2.5 3.75;2.5 3.75]';
wedge = [pi+pi/16 pi/8;pi+pi/4+pi/16 pi/8;pi+pi/2+pi/16 pi/8;pi+3*pi/4+pi/16 pi/8]';
border = [0;0;0;0]';
mglMetalArcs(xyz,rgba,radii,wedge,border);

% draw points for reference
r = [0:1.25:15]';
z = zeros(1,length(r))';
mglPoints2([-r; r;z;r/sqrt(2);-r/sqrt(2)],[z;z;r;r/sqrt(2);r/sqrt(2)],0.1);

% and display
mglFlush