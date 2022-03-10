% mglPlotFrameTimes: visualize a sequence of frame times.
%
%      usage: mglPlotFrameTimes(times)
%         by: Benjamin Heasly
%       date: 03/10/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Visualize a sequence of frame times.
%      usage: mglPlotFrameTimes(times)
%
function mglPlotFrameTimes(times)

displays = mglDescribeDisplays();
expectedFrameTime = 1 / displays(1).refreshRate;

deltas = diff(times);
figure()
plot(deltas, '.', 'LineStyle', 'none')
grid('on')
yticks(expectedFrameTime * [0:3]);
