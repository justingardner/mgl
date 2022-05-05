% mglRenderingDemo: go through several interactive rendering demos.
%
%      usage: mglRenderingDemo(testNames)
%         by: Benjamin Heasly
%       date: 03/10/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Run all the mgl test scripts in the mglRenderingTests folder.
%             Do them in interactive mode so you can see what happens.
%      usage: mglRenderingDemo();
%
function mglRenderingDemo(testNames)

thisFolder = fileparts(mfilename('fullpath'));
testsFolder = fullfile(thisFolder, 'mglRenderingTests');
if nargin < 1
    testsDir = dir([testsFolder, '/*.m']);
    testNames = cellfun(@(s) erase(s, '.m'), {testsDir.name}, 'UniformOutput', false);
end

if ischar(testNames)
    testNames = {testNames};
end

fprintf('\nRunning %d demos.\n', numel(testNames));

% Run all the demos with pauses in between.
for ii = 1:numel(testNames)
    testName = testNames{ii};
    fprintf('\n%d: Hit any key to continue for %s.\n', ii, testName);

    mglPause;

    feval(testName, true);
end
