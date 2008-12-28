% mglGetMouseEvent.m
%
%        $Id$
%      usage: mglGetMouseEvent(<waitTime>,<getAllEvents>)
%  alt usage: [buttons when x y] = mglGetMouseEvent(<waitTime>,<getAllEvents>)
%         by: justin gardner
%       date: 09/12/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: returns a mouse down event
%             waitTime specifies how long to wait for a mouse event
%             in seconds. Note that the timing precision is system-dependent:
%             - Mac OS X: nanosecond. relies on mglListener
%             - Linux: 1/HZ s where HZ is the system kernel tick frequency
%               (HZ=100 on older systems, HZ=250 or 500 on more modern systems)
%             The default wait time is 0, which will return immediately with
%             the mouse position regardless of button state.
%             The return structure contains the x,y coordinates of the mouse,
%             the button identifier if pressed (on the button-challenged Mac 
%             this is always 1) and 0 otherwise, and the time (in secs) of 
%             the mouse event.
%       e.g.:
%
%mglOpen
%mglGetMouseEvent(0.5)
%
function [mouseEvent when x y] = mglGetMouseEvent(waitTime,getAllEvents)

if nargin == 0,waitTime = [];end
if nargin == 1,getAllEvents = 0;end
  
% get all key events
if (nargin == 2) && getAllEvents
  % with one output argument, just return structures
  if ((nargout == 1) || (nargout == 0))
    thisMouseEvent = mglGetMouseEvent(waitTime);
    mouseEvent = {};
    % get events until it is empty
    while(~isempty(thisMouseEvent) && (thisMouseEvent.buttons ~= 0))
      mouseEvent{end+1} = thisMouseEvent;
      thisMouseEvent = mglGetMouseEvent;
    end
  % with more output arguments, return arrays
  else
    mouseEvent = [];when = [];x = [];y = [];
    % check for listener for mac os x
    if mglPrivateListener(1);
      % directly get all pending keyboard event from listener
      mouseEvents = mglPrivateListener(6);
      if ~isempty(mouseEvents)
	mouseEvent = mouseEvents.buttons;
	when = mouseEvents.when;
	x = mouseEvents.x;
	y = mouseEvents.y;
      end
    else
      thisMouseEvent = mglGetMouseEvent(waitTime);
      % get events until no more events are available
      while(~isempty(thisMouseEvent) && (thisMouseEvent.buttons ~= 0))
	% pack into output arguments
	mouseEvent(end+1) = thisMouseEvent.buttons;
	when(end+1) = thisMouseEvent.when;
	x(end+1) = thisMouseEvent.x;
	y(end+1) = thisMouseEvent.y;
	thisMouseEvent = mglGetMouseEvent;
      end
    end
  end
  return
end

  
% check to see if we need to get this from the listener
if mglPrivateListener(1)
  % ok, then get the keyEvent
  mouseEvent = mglPrivateListener(3);
  % if it is empty, and the user wants to wait, then wait for an event
  if ~isempty(waitTime)
    startTime = mglGetSecs;
    while(isempty(mouseEvent) && ((mglGetSecs-startTime) < waitTime))
      mouseEvent = mglPrivateListener(3);
    end
  end
else
  mouseEvent = mglPrivateGetMouseEvent;
end

if isempty(mouseEvent)
  mouseEvent = mglGetMouse;
  mouseEvent.when = mglGetSecs;
  mouseEvent.clickState = 0;
end

% convert to array style output if more than one output argument
if nargout > 1
  when = mouseEvent.when;
  x = mouseEvent.x;
  y = mouseEvent.y;
  mouseEvent = mouseEvent.buttons;
end



