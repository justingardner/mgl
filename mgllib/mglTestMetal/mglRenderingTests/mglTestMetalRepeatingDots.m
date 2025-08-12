% mglTestMetalRepeatingDots: an automated and/or interactive test for rendering.
%
%      usage: mglTestMetalRepeatingDots(isInteractive)
%         by: Benjamin Heasly
%       date: 03/17/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Test random dots, repeated by the Metal app.
%      usage:
%             % You can run it by hand with no args.
%             mglTestMetalRepeatingDots();
%
%             % Or mglRunRenderingTests can run it, in non-interactive mode.
%             mglTestMetalRepeatingDots(false);
%
function mglTestMetalRepeatingDots(isInteractive)

if nargin < 1
    isInteractive = true;
end

if (isInteractive)
    mglOpen();
    cleanup = onCleanup(@() mglClose());
end

%% How to:

nFrames = 31;
nDots = 1000;
randomSeed = 42;
mglMetalRepeatingDots(nFrames, nDots, randomSeed);

% mglMetalRepeatingDots should flush all on its own.
disp('Random dots should fill the screen.  The last set of dots should come out the same every time.');

if (isInteractive)
    mglPause();
end
