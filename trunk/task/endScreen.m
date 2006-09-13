% endScreen.m
%
%        $Id$
%      usage: endscreen
%         by: justin gardner
%       date: 12/21/04
%  copyright: (c) 2006 Justin Gardner (GPL see mgl/COPYING)
%
%    purpose: close screen and clean up - for MGL
%
function myscreen = endScreen(myscreen)

% close screen
if (myscreen.autoCloseScreen)
  mglClose;
else
  mglClearScreen;mglFlush;
  mglClearScreen;mglFlush;
end

% display tick rate
if isfield(myscreen,'totalflip')
  disp(sprintf('Average tick rate = %0.6f %0.5fHz effective',myscreen.totalflip/myscreen.tick,1/(myscreen.totalflip/myscreen.tick)));
  disp(sprintf('Dropped frames = %i (%0.2f%%)',myscreen.dropcount,100*myscreen.dropcount/myscreen.tick));
end
  
disp(sprintf('-----------------------------'));
if (nargin == 1)
  % generate traces from events (events only tell when a trace
  % changes its value, and we want traces that have a continuous
  % representation of the value). This is all done to keep the
  % trace arrays from getting too large and slowing things done
  % while the task is running
  endtime = GetSecs;
  if (isfield(myscreen,'events'))
    maxtick = myscreen.tick;
    % make up time in between first and end time, we will make this 
    % piecewise linear for each event later.
    if (maxtick > 2)
      myscreen.time(2:maxtick) = myscreen.time(1):(endtime-myscreen.time(1))/(maxtick-2):endtime;
    end
    % fill traces with zero
    myscreen.traces = zeros(max(myscreen.events.tracenum),maxtick);
    lastticknum = 1;
    disppercent(-inf,'Creating stimulus traces');
    for i = 1:myscreen.events.n
      disppercent(i/myscreen.events.n);
      % get the tick num for this event
      ticknum = myscreen.events.ticknum(i);
      % put the data into the trace
      myscreen.traces(myscreen.events.tracenum(i),ticknum:maxtick) = myscreen.events.data(i);
      % get the time in between the last time and this time
      thistime = myscreen.events.time(i);
      lasttime = myscreen.time(lastticknum);
      % get the time in between the last tick and this tick
      if (lastticknum == ticknum)
	timetrace = thistime;
      else
	timetrace = lasttime:(thistime-lasttime)/(ticknum-lastticknum):thistime;
      end
      % and stick that time into the time trace
      myscreen.time(lastticknum:ticknum) = timetrace;
      % remember the event ticknum
      lastticknum = ticknum;
    end
    % truncate unused parts of event traces
    myscreen.events.tracenum = myscreen.events.tracenum(1:myscreen.events.n);
    myscreen.events.data = myscreen.events.data(1:myscreen.events.n);
    myscreen.events.ticknum = myscreen.events.ticknum(1:myscreen.events.n);
    myscreen.events.volnum = myscreen.events.volnum(1:myscreen.events.n);
    myscreen.events.time = myscreen.events.time(1:myscreen.events.n);
    % make time start at 0
    myscreen.time = myscreen.time - myscreen.time(1);
  end
  myscreen.endtime = datestr(clock);
  disppercent(inf);
end

