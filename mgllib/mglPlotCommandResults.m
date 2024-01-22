% mglPlotCommandResults: visualize a sequence of command/frame times.
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
function mglPlotCommandResults(flushResults, drawResults, figureName, refreshRate)

if nargin < 3 || isempty(figureName)
    figureName = 'Frame Times';
end

if nargin < 4 || isempty(refreshRate)
    displays = mglDescribeDisplays();
    refreshRate = displays(1).refreshRate;
end
expectedFrameTime = 1 / refreshRate;

figure('Name', figureName);
subplot(2, 1, 1);
plot(1000 * diff([flushResults.drawablePresented]), 'm*');
grid('on');
ylabel('milliseconds');

subplot(2, 1, 2);
ylabel('milliseconds');
xlabel('frame number');

ylim(expectedFrameTime * [-3 1] * 1000);

% Choose a baseline for aligning within each frame.
baseline = [flushResults.processedTime];

if nargin > 1 && ~isempty(drawResults)
    plotTimestamps(drawResults, baseline, 'setupTime', 'draw setup', '.', 'green');
    plotTimestamps(drawResults, baseline, 'ackTime', 'draw ack',  'o', 'green');
    plotTimestamps(drawResults, baseline, 'drawableAcquired', 'drawable acquired', '+', 'magenta');
    plotTimestamps(drawResults, baseline, 'processedTime', 'draw done', 'x', 'green');
end

plotTimestamps(flushResults, baseline, 'ackTime', 'flush ack', 'o', 'black');
plotTimestamps(flushResults, baseline, 'drawableAcquired', 'drawable acquired', '+', 'magenta');
plotTimestamps(flushResults, baseline, 'vertexStart', 'vertex start', 'o', 'red');
plotTimestamps(flushResults, baseline, 'vertexEnd', 'vertex end', '.', 'red');
plotTimestamps(flushResults, baseline, 'fragmentStart', 'fragment start', 'o', 'blue');
plotTimestamps(flushResults, baseline, 'fragmentEnd', 'fragment end', '.', 'blue');
plotTimestamps(flushResults, baseline, 'drawablePresented', 'previous presented', '*', 'magenta');
plotTimestamps(flushResults, baseline, 'processedTime', 'flush done', 'x', 'black');

legend();

% Dig out one field of results and plot nonzero values wrt baseline.
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
