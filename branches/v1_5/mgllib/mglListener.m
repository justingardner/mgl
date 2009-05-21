% mglListener.m
%
%      usage: mglListener(event)
%         by: justin gardner
%       date: 06/19/08
%    purpose: Default listener function which logs events in a global
%
function retval = mglListener(event)

% check arguments
if ~any(nargin == [1])
  help mglListener
  return
end

disp(sprintf('%s: keyCode=%i timeStamp=%0.8f lag=%0.8f',event.type,event.keyCode,event.timeStamp,event.timeStamp-mglGetSecs));
