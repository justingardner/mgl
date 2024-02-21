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

% Enqueue several flush commands without processing them yet.
nFrames = 30;
mglMetalStartBatch();
for ii = 1:nFrames
    mglFlush();
end

% Start processing the commands as fast as possible.
mglMetalProcessBatch();

disp('Mgl Metal is repeating flush commands asynchronously.');

% Wait for the commands to finish and gather the timing results.
results = mglMetalFinishBatch();
assert(numel(results) == nFrames, 'Number of batched command results must equal number of batched commands.');

disp('Repeated flush commands should leave the screen blank.');

% When it's done, make sure we have normal control again.
% ie, calling flush shouldn't cause an error, get stuck, etc.
mglFlush();

if (isInteractive)
    mglPause();
end
