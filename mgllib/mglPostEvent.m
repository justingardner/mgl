% mglPostEvent.m
%
%        $Id: mglOpen.m 385 2009-01-03 20:34:37Z justin $
%      usage: mglPostEvent(command,<time>,<char/keyCode>)
%         by: justin gardner
%       date: 01/10/09
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: This is a mac specific command that is used to create an event.
%             For example, you can cause a keypress to happen in 2 seconds:
%
%             mglPostEvent('keypress',-2,'a');
% 
%             Note that if time is negative it is interpreted as in
%             how many seconds from now you want the event to happen.
%             If the time is a positive number it is assumed to be 
%             a system time (in seconds) like one returned by mglGetSecs.
%
%             To move the mouse to a certain screen position.
%             mglPostEvent('mousemove',-2,100,300);
%
%             To click the mouse at a certain screen position.
%             mglPostEvent('mousepress',-2,'left',100,300);
%
%             To list all pending events:
%             mglPostEvent('list');
%
%             To shut down the thread that dispatches the events (which
%             is started either with 'init', or simply by posting an event):
%             mglPostEvent('quit');
%             OR hit the ESC key to quit.
%
function mglPostEvent(command,time,arg1,arg2,arg3)

% check arguments
if ~any(nargin == [1 3 4 5])
  help mglPostEvent;
  return
end

% interpert time
if nargin >= 2
  % if time is a negative number, it means relative to now.
  if time < 0
    time = mglGetSecs-time;
  end
end


% interpret commands
if strcmp(lower(command),'init')
  mglPrivatePostEvent(1);
elseif strcmp(lower(command),'quit')
  mglPrivatePostEvent(0);
elseif strcmp(lower(command),'list')
  mglPrivatePostEvent(3);
elseif strcmp(lower(command),'keypress')
  % get the keycode we want
  if ischar(arg1)
    for i = 1:length(arg1)
      keyCode(i) = mglCharToKeycode({arg1(i)});
    end
  else
    keyCode = arg1;
  end
  % if post event is not enabled, enable it
  if isempty(mglGetParam('postEventEnabled')) || (mglGetParam('postEventEnabled') ~= 1)
    disp(sprintf('(mglPostEvent) Enabling post event thread.'));
    mglPrivatePostEvent(1);
  end
  % and post the event. First post a keyDown and then a keyUp 100ms later
  for i = 1:length(keyCode)
    mglPrivatePostEvent(2,time,keyCode(i),1);
    mglPrivatePostEvent(2,time+0.1,keyCode(i),0);
    time = time+0.01;
  end
elseif strcmp(lower(command),'mousemove')
  % if post event is not enabled, enable it
  if isempty(mglGetParam('postEventEnabled')) || (mglGetParam('postEventEnabled') ~= 1)
    disp(sprintf('(mglPostEvent) Enabling post event thread.'));
    mglPrivatePostEvent(1);
  end
  if nargin < 4,help mglPostEvent,return,end
  % and post the event. 
  mglPrivatePostEvent(4,time,arg1,arg2)
elseif strcmp(lower(command),'mousepress')
  % if post event is not enabled, enable it
  if isempty(mglGetParam('postEventEnabled')) || (mglGetParam('postEventEnabled') ~= 1)
    disp(sprintf('(mglPostEvent) Enabling post event thread.'));
    mglPrivatePostEvent(1);
  end
  if nargin < 5,help mglPostEvent,return,end
  % and post the event. 
  if strcmp(arg1,'left')
    mglPrivatePostEvent(5,time,0,arg2,arg3);
    mglPrivatePostEvent(6,time+0.1,0,arg2,arg3);
    time = time+0.01;
  else
    mglPrivatePostEvent(5,time,1,arg2,arg3);
    mglPrivatePostEvent(6,time+0.1,1,arg2,arg3);
    time = time+0.01;
  end
else
  disp(sprintf('(mglPostEvent) Command %s not recognized',command));
end


