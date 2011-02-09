% mglGetKeyEvent.m
%
%        $Id$
%      usage: keyEvent = mglGetKeyEvent(<waitTime>,<getAllEvents>)
%  alt usage: [keyCode when charCode] = mglGetKeyEvent(<waitTime>,<getAllEvents>)
%         by: justin gardner
%       date: 09/12/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: returns a key down event
%             waitTime specifies how long to wait for a key press event
%             in seconds. Note that the timing precision is system-dependent:
%             - Mac OS X: nanosecond precision. Relies on mglListener
%             - Linux: 1/HZ s where HZ is the system kernel tick frequency
%               (HZ=100 on older systems, HZ=250 or 500 on more modern systems)
%             The default wait time is 0, which will return immediately and if
%             no keypress event is found, will return an empty array [].
%             The return structure contains the character (ASCII) code of the
%             pressed key, the system-specific keycode, a keyboard identifier
%             (on Linux, this is the keyboard state, or modifier field), and 
%             and the time (in secs) of the key press event.
%       e.g.:
%
%mglOpen
%mglGetKeyEvent(0.5)
%
function [keyEvent when charCode] = mglGetKeyEvent(waitTime,getAllEvents)

if nargin == 0
  waitTime = [];
end
if nargin == 1
  getAllEvents = 0;
end

% get all key events
if (nargin == 2) && getAllEvents
  % with one output argument, just return structures
  if ((nargout == 1) || (nargout == 0))
    thisKeyEvent = mglGetKeyEvent(waitTime);
    keyEvent = {};
    % get events until it is empty
    while(~isempty(thisKeyEvent) && (thisKeyEvent.keyCode~=0))
      keyEvent{end+1} = thisKeyEvent;
      thisKeyEvent = mglGetKeyEvent;
    end
    % with more output arguments, return arrays
  else
    keyEvent = [];when = [];charCode = [];
    % check for listener for mac os x
    if mglPrivateListener(1);
      % directly get all pending keyboard event from listener
      keyEvents = mglPrivateListener(5);
      if ~isempty(keyEvents)
	keyEvent = keyEvents.keyCode;
	when = keyEvents.when;
	% if asked for, convert keyCodes into charCodes
	if nargout > 2
	  charCode = cell2mat(mglKeycodeToChar(keyEvent));
	end
      end
    else
      thisKeyEvent = mglGetKeyEvent(waitTime);
      % get events until no more events are available
      while(~isempty(thisKeyEvent) && (thisKeyEvent.keyCode~=0))
	% pack into output arguments
	keyEvent(end+1) = thisKeyEvent.keyCode;
	when(end+1) = thisKeyEvent.when;
	charCode(end+1) = thisKeyEvent.charCode;
	thisKeyEvent = mglGetKeyEvent;
      end
    end
    % make charCode into a string
    charCode = char(charCode);
  end
  return
end


% check to see if we need to get this from the listener
if mglPrivateListener(1)
  % ok, then get the keyEvent
  keyEvent = mglPrivateListener(2);
  % if it is empty, and the user wants to wait, then wait for an event
  if ~isempty(waitTime)
    startTime = mglGetSecs;
    while(isempty(keyEvent) && ((mglGetSecs-startTime) < waitTime))
      keyEvent = mglPrivateListener(2);
    end
  end
  % and convert the keyCode to a charCode
  if ~isempty(keyEvent)
    keyEvent.charCode = mglKeycodeToChar(keyEvent.keyCode);
    if ~isempty(keyEvent.charCode)
      keyEvent.charCode = keyEvent.charCode{1};
    else
      keyEvent.charCode = [];
    end
  end
else
  keyEvent = mglPrivateGetKeyEvent;
end

% convert to array style output if more than one output argument
if nargout > 1
  when = [];charCode = [];
  if ~isempty(keyEvent)
    when = keyEvent.when;
    charCode = keyEvent.charCode;
    keyEvent = keyEvent.keyCode;
  end
end

