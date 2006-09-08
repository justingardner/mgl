% writetrace.m
%
%      usage: writetrace.m()
%         by: justin gardner
%       date: 02/17/05
%    purpose: function for experiments that writes data
%             to a trace. because saving data in a trace
%             for every timestep starts to bog everything
%             down as the traces get to long, we just save
%             the ticknumber and the data of the event
%             when it is different than the previous ones.
%
function myscreen = writetrace(data,tracenum,myscreen)

% find last occurrence of data on this trace
getlast = last(find((myscreen.events.tracenum == tracenum)));

% if there is no last time point or the data is the same at that timepoint
if isempty(getlast) || ~isequal(myscreen.events.data(getlast),data)
  % then save the datapoint
  myscreen.events.n = myscreen.events.n+1;
  myscreen.events.tracenum(myscreen.events.n) = tracenum;
  myscreen.events.data(myscreen.events.n) = data;
  myscreen.events.ticknum(myscreen.events.n) = myscreen.tick;
  myscreen.events.volnum(myscreen.events.n) = myscreen.volnum;
  myscreen.events.time(myscreen.events.n) = GetSecs;
end
