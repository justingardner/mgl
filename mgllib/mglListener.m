% mglListener.m
%
%      usage: mglListener(command)
%         by: justin gardner
%       date: 06/19/08
%    purpose: This is a mac specific command that is used to capture low-level
%             keyboard and mouse events. It provides the event information used
%             by mglGetKeyEvent and mglGetMouseEvent on the mac. On linux it
%             does nothing. 
%
%             It works by installing an event-tap to get keyboard events. Event-taps are
%             a low level accessibilty function that gets keyboard/mouse
%             events at a very low level (before application windows). We
%             intall a "listener" which is a callback that is called every
%             time there is a new event. This listener logs the events, and
%             can later be queried to return the event information. Because
%             it works at a low level it can get keyboard and mouse events
%             regardless of where the window focus is. Also, the precision of
%             the timestamps is in nanoseconds (though of course that is just
%             what the OS reports -- there may be delays in the OS and hardware
%             processing).
%
%             Note that you normally will not call this function directly, it will
%             be called by mglGetKeyEvent, and mglGetMouseEvent
%
%             Here are the commands it accepts:
%             
%             1:'init' Init the listener, you have to do this before any other command will work
%             2:'getKeyEvent' Returns a keyboard down event
%             3:'getMouseEvent' Returns a mouse down event
%             4:'getKeys' Returns an array like mglGetKeys except that the time each
%                         key that is currently down was initially pressed is returned.
%             5:'getAllKeyEvents' Returns a structure with when/keyCode for all pending keyEvents
%             6:'getAllMouseEvents' Same as getAllKeyEvents but for mouse events
%             0:'quit' Quits the listener, after this you won't be able to run other commands
%
%
function retval = mglListener(command)

% check arguments
if ~any(nargin == [1])
  help mglListener
  return
end

if isstr(command)
  commandNum = find(strcmp(lower(command),{'quit','init','getkeyevent','getmouseevent','getkeys','getallkeyevents','getallmouseevents'}))-1;
  if isempty(commandNum)
    disp(sprintf('(mglListener) Unknown command %s',command));
    return
  end
elseif isscalar(command)
  commandNum = command;
else
  help mglListener;
  return
end

% run the mex command
retval = mglPrivateListener(commandNum);


