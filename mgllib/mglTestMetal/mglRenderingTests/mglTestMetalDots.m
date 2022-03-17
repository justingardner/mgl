% mglTestMetalDots: an automated and/or interactive test for rendering.
%
%      usage: mglTestMetalDots(isInteractive)
%         by: Benjamin Heasly
%       date: 03/10/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Test rendering various sizes and shapes of vectorized dots.
%      usage:
%             % You can run it by hand with no args.
%             mglTestMetalDots();
%
%             % Or mglRunRenderingTests can run it, in non-interactive mode.
%             mglTestMetalDots(false);
%
function mglTestMetalDots(isInteractive)

if nargin < 1
    isInteractive = true;
end

if (isInteractive)
    mglOpen();
    cleanup = onCleanup(@() mglClose());
end

%% How to:

mglVisualAngleCoordinates(50, [20, 20]);

% Dots are vectorized to have 11 components per vertex: [x y z r g b a w h shape border].
xyz = [5 5 0; -5 5 0; -5 -5 0; 5 -5, 0]';
rgba = [1 0 0 1; 0 1 0 1; 0 0 1 1; 1 1 1 0.5]';
wh = [200 100; 80 200; 150 150; 60 60]';
shape = [0 1 0 1];
border = [0 10 0 5];

mglMetalDots(xyz, rgba, wh, shape, border);

disp('There shoud be four dots of different shapes and colors.')

mglFlush();

if (isInteractive)
    pause();
end
