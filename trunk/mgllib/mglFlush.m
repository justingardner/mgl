% mglFlush.m
%
%        $Id$
%      usage: mglFlush()
%         by: justin gardner; X support by Jonas Larsson
%       date: 04/10/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: swap front and back buffer (waits for one frame tick)
%
%    Warning: if using mglFlush to keep timing, keep in mind that
%             Matlab checks for license every 30s, screwing up
%             timing at this interval. Installing a local copy
%             of the license manager appears to solve problem, mostly.
%

