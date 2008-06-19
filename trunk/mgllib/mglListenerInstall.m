% mglListenerInstall.m
%
%        $Id$
%      usage: mglListenerInstall(listnerName,<eventTypes>,<keyNames>)
%         by: justin gardner
%       date: 06/18/08
%  copyright: (c) 2008 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Installs a listener function to handle keyboard and mouse events
%             That is, you pass it a name of a function and it sets up that
%             function gets called every time there is a keyboard or mouse event
%
function retval = mglListenerInstall(listenerName,eventTypes,keyNames)

% check arguments
if ~any(nargin == [1 2 3])
  help mglListenerInstall
  return
end

% create an init event and run the function. This insures that the
% callback will be in memory
initEvent.type = 'init';
initEvent.keyCode = 0;
initEvent.timeStamp = mglGetSecs;

% call the listener with the initEvent
eval(sprintf('%s(initEvent)',listenerName));

% now install the listener
%[eventTapPointer runLoopPointer] = mglPrivateListenerInstall(listenerName);
mglPrivateListenerInstall(listenerName);

% keep the pointers
%global MGL
%MGL.listener.eventTapPointer = eventTapPointer;
%MGL.listener.runLoopPointer = runLoopPointer;
%MGL.listener.listener = listenerName;






