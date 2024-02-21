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

lastPresented = [flushes.drawablePresented];

% Show when each flush got presented -- which we learn from the next flush.
% Include the connecting line so we can see frames that went out of bounds.
line(1:(numel(lastPresented)-1), 1000 * diff(lastPresented), ...
    'LineStyle', '-', ...
    'Marker', 'o', ...
    'Color', 'magenta', ...
    'DisplayName', 'drawable presented');

% Show info about drawing commands, if any.
if nargin > 1 && ~isempty(draws)
    if iscell(draws)
        draws = [draws{:}];
    end
    plotTimestamps(draws, lastPresented, 'setupTime', 'client setup', '.', 'cyan');
    plotTimestamps(draws, lastPresented, 'ackTime', 'draw ack',  '.', 'black');
    plotTimestamps(draws, lastPresented, 'processedTime', 'draw done', 'o', 'black');
end

% Show lots of detail about flush commands!
plotTimestamps(flushes, lastPresented, 'vertexStart', 'vertex start', '.', 'red');
plotTimestamps(flushes, lastPresented, 'vertexEnd', 'vertex end', '.', 'red');
plotTimestamps(flushes, lastPresented, 'fragmentStart', 'fragment start', '.', 'green');
plotTimestamps(flushes, lastPresented, 'fragmentEnd', 'fragment end', '.', 'green');

plotTimestamps(flushes, lastPresented, 'drawableAcquired', 'drawable acquired', '.', 'magenta');

plotTimestamps(flushes, lastPresented, 'ackTime', 'flush ack', '.', 'blue');
plotTimestamps(flushes, lastPresented, 'processedTime', 'flush done', 'o', 'blue');

title('sub-frame timestamps wrt last drawable presentation')
grid('on');
ylabel('ms');
ylim(expectedFrameMillis * [-1.5 1.5]);
xlabel('frame number');

legend('AutoUpdate', 'off');

plotHorizontal(1, numel(flushes), expectedFrameMillis, 'red');
plotHorizontal(1, numel(flushes), -expectedFrameMillis, 'red');


%% Dig out one field of results and plot nonzero values wrt baseline.
function plotTimestamps(results, baseline, fieldName, displayName, marker, color)
xAxis = 1:numel(baseline);
timestamps = [results.(fieldName)];
hasData = timestamps ~= 0;
line(xAxis(hasData), ...
    1000 * (timestamps(hasData) - baseline(hasData)), ...
    'LineStyle', 'none', ...
    'Marker', marker, ...
    'Color', color, ...
    'DisplayName', displayName);


%% Plot a horizontal line representing an expected frame time.
function plotHorizontal(left, right, height, color)
line([left, right], ...
    height * [1 1], ...
    'Marker', 'none', ...
    'LineStyle', '--', ...
    'Color', color);
