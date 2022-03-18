% mglPlotFrameTimes: visualize a sequence of frame times from mglFlush.
%
%      usage: mglPlotFrameTimes(ackTimes, processedTimes)
%         by: Benjamin Heasly
%       date: 03/10/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Visualize a sequence of frame times.
%      usage: mglPlotFrameTimes(times)
%
function mglPlotFrameTimes(ackTimes, processedTimes, name, refreshRate)

if nargin < 3
    name = 'Frame Times';
end

if nargin < 4
    displays = mglDescribeDisplays();
    refreshRate = displays(1).refreshRate;
end
expectedFrameTime = 1 / refreshRate;

% For mglFlush(), "ackTime" is when the flush command was received,
% which is an indication of when we finished sending draw commands.
% mglFlush() then waits until "processedTime", the start of the next frame.
% From one processed to the next ack: how long we spend drawing stuff.
% From one processed to the next processed: how long the frame was.
drawingTimes = ackTimes(2:end) - processedTimes(1:end-1);
frameTimes = processedTimes(2:end) - processedTimes(1:end-1);

figure('Name', name);
xAxis = 1:numel(drawingTimes);
line(xAxis, drawingTimes, 'Marker', '.', 'LineStyle', 'none', 'Color', 'red');
line(xAxis, frameTimes, 'Marker', '*', 'LineStyle', 'none', 'Color', 'blue');
grid('on');
yticks(expectedFrameTime * (0:10));
ylim([0, max(frameTimes)]);
legend('draw', 'flip');
title(name);
xlabel('frame number');
ylabel('seconds');