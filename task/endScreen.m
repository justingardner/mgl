% endScreen.m
%
%        $Id$
%      usage: myscreen = endScreen(myscreen)
%         by: justin gardner
%       date: 12/21/04
%  copyright: (c) 2006 Justin Gardner (GPL see mgl/COPYING)
%
%    purpose: close screen and clean up - for mgl
%
function myscreen = endScreen(myscreen)

if nargin == 0
  disp(sprintf('(endScreen) No myscreen variable passed in, just closing screen and shutting down listeners'));
  mglClose;
  mglListener('quit');
  mglDigIO('quit');
  mglDisplayCursor(1);
  return
end
% close screen
if (myscreen.autoCloseScreen)
  mglClose;
else
  mglClearScreen;mglFlush;
  mglClearScreen;mglFlush;
end

% quit keyboard listener
myscreen.mouseEventsAtEndScreen = mglGetMouseEvent(0,1);
mglListener('quit');

% turn off eye tracker
%writeDigPort(0,2);

% shutdown mglDigIO if it is running
if myscreen.useDigIO
  disp(sprintf('(endScreen) Closing DIG IO'));
  mglDigIO('quit');
end
  
% display tick rate
if isfield(myscreen,'totalflip')
  disp(sprintf('Average tick rate = %0.6f %0.5fHz effective',myscreen.totalflip/myscreen.totaltick,1/(myscreen.totalflip/myscreen.totaltick)));
  disp(sprintf('Dropped frames = %i (%0.2f%%) (i.e. frames >= %0.1f%% longer than expected)',myscreen.dropcount,100*myscreen.dropcount/myscreen.totaltick,(myscreen.dropThreshold-1)*100));
end

% set end time
myscreen.endtimeSecs = mglGetSecs;
myscreen.endtime = datestr(clock);

disp(sprintf('-----------------------------'));
if ((nargin == 1) && (isfield(myscreen,'makeTraces')) && (myscreen.makeTraces == 1))
  myscreen = makeTraces(myscreen);
end

if myscreen.hideCursor
  mglDisplayCursor(1);
end