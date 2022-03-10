% mglTestClearScreen: an automated and/or interactive tets for rendering.
%
%      usage: mglTestClearScreen(isInteractive)
%         by: Benjamin Heasly
%       date: 03/10/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Test setting the screen clear color.
%      usage:
%             % Interactive Testing / Demo:
%             mglTestClearScreen();
%
%             % Auomated Testing:
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

% Choose an RGB color to be the next screen clear color, say an orange.
mglClearScreen([0.9, 0.45, 0.0]);

% The new clear color takes effect at the start of the next render pass.
% Flush by itself will start and end a render pass right away.
mglFlush();

disp('The screen should be orange or brown.')

if (isInteractive)
    pause();
end
