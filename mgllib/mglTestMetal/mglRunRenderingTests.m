% mglRunRenderingTests: run multiple rendering tests and check results.
%
%      usage: results = mglRunRenderingTests(testNames)
%         by: Benjamin Heasly
%       date: 03/10/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Run all the mgl test scripts in the mglRenderingTests folder.
%             Report any results that don't match expectations.
%      usage: results = mglRunRenderingTests();
%
function results = mglRunRenderingTests(testNames)

thisFolder = fileparts(mfilename('fullpath'));
testsFolder = fullfile(thisFolder, 'mglRenderingTests');
if nargin < 1
    testsDir = dir([testsFolder, '/*.m']);
    testNames = cellfun(@(s) erase(s, '.m'), {testsDir.name}, 'UniformOutput', false);
end

if ischar(testNames)
    testNames = {testNames};
end

fprintf('\nRunning %d tests.\n', numel(testNames));

% Run all the tests.
% Each will render to an offscreen texture that we create here.
% We'll read the texture and compare the rendering results to a snapshot.
resultCell = cell(1, numel(testNames));
for ii = 1:numel(testNames)
    testName = testNames{ii};
    snapshotData = fullfile(testsFolder, 'snapshots', [testName, '.mat']);
    resultCell{ii} = assertSnapshot(testName, snapshotData);
end

results = [resultCell{:}];
toReport = find(~[results.isSuccess]);

if isempty(toReport)
    fprintf('\nAll tests passed!\n');
    return
else
    fprintf('\n%d tests failed:\n', numel(toReport));
    for ii = toReport
        result = results(ii);
        fprintf('  %d: %s\n', ii, result.testName);
        fprintf('     snapshot data: %s\n', result.snapshotData);
        figure('Name', sprintf('%s Expected', result.testName));
        imshow(result.snapshot(:,:,1:3), 'InitialMagnification', 100);
        title(sprintf('Expected (%d x %d)', size(result.snapshot, 1), size(result.snapshot, 2)));
        figure('Name', sprintf('%s Actual', result.testName));
        if size(result.renderedImage, 3) >= 3
            imshow(result.renderedImage(:,:,1:3), 'InitialMagnification', 100);
        end
        title(sprintf('Actual (%d x %d)', size(result.renderedImage, 1), size(result.renderedImage, 2)));
    end
    fprintf('Despair not!\n');
    fprintf('You can review Expected vs Actual images.  If the Actual is correct, delete the snapshot data file and run this again.\n');
end


%% Run one test.
function result = assertSnapshot(testName, snapshotData)
% Open mgl with a fixed size, for automated comparison to snapshot data.
mglSize = 512;
mglOpen(0, mglSize, mglSize);

% This will close mgl whenever this function exists -- normally or on error.
cleanup = onCleanup(@() mglClose());

% Create a texture of fixed size to receive rendering results.
blankImage = zeros(mglSize, mglSize, 4);
screenGrab = mglCreateTexture(blankImage);
mglMetalSetRenderTarget(screenGrab);

% Execute the test script in non-interactive mode.
feval(testName, false);

% Capture a screen grab from the test script.
renderedImage = mglMetalReadTexture(screenGrab);

if ~isfile(snapshotData)
    fprintf('Saving new snapshot: %s\n', snapshotData);
    snapshot = renderedImage;
    save(snapshotData, 'snapshot');
end

result = load(snapshotData, 'snapshot');
result.renderedImage = renderedImage;
result.isSuccess = isequal(renderedImage, result.snapshot);
result.testName = testName;
result.snapshotData = snapshotData;
