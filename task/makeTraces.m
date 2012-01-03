% makeTraces.m
%
%      usage: myscreen = makeTraces(myscreen,<verbose>)
%         by: justin gardner
%       date: 02/28/07
%    purpose: makes traces from event times
%
function myscreen = makeTraces(myscreen,verbose)

% check arguments
if ~any(nargin == [1 2])
  help makeTraces
  return
end

if nargin < 2,verbose = 1;end

% convert time to seconds
if ~isfield(myscreen,'endtimeSecs')
  myscreen.endtimeSecs = datenum(myscreen.endtime);
end

% generate traces from events (events only tell when a trace
% changes its value, and we want traces that have a continuous
% representation of the value). This is all done to keep the
% trace arrays from getting too large and slowing things done
% while the task is running
if (isfield(myscreen,'events'))
  maxtick = myscreen.tick;
  % make up time in between first and end time, we will make this 
  % piecewise linear for each event later.
  if (maxtick > 2)
    myscreen.time(2:maxtick) = myscreen.time(1):(myscreen.endtimeSecs-myscreen.time(1))/(maxtick-2):myscreen.endtimeSecs;
  end
  % fill traces with zero
  myscreen.traces = zeros(max(myscreen.events.tracenum),maxtick);
  lastticknum = 1;
  if exist('disppercent')&&verbose,disppercent(-inf,'(makeTraces) Creating stimulus traces');end
  for i = 1:myscreen.events.n
    % get the tick num for this event
    ticknum = myscreen.events.ticknum(i);
    % put the data into the trace
    % if it is a force, then only set the current one
    if myscreen.events.force(i)
      myscreen.traces(myscreen.events.tracenum(i),ticknum) = myscreen.events.data(i);
    else
      myscreen.traces(myscreen.events.tracenum(i),ticknum:maxtick) = myscreen.events.data(i);
    end
    % get the time in between the last time and this time
    thistime = myscreen.events.time(i);
    lasttime = myscreen.time(lastticknum);
    % get the time in between the last tick and this tick
    if (lastticknum == ticknum)
      timetrace = thistime;
    else
      if (lasttime-thistime) ~= 0
	timetrace = lasttime:(thistime-lasttime)/(ticknum-lastticknum):thistime;
      else
	timetrace = repmat(lasttime,1,ticknum-lastticknum+1);
      end
    end
    % and stick that time into the time trace
    myscreen.time(lastticknum:ticknum) = timetrace;
    % remember the event ticknum
    lastticknum = ticknum;
    if exist('disppercent')&&verbose,disppercent(i/myscreen.events.n);end
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
if exist('disppercent')&&verbose,disppercent(inf);end

