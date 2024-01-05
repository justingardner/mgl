% mglTestMetalRepeatingFlush: an automated and/or interactive test for rendering.
%
%      usage: mglTestMetalRepeatingFlush(isInteractive)
%         by: Benjamin Heasly
%       date: 03/10/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Test multiple flushes, repeated by the Metal app.
%      usage:
%             % You can run it by hand with no args.
%             mglTestMetalRepeatingFlush();
%
%             % Or mglRunRenderingTests can run it, in non-interactive mode.
%             mglTestMetalRepeatingFlush(false);
%
function mglTestMetalRepeatingFlush(isInteractive)

if nargin < 1
    isInteractive = true;
end

if (isInteractive)
    mglOpen();
    cleanup = onCleanup(@() mglClose());
end

%% How to:

nFrames = 31;
mglMetalRepeatingFlush(nFrames);

% mglMetalRepeatingFlush should flush all on its own.
disp('Flush for 31 frames should leave the screen blank');

% When it's done, make sure we have normal control again.
% ie, calling flush shouldn't cause an error, get stuck, etc.
mglFlush();

if (isInteractive)
    mglPause();
end
