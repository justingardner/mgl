% writetrace.m
%
%        $Id$
%      usage: writetrace.m()
%         by: justin gardner
%       date: 02/17/05
%  copyright: (c) 2006 Justin Gardner (GPL see mgl/COPYING)
%    purpose: function for experiments that writes data
%             to a trace. because saving data in a trace
%             for every timestep starts to bog everything
%             down as the traces get to long, we just save
%             the ticknumber and the data of the event
%             when it is different than the previous ones.
%
function myscreen = writeTrace(data,tracenum,myscreen,force)

% decide whether to force
if nargin == 3
  force = 0;
end

% find last occurrence of data on this trace
getlast = find((myscreen.events.tracenum == tracenum));
if ~isempty(getlast)
  getlast = getlast(end);
end

% if there is no last time point or the data is the same at that timepoint
if force || isempty(getlast) || ~isequal(myscreen.events.data(getlast),data)
  % then save the datapoint
  myscreen.events.n = myscreen.events.n+1;
  myscreen.events.tracenum(myscreen.events.n) = tracenum;
  myscreen.events.data(myscreen.events.n) = data;
  myscreen.events.ticknum(myscreen.events.n) = myscreen.tick;
  myscreen.events.volnum(myscreen.events.n) = myscreen.volnum;
  myscreen.events.time(myscreen.events.n) = mglGetSecs;
  myscreen.events.force(myscreen.events.n) = force;
end
