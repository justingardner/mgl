% mglPlotCommandResults: plot a sequence of command/frame time records.
%
%      usage: mglPlotCommandResults(flushResults)
%         by: Benjamin Heasly
%       date: 01/19/2024
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Visualize a sequence of detailed command and frame times.
%      usage: mglPlotCommandResults(flushResults)
%
% Inputs:
%
%   flushResults:   struct array of command results from mglFlush commands,
%                   obtained over multiple frames.
%   drawResults:    struct array of command results from drawing commands,
%                   over the same frames as flushResults.
%
function f = mglPlotCommandResults(flushes, draws, figureName, refreshRate)

if iscell(flushes)
    flushes = [flushes{:}];
end

if nargin < 3 || isempty(figureName)
    figureName = 'Frame Times';
end

if nargin < 4 || isempty(refreshRate)
    displays = mglDescribeDisplays();
    refreshRate = displays(1).refreshRate;
end
expectedFrameMillis = 1000 / refreshRate;

f = figure('Name', figureName);

% Choose flush presentation time as the baseline.
% Since this is scheduled (in general) and reported (macOS 15.4+) by the
% system, I expect this to be the steadiest baseline for comparison.

presentationTimes = [flushes.drawablePresented];

% Show the frame-to-frame intervals reported by the system.
subplot(3, 1, 1);
plot(1000 * diff(presentationTimes), 'Marker', '*', 'Color', 'magenta');
plotHorizontal(1, numel(flushes), expectedFrameMillis);
plotHorizontal(1, numel(flushes), 2 * expectedFrameMillis);
title('system-reported presentation intervals')
grid('on');
ylabel('ms');
ylim([0 3 * expectedFrameMillis]);

% Show detailed timing info within each frame relative to baseline.
subplot(3, 1, 2:3);
if nargin > 1 && ~isempty(draws)
    if iscell(draws)
        draws = [draws{:}];
    end
    plotTimestamps(draws, presentationTimes, 'setupTime', 'draw setup', '.', 'green');
    plotTimestamps(draws, presentationTimes, 'ackTime', 'draw ack',  'o', 'green');
    plotTimestamps(draws, presentationTimes, 'drawableAcquired', 'drawable acquired', '+', 'magenta');
    plotTimestamps(draws, presentationTimes, 'processedTime', 'draw done', 'x', 'green');
end

plotTimestamps(flushes, presentationTimes, 'ackTime', 'flush ack', 'o', 'black');
plotTimestamps(flushes, presentationTimes, 'drawableAcquired', 'drawable acquired', '+', 'magenta');
plotTimestamps(flushes, presentationTimes, 'vertexStart', 'vertex start', 'o', 'red');
plotTimestamps(flushes, presentationTimes, 'vertexEnd', 'vertex end', '.', 'red');
plotTimestamps(flushes, presentationTimes, 'fragmentStart', 'fragment start', 'o', 'blue');
plotTimestamps(flushes, presentationTimes, 'fragmentEnd', 'fragment end', '.', 'blue');
plotTimestamps(flushes, presentationTimes, 'drawablePresented', 'previous presented', '*', 'magenta');
plotTimestamps(flushes, presentationTimes, 'processedTime', 'flush done', 'x', 'black');

title('sub-frame timestamps wrt system-reported presentation time')
grid('on');
ylabel('ms');
xlabel('frame number');
legend('AutoUpdate', 'off');

ylim(expectedFrameMillis * [-2 2]);
plotHorizontal(1, numel(flushes), expectedFrameMillis);
plotHorizontal(1, numel(flushes), -expectedFrameMillis);


%% Dig out one field of results and plot nonzero values wrt baseline.
function plotTimestamps(results, baseline, fieldName, displayName, marker, color)
xAxis = 1:numel(baseline);
timestamps = [results.(fieldName)];
hasData = timestamps ~= 0;
line( ...
    xAxis(hasData), ...
    1000 * (timestamps(hasData) - baseline(hasData)), ...
    'LineStyle', 'none', ...
    'Marker', marker, ...
    'Color', color, ...
    'DisplayName', displayName);


%% Plot a horizontal line representing an expected frame time.
function plotHorizontal(left, right, height)
line( ...
    [left, right], ...
    height * [1 1], ...
    'Marker', 'none', ...
    'LineStyle', '--', ...
    'Color', 'red');
