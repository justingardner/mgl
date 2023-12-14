% mglTestMetalArcs: an automated and/or interactive test for rendering.
%
%      usage: mglTestMetalArcs(isInteractive)
%         by: Benjamin Heasly
%       date: 03/10/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Test rendering various sizes and shapes of vectorized arcs.
%      usage:
%             % You can run it by hand with no args.
%             mglTestMetalArcs();
%
%             % Or mglRunRenderingTests can run it, in non-interactive mode.
%             mglTestMetalArcs(false);
%
function mglTestMetalArcs(isInteractive)

if nargin < 1
    isInteractive = true;
end

if (isInteractive)
    mglOpen();
    cleanup = onCleanup(@() mglClose());
end

%% How to:

mglVisualAngleCoordinates(50, [20, 20]);

% Arcs are vectorized to have 12 components per vertex: [x y z r g b a inner outer start sweep border].
xyz = [-5 5 0; 0 5 0; 5 5 0]';
rgba = [1 0 0 1; 0 1 1 1; 1 1 1 0.5]';
radii = [0 2; 1 2; 2 3]';
wedge = [0 2*pi; 0 2*pi; 0 2*pi;]';
border = [0.1 0.1 0.1];
mglMetalArcs(xyz, rgba, radii, wedge, border);
disp('There shoud be three rings across the top.')

xyz2 = [-5 0 0; 0 0 0; 5 0 0]';
radii2 = [0 2; 0 2; 0 3]';
wedge2 = [0 2*pi; pi/4 pi; 7*pi/4 pi/3]';
mglMetalArcs(xyz2, rgba, radii2, wedge2, border);
disp('There shoud be three wedges across the middle.')

xyz3 = [-5 -5 0; 0 -5 0; 5 -5 0]';
mglMetalArcs(xyz3, rgba, radii, wedge2, border);
disp('There shoud be three partial arcs across the bottom.')

mglFlush();

if (isInteractive)
    mglPause();
end
