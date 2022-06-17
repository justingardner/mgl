% mglTestMetalRepeatingQuads: an automated and/or interactive test for rendering.
%
%      usage: mglTestMetalRepeatingQuads(isInteractive)
%         by: Benjamin Heasly
%       date: 03/10/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Test random quads, repeated by the Metal app.
%      usage:
%             % You can run it by hand with no args.
%             mglTestMetalRepeatingQuads();
%
%             % Or mglRunRenderingTests can run it, in non-interactive mode.
%             mglTestMetalRepeatingQuads(false);
%
function mglTestMetalRepeatingQuads(isInteractive)

if nargin < 1
    isInteractive = true;
end

if (isInteractive)
    mglOpen();
    cleanup = onCleanup(@() mglClose());
end

%% How to:

nFrames = 30;
nQuads = 100;
randomSeed = 42;
mglMetalRepeatingQuads(nFrames, nQuads, randomSeed);

% mglMetalRepeatingQuads should flush all on its own.
disp('Random quads should fill the screen.  The last set of quads should come out the same every time.');

if (isInteractive)
    mglPause();
end
