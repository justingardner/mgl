% writetrace.m
%
%        $Id$
%      usage: myscreen = writetrace(data,tracenum,myscreen,force)
%         by: justin gardner
%       date: 02/17/05
%  copyright: (c) 2006 Justin Gardner (GPL see mgl/COPYING)
%    purpose: function for experiments that writes data
%             to a trace. because saving data in a trace
%             for every timestep starts to bog everything
%             down as the traces get to long, we just save
%             the ticknumber and the data of the event
%             when it is different than the previous ones.
%             data is the value to set
%             tracenum specifies which trace to write to
%             myscreen is the variable returned by initScreen
%             force if set to 1 saves the value regardless
%             of whether it is the same or different from
%             previous values. The default is to only save
%             the event if it causes a change in the trace
%
function myscreen = writeTrace(data,tracenum,myscreen,force,eventTime)

% decide whether to force
if any(nargin==[3])
  force = 0;
  eventTime = mglGetSecs;
end
% event time
if any(nargin==[3 4])
  eventTime = mglGetSecs;
end

% find last occurrence of data on this trace
%% isn't this operation slow? wouldn't it make more sense to
%% keep a 1xtraceNum vector of the the last event with an increment?
getlast = find((myscreen.events.tracenum == tracenum));
if ~isempty(getlast)
  getlast = getlast(end);
end

% if there is no last time point or the data is the same at that timepoint
if (tracenum>0) && (force || isempty(getlast) || ~isequal(myscreen.events.data(getlast),data))
  % then save the datapoint
  myscreen.events.n = myscreen.events.n+1;
  myscreen.events.tracenum(myscreen.events.n) = tracenum;
  myscreen.events.data(myscreen.events.n) = data;
  myscreen.events.ticknum(myscreen.events.n) = myscreen.tick;
  myscreen.events.volnum(myscreen.events.n) = myscreen.volnum;
  myscreen.events.time(myscreen.events.n) = eventTime;
  myscreen.events.force(myscreen.events.n) = force;
end
