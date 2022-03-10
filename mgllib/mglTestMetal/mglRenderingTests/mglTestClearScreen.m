% mglTestClearScreen: an automated and/or interactive tets for rendering.
%
%      usage: result = mglTestClearScreen(isInteractive)
%         by: Benjamin Heasly
%       date: 03/10/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Test setting the screen clear color.
%      usage:
%             % Interactive Testing / Demo:
%             mglTestClearScreen();
%
%             % Auomated Testing:
%             result = mglTestClearScreen(false);
%
function results = mglTestClearScreen(isInteractive)

if nargin < 1
    isInteractive = true;
end
results = [];

% Open with a known size, for automated comparisons.
windowSize = 512;
mglOpen(0, windowSize, windowSize);
cleanup = onCleanup(@() mglClose());

% For automated testing, we'll render to a texture instead of to screen.
if (~isInteractive)
    blankImage = zeros(windowSize, windowSize, 4);
    screenGrab = mglCreateTexture(blankImage);
    mglMetalSetRenderTarget(screenGrab);

    testFolder = fileparts(mfilename('fullpath'));
    snapshot = fullfile(testFolder, 'snapshots', [mfilename() '.mat']);
    results = load(snapshot);
end


%% How to.

% Choose an RGB color to be the next screen clear color, say an orange.
mglClearScreen([0.9, 0.45, 0.0]);

% The new clear color takes effect at the start of the next render pass.
% Flush by itself will start and end a render pass right away.
mglFlush();

disp('The screen should be orange or brown.')

if (isInteractive)
    pause();
end

%% Assertions.
if (~isInteractive)    
    results.renderedImage = mglMetalReadTexture(screenGrab);
    results.isSuccess = isequal(results.renderedImage, results.snapshot);
end
