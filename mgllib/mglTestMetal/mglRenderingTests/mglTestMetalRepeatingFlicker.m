% mglTestMetalRepeatingFlicker: an automated and/or interactive test for rendering.
%
%      usage: mglTestMetalRepeatingFlicker(isInteractive)
%         by: Benjamin Heasly
%       date: 03/10/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Test random clear colors repeated by the Metal app.
%      usage:
%             % You can run it by hand with no args.
%             mglTestMetalRepeatingFlicker();
%
%             % Or mglRunRenderingTests can run it, in non-interactive mode.
%             mglTestMetalRepeatingFlicker(false);
%
function mglTestMetalRepeatingFlicker(isInteractive)

if nargin < 1
    isInteractive = true;
end

if (isInteractive)
    mglOpen();
    cleanup = onCleanup(@() mglClose());
end

%% How to:

nFrames = 31;
randomSeed = 42;
mglMetalRepeatingFlicker(nFrames, randomSeed);

% mglMetalRepeatingFlicker should flush all on its own.
disp('Flicker for 31 frames with random seed 42 should leave us with a lavender clear color');

% When it's done, make sure we have normal control again.
% ie, calling flush shouldn't cause an error, get stuck, etc.
mglFlush();

if (isInteractive)
    mglPause();
end
