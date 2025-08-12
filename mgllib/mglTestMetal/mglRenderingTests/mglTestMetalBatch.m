% mglTestMetalBatch: an automated and/or interactive test for rendering.
%
%      usage: mglTestMetalBatch(isInteractive)
%         by: Benjamin Heasly
%       date: 12 Jan 2024
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Test multiple flushes, repeated by the Metal app.
%      usage:
%             % You can run it by hand with no args.
%             mglTestMetalBatch();
%
%             % Or mglRunRenderingTests can run it, in non-interactive mode.
%             mglTestMetalBatch(false);
%
function mglTestMetalBatch(isInteractive)

if nargin < 1
    isInteractive = true;
end

if (isInteractive)
    mglOpen();
    cleanup = onCleanup(@() mglClose());
end

%% How to:

% Start a new batch.
% In this state the Mgl Metal app will accept commands to process later.
batchInfo = mglMetalStartBatch();

% Enqueue several drawing and non-drawing commands.
mglVisualAngleCoordinates(50, [20, 20]);
mglClearScreen([.25 1 .25]);

% During a batch we won't see results from getter commands that return
% their own results.  We'll only see placeholder results that prevent
% Matlab from blocking.  These commands should still execute and not
% interfere with other commands in the batch.
[displayNumber, rect] = mglMetalGetWindowFrameInDisplay();
assert(displayNumber == 0, "Should get placeholder response for display number.")
assert(isequal(rect, [0 0 0 0]), "Should get placeholder response for window rect.")

% Enqueue an animation over several frames.
xSweep = linspace(-10, 10, 100);
for x = xSweep
    mglPolygon(x + [-5 -6 -3  4 5], [5  1 -4 -2 3], [.25 .25 1]);
    mglFillOval(x, 0, [3, 4], [1 .25 .25], 0.1);
    mglFlush();
end

% Process the batch -- nothing will appear until we do this.
% In this state the Mgl Metal app will process commands enqueued above.
batchInfo = mglMetalProcessBatch(batchInfo);

disp('Mgl Metal is executing commands asynchronously.');

% Wait for the commands to finish, and gather the timing results.
results = mglMetalFinishBatch(batchInfo);
commandCount = 4 + 1 + 1 + 3 * numel(xSweep);
assert(numel(results) == commandCount, 'Number of batched command results must equal number of batched commands.');

disp('A red oval and blue polygon should sweep over a green background.');

if (isInteractive)
    codes = mglSocketCommandTypes();
    isPolygon = [results.commandCode] == codes.mglPolygon;
    isFlush = [results.commandCode] == codes.mglFlush;
    mglPlotCommandResults(results(isFlush), results(isPolygon), "Batch");
    mglPause();
end
