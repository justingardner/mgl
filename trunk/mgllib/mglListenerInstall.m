% mglInstallListener.m
%
%        $Id$
%      usage: mglInstallListener(listnerName,<eventTypes>,<keyNames>)
%         by: justin gardner
%       date: 06/18/08
%  copyright: (c) 2008 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Installs a listener function to handle keyboard and mouse events
%             That is, you pass it a name of a function and it sets up that
%             function gets called every time there is a keyboard or mouse event
%
function retval = mglInstallListener(listnerName,eventTypes,keyNames)

% check arguments
if ~any(nargin == [1 2 3])
  help mglInstallListener
  return
end

bogusEvent.keyCode = 0;
bogusEvent.timeStamp = mglGetSecs;
eval(sprintf('%s(bogusEvent)',listnerName));
pointer1 = mglPrivateInstallListener(listnerName);





