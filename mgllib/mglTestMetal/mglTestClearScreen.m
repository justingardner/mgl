% mglTestClearScreen: an automated and/or interactive test for rendering.
%
%      usage: mglTestClearScreen(isInteractive)
%         by: Benjamin Heasly
%       date: 03/10/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Test setting the screen clear color.
%      usage:
%             % You can run it by hand with no args.
%             mglTestClearScreen();
%
%             % Or mglRunRenderingTests can run it, in non-interactive mode.
%             mglTestClearScreen(false);
%
function mglTestClearScreen(isInteractive)

if nargin < 1
    isInteractive = true;
end

if (isInteractive)
    mglOpen();
    cleanup = onCleanup(@() mglClose());
end

%% How to:

% Choose an RGB color to be the next screen clear color, perhaps an orange-brown color.
rgb = [0.9, 0.45, 0.0];
mglClearScreen(rgb);
disp('The screen should be cleared to an orange-brown color.')

% The clear color takes effect at the start of each render pass.
% Calling flush by itself will start and end a render pass right away.
mglFlush();

if (isInteractive)
    pause();
end
